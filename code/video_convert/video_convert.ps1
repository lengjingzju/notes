#Requires -Version 5.1
<#
==============================================================================
 视频批量转码脚本 —— Windows 版（Windows PowerShell 5.1 / PowerShell 7 均可运行）
 由 video_convert.sh 移植，编码逻辑、参数计算、判断条件与输出行为保持一致。

 运行前提：
   1) Win10 / Win11 自带的 PowerShell 5.1 即可，无需 WSL、无需 Bash；
   2) ffmpeg 与 ffprobe 需在 PATH 中（jq / bc / grep / sed / tr 等已由 PowerShell 原生替代）；
   3) 本文件必须保存为 UTF-8（带 BOM），否则 PowerShell 5.1 读取中文会乱码。

 用法：
   powershell -ExecutionPolicy Bypass -File video_convert.ps1 <输入目录> <输出目录>
   powershell -ExecutionPolicy Bypass -File video_convert.ps1 <配置文件> <输出目录>

 注：
   也可以将输入目录或配置文件拖动到 run_video_convert.bat 运行，此时输出目录自动命名为 <原名-enc>
   此时注意 bat 脚本中的 video_convert.ps1 路径要对（当前默认值是两个脚本位于相同目录）
==============================================================================
#>

#==============================================================================
# 编码配置选项
#==============================================================================

# 视频编码器选择
[int]$enc_hevc = 1              # 0 = H.264 / 1 = HEVC (H.265)
                                # 注意：此选项影响软编码和硬编码的编码器选择

# 编码模式选择
[int]$enc_2pass = 1             # 0 = CRF恒定质量模式（单次编码）
                                # 1 = 2-pass恒定码率模式（两次编码）
                                # 注意：CUDA硬件编码不支持真正的2-pass，启用时自动降级为CQP

# 是否启用CUDA硬件加速编码
[int]$enc_cuda = 0              # 0 = 纯软件编码（libx264/libx265）
                                # 1 = CUDA硬件编码（h264_nvenc/hevc_nvenc）
                                # 前提：系统需安装NVIDIA驱动及支持NVENC的GPU

# 高度参考值配置（仅用于文件夹批量处理模式）
[string]$height_refer = "1080"  # 参考高度（单位：像素）
                                # 当视频较短边大于height_limit时，将自动缩放到此高度
                                # 设置为空字符串 "" 则不限制

[string]$height_limit = "1100"  # 触发自动缩放的高度阈值（单位：像素）
                                # 较短边超过该值才会进行缩放

# 帧率限制配置
[string]$fps_limit = "30"       # 帧率上限（单位：fps）
                                # 当视频原始帧率高于此值时，自动降低到该值
                                # 设置为空字符串 "" 则保留原始帧率

# GOP倍率设置
[int]$gop_multiplier = 2        # GOP设置为FPS的几倍，默认约2秒的帧数，范围[24,600]

# CRF / CQP 质量值
[string]$CRF_VALUE = "23"       # - 软件编码（libx264/libx265）：0-51，值越小质量越高，23为默认
                                # - 硬件编码（NVENC）：-cq 参数范围可能不同，但此处通用值23通常有效

# 音频编码器及码率（统一使用AAC 64kbps，兼容性好）
[string]$AUDIO_CODEC = "aac"
[string]$AUDIO_BITRATE = "64k"

#==============================================================================
# 全局初始化
#==============================================================================

# 严格错误处理（等价原脚本 set -e）；单文件处理循环内用 try/catch 局部容错
$ErrorActionPreference = 'Stop'

# 无 BOM 的 UTF-8 编码器，用于写日志文件（避免 PS 5.1 默认 UTF-16 或 ANSI 造成中文乱码）
$script:Utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false

# 临时目录（替代原脚本 /tmp）
$script:TempDir = [System.IO.Path]::GetTempPath()

# 配置文件行解析正则（等价原脚本 ^([^[\(<]+)(\[.*\])?[[:space:]]*(\(.*\))?[[:space:]]*(<.*>)?$）
$script:LinePattern = '^([^\[\(<]+)(\[.*\])?\s*(\(.*\))?\s*(<.*>)?$'

#==============================================================================
# 根据配置选择编码器及相关显示名称
# 优先级：enc_cuda 覆盖软/硬编码器选择
#==============================================================================
if ($enc_cuda -eq 1) {
    if ($enc_hevc -eq 1) {
        $VIDEO_CODEC = "hevc_nvenc"
        $CODEC_NAME  = "HEVC (H.265 NVENC)"
    } else {
        $VIDEO_CODEC = "h264_nvenc"
        $CODEC_NAME  = "H.264 (NVENC)"
    }
} else {
    if ($enc_hevc -eq 1) {
        $VIDEO_CODEC = "libx265"
        $CODEC_NAME  = "HEVC (H.265)"
    } else {
        $VIDEO_CODEC = "libx264"
        $CODEC_NAME  = "H.264"
    }
}

#==============================================================================
# 通用辅助函数
#==============================================================================

# 追加一行文本到日志（无 BOM UTF-8，等价于原脚本 echo ... >> log）
function Append-Log {
    param([string]$Path, [string]$Text)
    [System.IO.File]::AppendAllText($Path, $Text + [Environment]::NewLine, $script:Utf8NoBom)
}

# 生成用于显示的命令行（含空格的参数加引号，接近原脚本 eval 前的字符串）
function Format-CommandLine {
    param([string[]]$Parts)
    return (($Parts | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' ')
}

# 执行 ffmpeg：按参数数组直接调用（不拼接字符串、不 eval），
# 完整输出写入临时日志（等价 tee），仅显示进度行（等价 grep -E），以退出码判定成败。
function Invoke-Ffmpeg {
    param(
        [string[]]$Arguments,
        [string]$CaptureLog,
        [string]$Label = 'ffmpeg'
    )

    # 外部命令的 stderr 不能被全局 Stop 打断；PS 7.3+ 也不要把非零退出码变成异常
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false

    Write-Host ("执行: ffmpeg " + (Format-CommandLine -Parts $Arguments)) -ForegroundColor Blue

    $lines = New-Object -TypeName 'System.Collections.Generic.List[string]'
    $lastWasProgress = $false

    & ffmpeg @Arguments 2>&1 | ForEach-Object {
        $line = $_.ToString()
        [void]$lines.Add($line)
        if ($line -match 'frame=|fps=|size=|time=|bitrate=|speed=') {
            Write-Host "`r$line" -NoNewline -ForegroundColor Cyan
            $lastWasProgress = $true
        }
        else {
            # 非进度行：如果上一行是进度，先换行再输出
            if ($lastWasProgress) {
                Write-Host ""
                $lastWasProgress = $false
            }
            Write-Host $line
        }
    }

    # 如果最后一行是进度，补换行
    if ($lastWasProgress) {
        Write-Host ""
    }

    $exit = $LASTEXITCODE
    try {
        [System.IO.File]::WriteAllLines($CaptureLog, $lines, $script:Utf8NoBom)
    } catch { }

    if ($exit -ne 0) {
        $err = $lines | Where-Object { $_ -match '(?i)error|failed|invalid' } | Select-Object -First 1
        if ([string]::IsNullOrEmpty($err)) { $err = '未知错误' }
        Write-Host "${Label}失败: $err" -ForegroundColor Red
        return $false
    }
    return $true
}

#==============================================================================
# 帮助信息函数（显示当前配置及使用方法）
#==============================================================================
function Show-Help {
    Write-Host "视频批量转码脚本"
    $m = if ($enc_2pass -eq 1) { '2-pass' } else { 'CRF' }
    Write-Host "当前配置: $CODEC_NAME, 编码模式: $m"
    if ($enc_cuda -eq 1) {
        Write-Host "硬件加速: CUDA (NVENC)"
    }
    if (-not [string]::IsNullOrEmpty($height_refer)) {
        Write-Host "高度参考值: ${height_refer}px (限制: ${height_limit}px)"
    }
    if (-not [string]::IsNullOrEmpty($fps_limit)) {
        Write-Host "帧率限制: ${fps_limit}fps"
    }

    $self = if ($PSCommandPath) { $PSCommandPath } else { 'video_convert.ps1' }

    Write-Host ""
    Write-Host "用法:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$self`" <输入目录> <输出目录>     处理目录下所有视频文件"
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$self`" <输入文件> <输出目录>     按配置文件处理"
    Write-Host ""
    Write-Host "配置文件格式:"
    Write-Host "  <视频文件名> [时间范围] (裁剪参数) <缩放比例>"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  video.mp4 [00:01:44-01:00:01] (100,100,1920,800) <1/2>"
    Write-Host "  movie.mkv (0,140,1920,800) <2/3>"
    Write-Host "  clip.avi [00:10:00-] <1>"
    Write-Host "  video2.mp4 <3/4>"
    Write-Host ""
    Write-Host "注意:"
    Write-Host "  在文件夹处理模式下，如果设置了height_refer，系统会根据视频高度自动缩放"
    Write-Host "  如果设置了fps_limit，系统会将高于此帧率的视频降低到fps_limit"
    Write-Host "  CUDA模式下2-pass会被强制降为CQP恒定质量模式"
    Write-Host "  依赖：ffmpeg / ffprobe 需加入 PATH（无需 jq、bc 等 Linux 工具）"
    exit 1
}

#==============================================================================
# 工具函数：获取视频容器格式（如mp4、mkv等）
# 参数：$1 - 输入文件路径
# 返回：小写的格式名
#==============================================================================
function Get-ContainerFormat {
    param([string]$InputFile)
    $ErrorActionPreference = 'Continue'
    $fmt = (& ffprobe -v quiet -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 $InputFile 2>$null | Select-Object -First 1)
    if ($null -eq $fmt) { return '' }
    return ([string]$fmt).ToLowerInvariant()
}

#==============================================================================
# 工具函数：获取视频基本信息
# 参数：$1 - 输入文件路径
# 输出：宽度 高度 时长(秒) 码率(kbps) 视频编码 音频编码
# 使用 ConvertFrom-Json 替代原版 jq
#==============================================================================
function Get-VideoInfo {
    param([string]$InputFile)
    $ErrorActionPreference = 'Continue'

    # 逐行接收并按换行拼接，避免 Out-String 按控制台宽度折行破坏长 JSON 行
    $probeOut = & ffprobe -v quiet -print_format json -show_format -show_streams $InputFile 2>$null
    $raw = ($probeOut -join [Environment]::NewLine)
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "ffprobe 未返回数据" }
    $info = $raw | ConvertFrom-Json

    # 找到第一个视频流
    $vs = $info.streams | Where-Object { $_.codec_type -eq 'video' } | Select-Object -First 1
    if ($null -eq $vs) { throw "未找到视频流" }

    # 提取宽度、高度
    $width  = [int]$vs.width
    $height = [int]$vs.height
    # 提取总时长
    $duration = $info.format.duration

    # 提取整体码率（如不存在则设为0），转换为 kbps（截断取整）
    $br = $info.format.bit_rate
    if ($null -eq $br -or [string]::IsNullOrEmpty([string]$br)) {
        $bitrate = 0
    } else {
        $bitrate = [int][math]::Truncate([double]$br / 1000)
    }

    # 视频编码格式名称
    $codec = [string]$vs.codec_name

    # 音频编码格式（第一个音频流）
    $as = $info.streams | Where-Object { $_.codec_type -eq 'audio' } | Select-Object -First 1
    $audioCodec = ''
    if ($null -ne $as) { $audioCodec = [string]$as.codec_name }

    return [pscustomobject]@{
        Width      = $width
        Height     = $height
        Duration   = $duration
        Bitrate    = $bitrate
        Codec      = $codec
        AudioCodec = $audioCodec
    }
}

#==============================================================================
# 工具函数：获取视频帧率（四舍五入到整数）
# 参数：$1 - 输入文件路径
# 返回：整数帧率
#==============================================================================
function Get-VideoFps {
    param([string]$InputFile)
    $ErrorActionPreference = 'Continue'

    $fpsInfo = (& ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 $InputFile 2>$null | Select-Object -First 1)
    if ($null -eq $fpsInfo) { $fpsInfo = '' }
    $fpsInfo = ([string]$fpsInfo).Trim()

    if ([string]::IsNullOrEmpty($fpsInfo) -or $fpsInfo -eq 'N/A') {
        return 25   # 默认值
    }

    if ($fpsInfo -match '^(\d+)/(\d+)$') {
        $num = [double]$Matches[1]
        $den = [double]$Matches[2]
        if ($den -ne 0) {
            # 等价：bc scale=2 得到两位小数，再 printf %.0f 四舍五入
            $fps = [math]::Round($num / $den, 2, [System.MidpointRounding]::AwayFromZero)
            return [int][math]::Round($fps, 0, [System.MidpointRounding]::AwayFromZero)
        }
    }

    try {
        $v = [double]::Parse($fpsInfo, [System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        return 25
    }
    # 直接取整（舍去小数）
    return [int][math]::Round($v, 0, [System.MidpointRounding]::AwayFromZero)
}

#==============================================================================
# 码率计算函数（基于分辨率）
# 参数：$1 - 宽度，$2 - 高度
# 返回：推荐的视频码率（kbps），已四舍五入到100的倍数
# 算法：基于720p (1280×720) 使用1300kbps的H.264基准，像素数线性缩放
#       HEVC码率 = H.264码率 × 0.8，最后四舍五入到100的倍数
#==============================================================================
function Calculate-Bitrate {
    param([int]$Width, [int]$Height)

    [long]$pixels = [long]$Width * [long]$Height

    # 计算等效H.264码率（像素数÷9216 ≈ 720p像素数，再乘基准13或12）
    if ($pixels -le 1000000) {       # 小于100万像素（约960×540）
        $h264 = [long][math]::Floor($pixels * 13 / 9216)
    } else {                         # 大于等于100万像素
        $h264 = [long][math]::Floor($pixels * 12 / 9216)
    }

    $rate = $h264
    if ($enc_hevc -eq 1) {
        # HEVC效率提升约20%，码率降为80%
        $rate = [long][math]::Floor($h264 * 8 / 10)
    }

    # 四舍五入到最近的100的倍数：((value + 50) / 100) * 100（整数除法）
    return [int]([math]::Floor(($rate + 50) / 100) * 100)
}

#==============================================================================
# 计算关键帧间隔（GOP大小）
# 参数：$1 - 输出帧率
# 返回：GOP帧数
#==============================================================================
function Calculate-GopSize {
    param([int]$Fps)
    $gop = $Fps * $gop_multiplier
    if ($gop -lt 24) { $gop = 24 }
    elseif ($gop -gt 600) { $gop = 600 }
    return $gop
}

#==============================================================================
# 获取GOP相关编码参数（根据软/硬编码区分参数格式）
# 参数：$1 - GOP大小
# 返回：ffmpeg 的编码器参数部分字符串
#==============================================================================
function Get-GopParams {
    param([int]$Gop)
    if ($enc_cuda -eq 1) {
        # NVENC 参数：固定GOP，禁用场景检测（避免插入额外关键帧影响编码控制）
        return @('-g', "$Gop", '-no-scenecut', '1')
    }
    if ($enc_hevc -eq 1) {
        # libx265 参数：通过x265-params传递关键帧间隔，并禁用场景切换检测
        return @('-g', "$Gop", '-x265-params', "keyint=${Gop}:min-keyint=${Gop}:no-scenecut=1")
    }
    # libx264 参数：keyint_min 设置最小关键帧间隔，sc_threshold=0 禁用场景检测
    return @('-g', "$Gop", '-keyint_min', "$Gop", '-sc_threshold', '0')
}

#==============================================================================
# 日志记录函数：记录每条文件的处理状态到日志文件
# 参数：$1 - 文件名（标识），$2 - 状态（SUCCESS/ERROR/SKIPPED），$3 - 附加信息，$4 - 日志文件路径
# 说明：控制台仍保留彩色输出；日志文件写纯文本（原版会把 ANSI 转义符写进日志）
#==============================================================================
function Log-Status {
    param([string]$Filename, [string]$Status, [string]$Message, [string]$LogFile)

    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Append-Log $LogFile "[$ts] ${Status}: $Filename - $Message"

    switch ($Status) {
        'SUCCESS' { Append-Log $LogFile "[✓] 成功: $Filename" }
        'SKIPPED' { Append-Log $LogFile "[~] 跳过: $Filename - $Message" }
        'ERROR'   { Append-Log $LogFile "[✗] 错误: $Filename - $Message" }
    }
}

#==============================================================================
# 快速复制/剪切函数（不重新编码，直接复制流）
# 参数：$1 - 输入文件，$2 - 输出文件，$3 - 开始时间（可选），$4 - 结束时间（可选）
# 返回：0 成功，1 失败
# 优化：-ss 放在 -i 之前，实现快速 seek，避免完整解码
#==============================================================================
function Copy-Or-Cut-Video {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$StartTime,
        [string]$EndTime
    )

    Write-Host "跳过编码，直接复制/剪切..." -ForegroundColor Blue

    # 构建命令：先指定开始时间（快速seek），再指定输入文件
    $a = New-Object -TypeName 'System.Collections.Generic.List[string]'
    if (-not [string]::IsNullOrEmpty($StartTime) -and $StartTime -ne '0') {
        [void]$a.Add('-ss'); [void]$a.Add($StartTime)
    }
    [void]$a.Add('-i'); [void]$a.Add($InputFile)
    if (-not [string]::IsNullOrEmpty($EndTime)) {
        [void]$a.Add('-to'); [void]$a.Add($EndTime)
    }

    # 流复制：仅复制第一个视频流和所有音频流（使用?避免无对应流时报错）
    [void]$a.Add('-c:v'); [void]$a.Add('copy')
    [void]$a.Add('-c:a'); [void]$a.Add('copy')
    [void]$a.Add('-map'); [void]$a.Add('0:v:0?')
    [void]$a.Add('-map'); [void]$a.Add('0:a?')
    [void]$a.Add('-movflags'); [void]$a.Add('+faststart')
    [void]$a.Add('-y'); [void]$a.Add($OutputFile)

    $cap = Join-Path -Path $script:TempDir -ChildPath "ffmpeg_output_${PID}_copy.log"
    $ok = Invoke-Ffmpeg -Arguments $a.ToArray() -CaptureLog $cap -Label '复制/剪切'
    if ($ok) {
        Write-Host "复制/剪切完成" -ForegroundColor Green
        return $true
    }
    Write-Host "复制/剪切失败" -ForegroundColor Red
    return $false
}

#==============================================================================
# CRF/CQP 编码函数（兼容软件编码和NVENC硬件编码）
# 参数：$1 - 基础 ffmpeg 命令前缀（含输入、滤镜），$2 - 目标码率（用于maxrate限制），
#       $3 - 输出文件，$4 - 输出帧率
# 返回：0 成功，1 失败
#==============================================================================
function Encode-Crf {
    param(
        [string[]]$BaseArgs,
        [int]$TargetBitrate,
        [string]$OutputFile,
        [int]$Fps
    )

    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 开始CRF/CQP编码..." -ForegroundColor Yellow

    $gop = Calculate-GopSize -Fps $Fps
    $gopParams = Get-GopParams -Gop $gop

    Write-Host "编码参数: 质量值=$CRF_VALUE, 最大码率=${TargetBitrate}k, GOP=${gop}帧 (FPS: ${Fps})"

    $a = New-Object -TypeName 'System.Collections.Generic.List[string]'
    foreach ($x in $BaseArgs) { [void]$a.Add($x) }

    [void]$a.Add('-c:v'); [void]$a.Add($VIDEO_CODEC)
    foreach ($x in $gopParams) { [void]$a.Add($x) }

    # 根据软/硬编码添加不同的质量参数：NVENC使用 -cq 控制质量，软件编码使用 -crf
    if ($enc_cuda -eq 1) { [void]$a.Add('-cq') } else { [void]$a.Add('-crf') }
    [void]$a.Add($CRF_VALUE)
    [void]$a.Add('-maxrate'); [void]$a.Add("${TargetBitrate}k")
    [void]$a.Add('-bufsize'); [void]$a.Add("$($TargetBitrate * 2)k")

    # 音频编码
    [void]$a.Add('-c:a'); [void]$a.Add($AUDIO_CODEC)
    [void]$a.Add('-b:a'); [void]$a.Add($AUDIO_BITRATE)
    [void]$a.Add('-map'); [void]$a.Add('0:a?')

    # 输出容器特性：快速启动（faststart），HEVC需添加hvc1标签以确保兼容性
    [void]$a.Add('-movflags'); [void]$a.Add('+faststart')
    if ($enc_hevc -eq 1) { [void]$a.Add('-tag:v'); [void]$a.Add('hvc1') }
    [void]$a.Add('-y'); [void]$a.Add($OutputFile)

    $cap = Join-Path -Path $script:TempDir -ChildPath "ffmpeg_output_${PID}_crf.log"
    $ok = Invoke-Ffmpeg -Arguments $a.ToArray() -CaptureLog $cap -Label '编码'
    if ($ok) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 编码成功" -ForegroundColor Green
        return $true
    }
    return $false
}

#==============================================================================
# 清理 2-pass 临时文件（等价原脚本 rm -f ffmpeg2pass-*.log / debug-*.log）
#==============================================================================
function Clear-2PassTemp {
    param([string]$PassLogPrefix, [string]$DebugPrefix)

    $dir  = Split-Path -Parent $PassLogPrefix
    $leaf = Split-Path -Leaf $PassLogPrefix
    Get-ChildItem -LiteralPath $dir -Filter "${leaf}*" -File -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    $ddir  = Split-Path -Parent $DebugPrefix
    $dleaf = Split-Path -Leaf $DebugPrefix
    Get-ChildItem -LiteralPath $ddir -Filter "${dleaf}-*.log" -File -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

#==============================================================================
# 2-pass 编码函数（仅软件编码，CUDA不支持）
# 参数：$1 - 基础 ffmpeg 命令前缀，$2 - 目标码率，$3 - 输出文件，$4 - 输出帧率
# 返回：0 成功，1 失败
#==============================================================================
function Encode-2Pass {
    param(
        [string[]]$BaseArgs,
        [int]$TargetBitrate,
        [string]$OutputFile,
        [int]$Fps
    )

    # CUDA模式下不应该调用此函数（已在外部判断）
    if ($enc_cuda -eq 1) {
        Write-Host "错误: CUDA模式下2-pass不被支持，该调用不应发生。" -ForegroundColor Red
        return $false
    }

    $gop = Calculate-GopSize -Fps $Fps
    $gopParams = Get-GopParams -Gop $gop

    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 开始2-pass编码..." -ForegroundColor Yellow
    Write-Host "编码参数: 目标码率=${TargetBitrate}k, GOP=${gop}帧 (FPS: ${Fps})"

    # 使用进程PID作为临时文件唯一后缀，防止并行处理时冲突
    $passLogPrefix = Join-Path -Path (Get-Location).Path -ChildPath "ffmpeg2pass-${PID}"
    $debugPrefix   = Join-Path -Path $script:TempDir -ChildPath "ffmpeg_output_${PID}"

    # 第一遍：分析视频，生成统计日志，不编码音频，输出到 NUL
    $p1 = New-Object -TypeName 'System.Collections.Generic.List[string]'
    foreach ($x in $BaseArgs) { [void]$p1.Add($x) }
    [void]$p1.Add('-c:v'); [void]$p1.Add($VIDEO_CODEC)
    foreach ($x in $gopParams) { [void]$p1.Add($x) }
    [void]$p1.Add('-b:v'); [void]$p1.Add("${TargetBitrate}k")
    [void]$p1.Add('-pass'); [void]$p1.Add('1')
    [void]$p1.Add('-passlogfile'); [void]$p1.Add($passLogPrefix)
    [void]$p1.Add('-an'); [void]$p1.Add('-f'); [void]$p1.Add('mp4')
    [void]$p1.Add('-y'); [void]$p1.Add('NUL')

    # 第二遍：使用第一遍的日志进行实际编码，同时加入音频
    $p2 = New-Object -TypeName 'System.Collections.Generic.List[string]'
    foreach ($x in $BaseArgs) { [void]$p2.Add($x) }
    [void]$p2.Add('-c:v'); [void]$p2.Add($VIDEO_CODEC)
    foreach ($x in $gopParams) { [void]$p2.Add($x) }
    [void]$p2.Add('-b:v'); [void]$p2.Add("${TargetBitrate}k")
    [void]$p2.Add('-pass'); [void]$p2.Add('2')
    [void]$p2.Add('-passlogfile'); [void]$p2.Add($passLogPrefix)
    [void]$p2.Add('-c:a'); [void]$p2.Add($AUDIO_CODEC)
    [void]$p2.Add('-b:a'); [void]$p2.Add($AUDIO_BITRATE)
    [void]$p2.Add('-map'); [void]$p2.Add('0:a?')
    [void]$p2.Add('-movflags'); [void]$p2.Add('+faststart')
    if ($enc_hevc -eq 1) { [void]$p2.Add('-tag:v'); [void]$p2.Add('hvc1') }
    [void]$p2.Add('-y'); [void]$p2.Add($OutputFile)

    # 执行第一遍
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 开始第一次编码..." -ForegroundColor Yellow
    $ok1 = Invoke-Ffmpeg -Arguments $p1.ToArray() -CaptureLog "${debugPrefix}-1.log" -Label '第一次编码'
    if (-not $ok1) {
        Clear-2PassTemp -PassLogPrefix $passLogPrefix -DebugPrefix $debugPrefix
        return $false
    }
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 第一次编码完成" -ForegroundColor Green

    # 执行第二遍
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 开始第二次编码..." -ForegroundColor Yellow
    $ok2 = Invoke-Ffmpeg -Arguments $p2.ToArray() -CaptureLog "${debugPrefix}-2.log" -Label '第二次编码'
    if ($ok2) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 编码成功" -ForegroundColor Green
    }
    Clear-2PassTemp -PassLogPrefix $passLogPrefix -DebugPrefix $debugPrefix
    return $ok2
}

#==============================================================================
# 自动缩放比例计算（仅用于文件夹模式且没有手动指定缩放比例的情况）
# 参数：$1 - 原始宽度，$2 - 原始高度
# 输出：如果触发缩放，打印 "分子 分母"；否则输出空字符串
# 逻辑：确定视频的较短边，若其大于 height_limit，则计算缩放到 height_refer 的比例
#==============================================================================
function Calculate-AutoScale {
    param([int]$Width, [int]$Height)

    if ([string]::IsNullOrEmpty($height_refer)) { return $null }

    if ($Height -gt $Width) {
        # 竖屏视频：宽度为较短边
        $reference = $Width
    } else {
        # 横屏或正方形：高度为较短边
        $reference = $Height
    }

    $limit = if ([string]::IsNullOrEmpty($height_limit)) { [int]::MaxValue } else { [int]$height_limit }
    if ($reference -gt $limit) {
        # 返回比例值：高度参考值 / 原始参考维度
        return "$height_refer $reference"
    }
    return $null
}

#==============================================================================
# 核心函数：处理单个视频文件
# 参数：$1 - 输入文件路径，$2 - 输出目录，$3 - 时间范围（如 [00:10:00-00:20:00]），
#       $4 - 裁剪参数（如 (x,y,w,h)），$5 - 手动缩放比例（如 <1/2>），$6 - 日志文件路径
# 返回：0 成功，1 失败
#==============================================================================
function Encode-Video {
    param(
        [string]$InputFile,
        [string]$OutputDir,
        [string]$TimeRange = '',
        [string]$CropParams = '',
        [string]$ScaleRatio = '',
        [string]$LogFile
    )

    # 提取文件名、基本名，生成输出路径（强制 .mp4 后缀）
    $filename  = [System.IO.Path]::GetFileName($InputFile)
    $basename  = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $outputFile = Join-Path -Path $OutputDir -ChildPath ($basename + '-encoded.mp4')

    Write-Host "开始处理: $filename" -ForegroundColor Green
    Write-Host "输出到: $outputFile"

    # 确定实际编码模式（CUDA下2-pass会被降级）
    if ($enc_cuda -eq 1 -and $enc_2pass -eq 1) {
        $actualMode = 'CQP（原2-pass已降级）'
    } elseif ($enc_2pass -eq 1) {
        $actualMode = '2-pass'
    } else {
        $actualMode = 'CRF/CQP'
    }
    Write-Host "编码配置: $CODEC_NAME, 模式: $actualMode"

    #---------------------------------------------------------------------
    # 1. 获取源文件信息
    #---------------------------------------------------------------------
    try {
        $info = Get-VideoInfo -InputFile $InputFile
    } catch {
        Log-Status $filename 'ERROR' '无法获取视频信息' $LogFile
        Write-Host "错误: 无法获取视频信息" -ForegroundColor Red
        return $false
    }

    if ($info.Width -eq 0 -or $info.Height -eq 0) {
        Log-Status $filename 'ERROR' '无效的视频分辨率' $LogFile
        Write-Host "错误: 无法获取视频信息" -ForegroundColor Red
        return $false
    }

    Write-Host "分辨率: $($info.Width)x$($info.Height), 时长: $($info.Duration)秒"
    Write-Host "原始码率: $($info.Bitrate)kbps"
    Write-Host "视频编码: $($info.Codec), 音频编码: $($info.AudioCodec)"

    # 获取帧率并判断是否需要降低
    $fps = Get-VideoFps -InputFile $InputFile
    Write-Host "原始帧率: ${fps}fps"

    $needReduceFps = $false
    $outputFps = $fps
    if (-not [string]::IsNullOrEmpty($fps_limit) -and $fps -gt [int]$fps_limit) {
        $needReduceFps = $true
        $outputFps = [int]$fps_limit
        Write-Host "帧率限制: ${fps_limit}fps (需要从${fps}fps降低)"
    }

    #---------------------------------------------------------------------
    # 2. 解析时间范围（用于剪切）
    #---------------------------------------------------------------------
    $startTime = ''
    $endTime   = ''
    if (-not [string]::IsNullOrEmpty($TimeRange) -and $TimeRange.Length -ge 2) {
        # 去掉外层方括号，按第一个 '-' 分割开始和结束时间
        $clean = $TimeRange.Substring(1, $TimeRange.Length - 2)
        $idx = $clean.IndexOf('-')
        if ($idx -ge 0) {
            $startTime = $clean.Substring(0, $idx)
            $endTime   = $clean.Substring($idx + 1)
        }
    }

    #---------------------------------------------------------------------
    # 3. 处理裁剪参数（crop）
    #---------------------------------------------------------------------
    $actualWidth  = $info.Width
    $actualHeight = $info.Height
    $filterChain  = ''

    if (-not [string]::IsNullOrEmpty($CropParams) -and $CropParams.Length -ge 2) {
        $clean = $CropParams.Substring(1, $CropParams.Length - 2)
        $p = $clean.Split(',')
        if ($p.Count -lt 4) {
            Log-Status $filename 'ERROR' '裁剪参数格式不正确' $LogFile
            Write-Host "错误: 裁剪参数格式不正确" -ForegroundColor Red
            return $false
        }
        $actualWidth  = [int]$p[2]
        $actualHeight = [int]$p[3]
        $filterChain  = "crop=$($p[2]):$($p[3]):$($p[0]):$($p[1])"
        Write-Host "裁剪后分辨率: ${actualWidth}x${actualHeight}"
    }

    #---------------------------------------------------------------------
    # 4. 处理缩放参数（手动指定 或 自动缩放）
    #---------------------------------------------------------------------
    $scaledWidth  = $actualWidth
    $scaledHeight = $actualHeight
    $needScale = $false
    $autoScaleApplied = $false

    if (-not [string]::IsNullOrEmpty($ScaleRatio) -and $ScaleRatio.Length -ge 2) {
        # 手动缩放比例（来自配置文件）
        $clean = $ScaleRatio.Substring(1, $ScaleRatio.Length - 2)
        if ($clean -match '^(\d+)/(\d+)$') {
            $num = [int]$Matches[1]
            $den = [int]$Matches[2]
            if ($den -eq 0) {
                Write-Host "错误: 缩放分母不能为0" -ForegroundColor Red
                return $false
            }
            if ($num -ne 1 -or $den -ne 1) {
                $needScale = $true
                $scaledWidth  = [int][math]::Floor($actualWidth  * $num / $den)
                $scaledHeight = [int][math]::Floor($actualHeight * $num / $den)
                # 确保宽度和高度为偶数（视频编码普遍要求）
                if ($scaledWidth  % 2 -ne 0) { $scaledWidth-- }
                if ($scaledHeight % 2 -ne 0) { $scaledHeight-- }
                # 追加到滤镜链
                if ([string]::IsNullOrEmpty($filterChain)) {
                    $filterChain = "scale=${scaledWidth}:${scaledHeight}"
                } else {
                    $filterChain = "$filterChain,scale=${scaledWidth}:${scaledHeight}"
                }
                Write-Host "手动缩放比例: ${num}/${den}"
                Write-Host "缩放后分辨率: ${scaledWidth}x${scaledHeight}"
            }
        }
    }
    elseif ([string]::IsNullOrEmpty($TimeRange) -and [string]::IsNullOrEmpty($CropParams)) {
        # 文件夹模式且无手动缩放、无裁剪：尝试自动缩放
        $auto = Calculate-AutoScale -Width $actualWidth -Height $actualHeight
        if (-not [string]::IsNullOrEmpty($auto)) {
            $parts = $auto.Split(' ')
            $hr = [int]$parts[0]
            $needScale = $true
            $autoScaleApplied = $true

            # 根据视频方向计算缩放后的实际尺寸（保持宽高比）
            if ($actualHeight -gt $actualWidth) {
                # 竖屏：将宽度缩放到 height_refer
                $scaledWidth  = $hr
                $scaledHeight = [int][math]::Floor($actualHeight * $hr / $actualWidth)
            } else {
                # 横屏：将高度缩放到 height_refer
                $scaledHeight = $hr
                $scaledWidth  = [int][math]::Floor($actualWidth * $hr / $actualHeight)
            }

            # 确保偶数
            if ($scaledWidth  % 2 -ne 0) { $scaledWidth-- }
            if ($scaledHeight % 2 -ne 0) { $scaledHeight-- }

            if ([string]::IsNullOrEmpty($filterChain)) {
                $filterChain = "scale=${scaledWidth}:${scaledHeight}"
            } else {
                $filterChain = "$filterChain,scale=${scaledWidth}:${scaledHeight}"
            }

            Write-Host "自动缩放: 较短边 > ${height_limit}px，缩放到 ${hr}px"
            Write-Host "缩放后分辨率: ${scaledWidth}x${scaledHeight}"
        }
    }

    #---------------------------------------------------------------------
    # 5. 应用帧率限制（添加fps滤镜）
    #---------------------------------------------------------------------
    if ($needReduceFps) {
        if ([string]::IsNullOrEmpty($filterChain)) {
            $filterChain = "fps=$outputFps"
        } else {
            $filterChain = "$filterChain,fps=$outputFps"
        }
        Write-Host "帧率限制: 从${fps}fps降低到${outputFps}fps"
    }

    #---------------------------------------------------------------------
    # 6. 计算目标码率（基于最终缩放后的分辨率）
    #---------------------------------------------------------------------
    $targetBitrate = Calculate-Bitrate -Width $scaledWidth -Height $scaledHeight
    Write-Host "目标码率: ${targetBitrate}kbps"

    #---------------------------------------------------------------------
    # 7. 是否需要重新编码判断
    #    满足以下任一条件时必须编码：
    #    a) 需要缩放/裁剪/帧率降低
    #    b) 原始码率 > 目标码率 × 1.2
    #    否则直接复制流
    #---------------------------------------------------------------------
    $needEncode = $true
    if ($needScale -or -not [string]::IsNullOrEmpty($CropParams) -or $needReduceFps) {
        $needEncode = $true
        if ($needScale)                                     { Write-Host "需要缩放，重新编码" -ForegroundColor Yellow }
        if (-not [string]::IsNullOrEmpty($CropParams))      { Write-Host "需要裁剪，重新编码" -ForegroundColor Yellow }
        if ($needReduceFps)                                 { Write-Host "需要降低帧率，重新编码" -ForegroundColor Yellow }
    }
    elseif ($info.Bitrate -gt 0) {
        # 等价原版 bc 的 target_bitrate * 1.2；目标码率恒为100的倍数，用 6/5 整数运算避免浮点误差
        $threshold = [int]([math]::Floor($targetBitrate * 6 / 5))
        if ($info.Bitrate -gt $threshold) {
            $needEncode = $true
            Write-Host "重新编码: 原始码率($($info.Bitrate)kbps) > 目标码率(${targetBitrate}kbps) × 1.2" -ForegroundColor Yellow
        } else {
            $needEncode = $false
            Write-Host "跳过编码: 原始码率($($info.Bitrate)kbps) ≤ 目标码率(${targetBitrate}kbps) × 1.2" -ForegroundColor Blue
        }
    } else {
        Write-Host "无法获取原始码率，重新编码" -ForegroundColor Yellow
        $needEncode = $true
    }

    # 如果无需编码，直接复制/剪切
    if (-not $needEncode) {
        if (Copy-Or-Cut-Video -InputFile $InputFile -OutputFile $outputFile -StartTime $startTime -EndTime $endTime) {
            Log-Status $filename 'SUCCESS' '直接复制完成' $LogFile
            Write-Host "处理完成" -ForegroundColor Green
            return $true
        }
        Log-Status $filename 'ERROR' '直接复制失败' $LogFile
        Write-Host "处理失败" -ForegroundColor Red
        return $false
    }

    #---------------------------------------------------------------------
    # 8. 构建编码命令基础部分
    #    -ss 放在 -i 之前以实现快速 seek
    #---------------------------------------------------------------------
    $base = New-Object -TypeName 'System.Collections.Generic.List[string]'
    [void]$base.Add('-i'); [void]$base.Add($InputFile)
    if (-not [string]::IsNullOrEmpty($startTime) -and $startTime -ne '0') {
        [void]$base.Add('-ss'); [void]$base.Add($startTime)
    }
    if (-not [string]::IsNullOrEmpty($endTime)) {
        [void]$base.Add('-to'); [void]$base.Add($endTime)
    }

    # 滤镜和映射：若存在滤镜链，使用 -filter_complex 并映射输出标签 [v]
    if (-not [string]::IsNullOrEmpty($filterChain)) {
        [void]$base.Add('-filter_complex'); [void]$base.Add($filterChain + '[v]')
        [void]$base.Add('-map'); [void]$base.Add('[v]')
    } else {
        # 无滤镜时直接映射第一个视频流
        [void]$base.Add('-map'); [void]$base.Add('0:v:0')
    }

    #---------------------------------------------------------------------
    # 9. 根据编码模式选择执行函数（CUDA下强制使用CRF/CQP）
    #---------------------------------------------------------------------
    $actual2pass = $enc_2pass
    if ($enc_cuda -eq 1 -and $enc_2pass -eq 1) {
        Write-Host "警告: CUDA不支持2-pass，将采用CQP恒定质量模式" -ForegroundColor Yellow
        $actual2pass = 0
    }

    if ($actual2pass -eq 1) {
        $ok = Encode-2Pass -BaseArgs $base.ToArray() -TargetBitrate $targetBitrate -OutputFile $outputFile -Fps $outputFps
    } else {
        $ok = Encode-Crf   -BaseArgs $base.ToArray() -TargetBitrate $targetBitrate -OutputFile $outputFile -Fps $outputFps
    }

    #---------------------------------------------------------------------
    # 10. 记录结果
    #---------------------------------------------------------------------
    if ($ok) {
        Log-Status $filename 'SUCCESS' '编码完成' $LogFile
        Write-Host "编码完成: $filename" -ForegroundColor Green
    } else {
        Log-Status $filename 'ERROR' '编码过程失败' $LogFile
        Write-Host "编码失败: $filename" -ForegroundColor Red
    }

    Write-Host ""
    return $ok
}

#==============================================================================
# 主函数：程序入口
#==============================================================================
function main {
    $cli = @($args)   # 复制脚本的位置参数，避免与函数内 $args 混淆

    # 显示当前配置
    Write-Host "=== 视频转码脚本 ===" -ForegroundColor Green
    Write-Host "视频编码: $CODEC_NAME"
    if ($enc_cuda -eq 1) { Write-Host "硬件加速: CUDA (NVENC)" }
    $modeText = if ($enc_2pass -eq 1 -and $enc_cuda -eq 0) { '2-pass' } else { 'CRF/CQP' }
    Write-Host "编码模式: $modeText"
    Write-Host "音频编码: $AUDIO_CODEC $AUDIO_BITRATE"
    if (-not [string]::IsNullOrEmpty($height_refer)) {
        Write-Host "高度参考值: ${height_refer}px (限制: ${height_limit}px)"
    }
    if (-not [string]::IsNullOrEmpty($fps_limit)) {
        Write-Host "帧率限制: ${fps_limit}fps"
    }
    Write-Host ""

    # 参数检查：必须提供两个参数
    if ($cli.Count -ne 2) { Show-Help }

    $inputPath = [string]$cli[0]
    $outDir    = [string]$cli[1]

    # 若输出目录不存在则创建
    if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
        [void][System.IO.Directory]::CreateDirectory($outDir)
        Write-Host "创建输出目录: $outDir"
    }

    # 创建日志文件（带时间戳，存储在输出目录中）
    $logFile = Join-Path -Path $outDir -ChildPath ("encode_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
    Write-Host "日志文件: $logFile" -ForegroundColor Magenta
    Append-Log $logFile ("转码任务开始: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    Append-Log $logFile "输入: $inputPath"
    Append-Log $logFile "输出目录: $outDir"
    Append-Log $logFile "配置: $CODEC_NAME, 模式: $modeText"
    if (-not [string]::IsNullOrEmpty($height_refer)) {
        Append-Log $logFile "高度参考值: ${height_refer}px (限制: ${height_limit}px)"
    }
    if (-not [string]::IsNullOrEmpty($fps_limit)) {
        Append-Log $logFile "帧率限制: ${fps_limit}fps"
    }
    Append-Log $logFile ''

    #---------------------------------------------------------------------
    # 检查必要的依赖工具（jq / bc 已由 PowerShell 原生替代，无需安装）
    #---------------------------------------------------------------------
    foreach ($tool in @('ffmpeg', 'ffprobe')) {
        if ($null -eq (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Host "错误: $tool 未安装或未加入 PATH" -ForegroundColor Red
            Log-Status 'SYSTEM' 'ERROR' "$tool 未安装或未加入 PATH" $logFile
            Write-Host "请安装 ffmpeg 的 Windows 构建（含 ffprobe），并把 bin 目录加入 PATH"
            exit 1
        }
    }

    #---------------------------------------------------------------------
    # 构建待处理文件列表
    # - 若输入是目录：递归搜索所有支持的视频文件
    # - 若输入是文件：视为配置文件，逐行解析
    #---------------------------------------------------------------------
    $fileList = New-Object -TypeName 'System.Collections.Generic.List[string]'
    $parseLine = $false

    if (Test-Path -LiteralPath $inputPath -PathType Container) {
        Write-Host "处理目录: $inputPath" -ForegroundColor Green

        # 常见视频扩展名列表（不区分大小写，等价 find -iname）
        $exts = @('mp4','avi','mkv','mov','wmv','flv','webm','m4v','mpg','mpeg','ts',
                  '3gp','f4v','rmvb','rm','asf','vob','dat','mts','m2ts')

        foreach ($ext in $exts) {
            Get-ChildItem -LiteralPath $inputPath -Recurse -File -Force -Filter "*.$ext" -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -ieq ".$ext" } |
                ForEach-Object { [void]$fileList.Add($_.FullName) }
        }
    }
    elseif (Test-Path -LiteralPath $inputPath -PathType Leaf) {
        Write-Host "处理配置文件: $inputPath" -ForegroundColor Green
        $parseLine = $true

        $lineNumber = 0
        foreach ($line in (Get-Content -LiteralPath $inputPath)) {
            $lineNumber++
            $trimmed = ([string]$line).Trim()

            # 跳过空行和注释行（以#开头）
            if ([string]::IsNullOrEmpty($trimmed) -or $trimmed.StartsWith('#')) { continue }

            if ($trimmed -match $script:LinePattern) {
                $fname = ([string]$Matches[1]).Trim()
                if (-not (Test-Path -LiteralPath $fname -PathType Leaf)) {
                    Write-Host "错误 (第${lineNumber}行): 文件不存在 - $fname" -ForegroundColor Red
                    Log-Status $fname 'ERROR' "第${lineNumber}行: 文件不存在" $logFile
                    continue
                }
                [void]$fileList.Add($trimmed)
            } else {
                Write-Host "错误 (第${lineNumber}行): 格式不正确" -ForegroundColor Red
                Log-Status "LINE $lineNumber" 'ERROR' "格式不正确: $trimmed" $logFile
            }
        }
    }
    else {
        Write-Host "错误: 输入不存在" -ForegroundColor Red
        Show-Help
    }

    #---------------------------------------------------------------------
    # 依次处理每个文件
    #---------------------------------------------------------------------
    $total = $fileList.Count
    $count = 0
    $successCount = 0
    $errorCount = 0
    Write-Host "需要处理 $total 个视频文件"

    foreach ($file in $fileList) {
        $count++
        Write-Host "==================== $count/$total ====================" -ForegroundColor Cyan

        try {
            if (-not $parseLine) {
                # 目录模式：直接传递文件路径
                if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
                    Write-Host "错误: 文件不存在 - $file" -ForegroundColor Red
                    Log-Status $file 'ERROR' '文件不存在' $logFile
                    $errorCount++
                    continue
                }
                Write-Host "文件: $file" -ForegroundColor Yellow

                # 单文件失败不影响后续文件（等价 set +e / set -e）
                $ok = Encode-Video -InputFile $file -OutputDir $outDir -LogFile $logFile
            }
            else {
                # 配置文件模式：再次解析行内容，提取各个参数
                if ($file -match $script:LinePattern) {
                    $fname       = ([string]$Matches[1]).Trim()
                    $timeRange   = [string]$Matches[2]
                    $cropParams  = [string]$Matches[3]
                    $scaleRatio  = [string]$Matches[4]

                    if (-not (Test-Path -LiteralPath $fname -PathType Leaf)) {
                        Write-Host "错误: 文件不存在 - $fname" -ForegroundColor Red
                        Log-Status $fname 'ERROR' '文件不存在' $logFile
                        $errorCount++
                        continue
                    }

                    Write-Host "文件: $fname" -ForegroundColor Yellow
                    if (-not [string]::IsNullOrEmpty($timeRange))  { Write-Host "时间范围: $timeRange" -ForegroundColor Yellow }
                    if (-not [string]::IsNullOrEmpty($cropParams))  { Write-Host "裁剪参数: $cropParams" -ForegroundColor Yellow }
                    if (-not [string]::IsNullOrEmpty($scaleRatio))  { Write-Host "缩放比例: $scaleRatio" -ForegroundColor Yellow }

                    $ok = Encode-Video -InputFile $fname -OutputDir $outDir -TimeRange $timeRange -CropParams $cropParams -ScaleRatio $scaleRatio -LogFile $logFile
                }
                else {
                    # 安全兜底：正常情况下不会执行到这里
                    Write-Host "错误: 无法解析行 - $file" -ForegroundColor Red
                    Log-Status 'LINE' 'ERROR' "无法解析: $file" $logFile
                    $errorCount++
                    continue
                }
            }

            if ($ok) { $successCount++ } else { $errorCount++ }
        }
        catch {
            Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
            Log-Status $file 'ERROR' "处理异常: $($_.Exception.Message)" $logFile
            $errorCount++
        }

        # 文件之间增加空行提高可读性
        if ($count -lt $total) { Write-Host "" }
    }

    #---------------------------------------------------------------------
    # 输出最终统计信息
    #---------------------------------------------------------------------
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "任务完成统计:" -ForegroundColor Green
    Write-Host "总共处理: $total 个文件"
    Write-Host "成功: $successCount" -ForegroundColor Green
    Write-Host "失败: $errorCount" -ForegroundColor Red
    Write-Host "日志文件: $logFile" -ForegroundColor Magenta

    # 同时写入日志文件
    Append-Log $logFile ''
    Append-Log $logFile '任务完成统计:'
    Append-Log $logFile "总共处理: $total 个文件"
    Append-Log $logFile "成功: $successCount"
    Append-Log $logFile "失败: $errorCount"
    Append-Log $logFile ("转码任务结束: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

    Write-Host "所有任务完成！" -ForegroundColor Green
}

# 脚本入口（等价 main "$@"）
main @args
