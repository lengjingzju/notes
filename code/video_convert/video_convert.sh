#!/bin/bash

#==============================================================================
# 编码配置选项（用户可根据需求修改以下变量）
#==============================================================================

# 视频编码器选择
enc_hevc=1          # 0 = H.264 / 1 = HEVC (H.265)
                    # 注意：此选项影响软编码和硬编码的编码器选择

# 编码模式选择
enc_2pass=1         # 0 = CRF恒定质量模式（单次编码）
                    # 1 = 2-pass恒定码率模式（两次编码）
                    # 注意：CUDA硬件编码不支持真正的2-pass，启用时自动降级为CQP

# 是否启用CUDA硬件加速编码
enc_cuda=0          # 0 = 纯软件编码（libx264/libx265）
                    # 1 = CUDA硬件编码（h264_nvenc/hevc_nvenc）
                    # 前提：系统需安装NVIDIA驱动及支持NVENC的GPU

# 高度参考值配置（仅用于文件夹批量处理模式）
height_refer=1080   # 参考高度（单位：像素）
                    # 当视频较短边大于height_limit时，将自动缩放到此高度
                    # 设置为空字符串 "" 则不限制

height_limit=1100   # 触发自动缩放的高度阈值（单位：像素）
                    # 较短边超过该值才会进行缩放

# 帧率限制配置
fps_limit=30        # 帧率上限（单位：fps）
                    # 当视频原始帧率高于此值时，自动降低到该值
                    # 设置为空字符串 "" 则保留原始帧率

# CRF / CQP 质量值
CRF_VALUE="23"      # - 软件编码（libx264/libx265）：0-51，值越小质量越高，23为默认
                    # - 硬件编码（NVENC）：-cq 参数范围可能不同，但此处通用值23通常有效

# 音频编码器及码率（统一使用AAC 64kbps，兼容性好）
AUDIO_CODEC="aac"
AUDIO_BITRATE="64k"

#==============================================================================
# 脚本功能：批量视频转码
# 用法：
#   ./encode.sh <输入目录> <输出目录>    # 处理目录下所有视频文件
#   ./encode.sh <配置文件> <输出目录>    # 按配置文件逐行处理
#==============================================================================

# 设定严格错误处理：遇到未捕获的错误时立即退出
# （但会在单文件处理循环内临时关闭，以允许继续处理后续文件）
set -e

#==============================================================================
# 终端颜色定义（用于美化输出）
#==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 恢复默认颜色

#==============================================================================
# 根据配置选择编码器及相关显示名称
# 优先级：enc_cuda 覆盖软/硬编码器选择
#==============================================================================
if [ $enc_cuda -eq 1 ]; then
    if [ $enc_hevc -eq 1 ]; then
        VIDEO_CODEC="hevc_nvenc"
        CODEC_NAME="HEVC (H.265 NVENC)"
    else
        VIDEO_CODEC="h264_nvenc"
        CODEC_NAME="H.264 (NVENC)"
    fi
else
    if [ $enc_hevc -eq 1 ]; then
        VIDEO_CODEC="libx265"
        CODEC_NAME="HEVC (H.265)"
    else
        VIDEO_CODEC="libx264"
        CODEC_NAME="H.264"
    fi
fi

#==============================================================================
# 帮助信息函数
# 显示当前配置及使用方法
#==============================================================================
show_help() {
    echo "视频批量转码脚本"
    echo "当前配置: $CODEC_NAME, 编码模式: $([ $enc_2pass -eq 1 ] && echo "2-pass" || echo "CRF")"
    if [ $enc_cuda -eq 1 ]; then
        echo "硬件加速: CUDA (NVENC)"
    fi
    if [ -n "$height_refer" ]; then
        echo "高度参考值: ${height_refer}px (限制: ${height_limit}px)"
    fi
    if [ -n "$fps_limit" ]; then
        echo "帧率限制: ${fps_limit}fps"
    fi
    echo ""
    echo "用法:"
    echo "  $0 <输入目录> <输出目录>     处理目录下所有视频文件"
    echo "  $0 <输入文件> <输出目录>     按配置文件处理"
    echo ""
    echo "配置文件格式:"
    echo "  <视频文件名> [时间范围] (裁剪参数) <缩放比例>"
    echo ""
    echo "示例:"
    echo "  video.mp4 [00:01:44-01:00:01] (100,100,1920,800) <1/2>"
    echo "  movie.mkv (0,140,1920,800) <2/3>"
    echo "  clip.avi [00:10:00-] <1>"
    echo "  video2.mp4 <3/4>"
    echo ""
    echo "注意:"
    echo "  在文件夹处理模式下，如果设置了height_refer，系统会根据视频高度自动缩放"
    echo "  如果设置了fps_limit，系统会将高于此帧率的视频降低到fps_limit"
    echo "  CUDA模式下2-pass会被强制降为CQP恒定质量模式"
    exit 1
}

#==============================================================================
# 工具函数：获取视频容器格式（如mp4、mkv等）
# 参数：$1 - 输入文件路径
# 返回：小写的格式名
#==============================================================================
get_container_format() {
    local input_file="$1"
    local format=$(ffprobe -v quiet -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null)
    echo "$format" | tr '[:upper:]' '[:lower:]'
}

#==============================================================================
# 工具函数：获取视频基本信息
# 参数：$1 - 输入文件路径
# 输出：宽度 高度 时长(秒) 码率(kbps) 视频编码 音频编码
#==============================================================================
get_video_info() {
    local input_file="$1"
    local info_json=$(ffprobe -v quiet -print_format json -show_format -show_streams "$input_file")

    # 找到第一个视频流
    local video_stream=$(echo "$info_json" | jq -r '.streams[] | select(.codec_type=="video")')

    # 提取宽度、高度
    local width=$(echo "$video_stream" | jq -r '.width')
    local height=$(echo "$video_stream" | jq -r '.height')
    # 提取总时长
    local duration=$(echo "$info_json" | jq -r '.format.duration')

    # 提取整体码率（如不存在则设为0）
    local bitrate=$(echo "$info_json" | jq -r '.format.bit_rate')
    if [ "$bitrate" = "null" ] || [ -z "$bitrate" ]; then
        bitrate=0
    else
        bitrate=$((bitrate / 1000))  # 转换为kbps
    fi

    # 视频编码格式名称
    local codec_name=$(echo "$video_stream" | jq -r '.codec_name')

    # 音频编码格式（第一个音频流）
    local audio_stream=$(echo "$info_json" | jq -r '.streams[] | select(.codec_type=="audio")')
    local audio_codec=""
    if [ -n "$audio_stream" ] && [ "$audio_stream" != "null" ]; then
        audio_codec=$(echo "$audio_stream" | jq -r '.codec_name')
    fi

    echo "$width $height $duration $bitrate $codec_name $audio_codec"
}

#==============================================================================
# 工具函数：获取视频帧率（四舍五入到整数）
# 参数：$1 - 输入文件路径
# 返回：整数帧率
#==============================================================================
get_video_fps() {
    local input_file="$1"
    local fps_info
    fps_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null | head -1)

    if [ -z "$fps_info" ] || [ "$fps_info" = "N/A" ]; then
        echo "25"   # 默认值
        return
    fi

    # 处理分数形式帧率（如30000/1001）
    if [[ "$fps_info" =~ ^([0-9]+)/([0-9]+)$ ]]; then
        local numerator=${BASH_REMATCH[1]}
        local denominator=${BASH_REMATCH[2]}
        if [ "$denominator" -ne 0 ]; then
            local fps=$(echo "scale=2; $numerator / $denominator" | bc 2>/dev/null || echo "25")
            printf "%.0f" "$fps"  # 四舍五入
            return
        fi
    fi

    # 直接取整（舍去小数）
    printf "%.0f" "$fps_info"
}

#==============================================================================
# 码率计算函数（基于分辨率）
# 参数：$1 - 宽度，$2 - 高度
# 返回：推荐的视频码率（kbps），已四舍五入到100的倍数
# 算法：基于720p (1280×720) 使用1300kbps的H.264基准，像素数线性缩放
#       HEVC码率 = H.264码率 × 0.8
#==============================================================================
calculate_bitrate() {
    local width=$1
    local height=$2
    local pixels=$((width * height))

    # 内部函数：四舍五入到最近的100的倍数
    round100() {
        local value=$1
        echo $(( ((value + 50) / 100) * 100 ))
    }

    # 计算等效H.264码率（像素数÷9216 ≈ 720p像素数，再乘基准13或12）
    local h264_bitrate
    if [ $pixels -le 1000000 ]; then       # 小于100万像素（约960×540）
        h264_bitrate=$(( pixels * 13 / 9216 ))
    else                                   # 大于等于100万像素
        h264_bitrate=$(( pixels * 12 / 9216 ))
    fi

    if [ $enc_hevc -eq 1 ]; then
        # HEVC效率提升约20%，码率降为80%
        local hevc_rate=$(( h264_bitrate * 8 / 10 ))
        echo $(round100 $hevc_rate)
    else
        echo $(round100 $h264_bitrate)
    fi
}

#==============================================================================
# 计算关键帧间隔（GOP大小）
# 参数：$1 - 输出帧率
# 返回：GOP帧数（约2秒的帧数，范围[24,250]）
#==============================================================================
calculate_gop_size() {
    local fps=$1
    local gop_size=$((fps * 2))
    if [ $gop_size -lt 24 ]; then
        gop_size=24
    elif [ $gop_size -gt 250 ]; then
        gop_size=250
    fi
    echo "$gop_size"
}

#==============================================================================
# 获取GOP相关编码参数（根据软/硬编码区分参数格式）
# 参数：$1 - GOP大小
# 返回：ffmpeg 的编码器参数部分字符串
#==============================================================================
get_gop_params() {
    local gop_size=$1
    if [ $enc_cuda -eq 1 ]; then
        # NVENC 参数：固定GOP，禁用场景检测（避免插入额外关键帧影响编码控制）
        echo "-g $gop_size -no-scenecut 1"
    else
        if [ $enc_hevc -eq 1 ]; then
            # libx265 参数：通过x265-params传递关键帧间隔，并禁用场景切换检测
            echo "-g $gop_size -x265-params keyint=${gop_size}:min-keyint=${gop_size}:no-scenecut=1"
        else
            # libx264 参数：keyint_min 设置最小关键帧间隔，sc_threshold=0 禁用场景检测
            echo "-g $gop_size -keyint_min $gop_size -sc_threshold 0"
        fi
    fi
}

#==============================================================================
# 日志记录函数：记录每条文件的处理状态到日志文件
# 参数：$1 - 文件名（标识），$2 - 状态（SUCCESS/ERROR/SKIPPED），$3 - 附加信息，$4 - 日志文件路径
#==============================================================================
log_status() {
    local filename="$1"
    local status="$2"
    local message="$3"
    local log_file="$4"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $status: $filename - $message" >> "$log_file"

    case "$status" in
        "SUCCESS")
            echo -e "${GREEN}[✓] 成功: $filename${NC}" >> "$log_file"
            ;;
        "SKIPPED")
            echo -e "${BLUE}[~] 跳过: $filename - $message${NC}" >> "$log_file"
            ;;
        "ERROR")
            echo -e "${RED}[✗] 错误: $filename - $message${NC}" >> "$log_file"
            ;;
    esac
}

#==============================================================================
# 快速复制/剪切函数（不重新编码，直接复制流）
# 参数：$1 - 输入文件，$2 - 输出文件，$3 - 开始时间（可选），$4 - 结束时间（可选）
# 返回：0 成功，1 失败
# 优化：-ss 放在 -i 之前，实现快速 seek，避免完整解码
#==============================================================================
copy_or_cut_video() {
    local input_file="$1"
    local output_file="$2"
    local start_time="$3"
    local end_time="$4"

    echo -e "${BLUE}跳过编码，直接复制/剪切...${NC}"

    # 构建命令：先指定开始时间（快速seek），再指定输入文件
    local ffmpeg_cmd="ffmpeg"
    if [ -n "$start_time" ] && [ "$start_time" != "0" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -ss $start_time"
    fi
    ffmpeg_cmd="$ffmpeg_cmd -i \"$input_file\""
    if [ -n "$end_time" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -to $end_time"
    fi

    # 流复制：仅复制第一个视频流和所有音频流（使用?避免无对应流时报错）
    ffmpeg_cmd="$ffmpeg_cmd -c:v copy -c:a copy -map 0:v:0? -map 0:a? -movflags +faststart -y \"$output_file\""

    echo -e "执行: $ffmpeg_cmd"
    if eval $ffmpeg_cmd 2>&1 | tee /tmp/ffmpeg_output.log | grep -E "frame|fps|size|time|bitrate|speed"; then
        echo -e "${GREEN}复制/剪切完成${NC}"
        return 0
    else
        local error_msg=$(grep -i "error\|failed\|invalid" /tmp/ffmpeg_output.log | head -1)
        echo -e "${RED}复制/剪切失败: ${error_msg:-未知错误}${NC}"
        return 1
    fi
}

#==============================================================================
# CRF/CQP 编码函数（兼容软件编码和NVENC硬件编码）
# 参数：$1 - 基础 ffmpeg 命令前缀（含输入、滤镜），$2 - 目标码率（用于maxrate限制），
#       $3 - 输出文件，$4 - 输出帧率
# 返回：0 成功，1 失败
#==============================================================================
encode_crf() {
    local ffmpeg_cmd="$1"
    local target_bitrate="$2"
    local output_file="$3"
    local fps="$4"

    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始CRF/CQP编码...${NC}"

    local gop_size=$(calculate_gop_size $fps)
    local gop_params=$(get_gop_params $gop_size)

    echo -e "编码参数: 质量值=$CRF_VALUE, 最大码率=${target_bitrate}k, GOP=${gop_size}帧 (FPS: ${fps})"

    # 根据软/硬编码添加不同的质量参数
    if [ $enc_cuda -eq 1 ]; then
        # NVENC使用 -cq 控制质量
        ffmpeg_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -cq $CRF_VALUE -maxrate ${target_bitrate}k -bufsize $((target_bitrate * 2))k"
    else
        # 软件编码使用 -crf
        ffmpeg_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -crf $CRF_VALUE -maxrate ${target_bitrate}k -bufsize $((target_bitrate * 2))k"
    fi

    # 音频编码
    ffmpeg_cmd="$ffmpeg_cmd -c:a $AUDIO_CODEC -b:a $AUDIO_BITRATE -map 0:a?"

    # 输出容器特性：快速启动（faststart），HEVC需添加hvc1标签以确保兼容性
    if [ $enc_hevc -eq 1 ]; then
        ffmpeg_cmd="$ffmpeg_cmd -movflags +faststart -tag:v hvc1 -y \"$output_file\""
    else
        ffmpeg_cmd="$ffmpeg_cmd -movflags +faststart -y \"$output_file\""
    fi

    # 执行编码并显示进度
    if eval $ffmpeg_cmd 2>&1 | tee /tmp/ffmpeg_output.log | grep -E "frame|fps|size|time|bitrate|speed"; then
        echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') 编码成功${NC}"
        return 0
    else
        local error_msg=$(grep -i "error\|failed\|invalid" /tmp/ffmpeg_output.log | head -1)
        echo -e "${RED}编码失败: ${error_msg:-未知错误}${NC}"
        return 1
    fi
}

#==============================================================================
# 2-pass 编码函数（仅软件编码，CUDA不支持）
# 参数：$1 - 基础 ffmpeg 命令前缀，$2 - 目标码率，$3 - 输出文件，$4 - 输出帧率
# 返回：0 成功，1 失败
#==============================================================================
encode_2pass() {
    local ffmpeg_cmd="$1"
    local target_bitrate="$2"
    local output_file="$3"
    local fps="$4"

    # CUDA模式下不应该调用此函数（已在外部判断）
    if [ $enc_cuda -eq 1 ]; then
        echo -e "${RED}错误: CUDA模式下2-pass不被支持，该调用不应发生。${NC}"
        return 1
    fi

    local gop_size=$(calculate_gop_size $fps)
    local gop_params=$(get_gop_params $gop_size)

    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始2-pass编码...${NC}"
    echo -e "编码参数: 目标码率=${target_bitrate}k, GOP=${gop_size}帧 (FPS: ${fps})"

    # 使用进程PID作为临时文件唯一后缀，防止并行处理时冲突
    local UNIQUE_ID="$$"
    local PASSLOG_PREFIX="ffmpeg2pass-${UNIQUE_ID}"
    local DEBUGLOG_PREFIX="/tmp/ffmpeg_output_${UNIQUE_ID}"

    # 第一遍：分析视频，生成统计日志，不编码音频，输出到/dev/null
    local pass1_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -b:v ${target_bitrate}k -pass 1 -passlogfile ${PASSLOG_PREFIX} -an -f mp4 -y /dev/null"

    # 第二遍：使用第一遍的日志进行实际编码，同时加入音频
    local pass2_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -b:v ${target_bitrate}k -pass 2 -passlogfile ${PASSLOG_PREFIX} -c:a $AUDIO_CODEC -b:a $AUDIO_BITRATE -map 0:a?"

    if [ $enc_hevc -eq 1 ]; then
        pass2_cmd="$pass2_cmd -movflags +faststart -tag:v hvc1 -y \"$output_file\""
    else
        pass2_cmd="$pass2_cmd -movflags +faststart -y \"$output_file\""
    fi

    # 执行第一遍
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始第一次编码...${NC}"
    if ! eval $pass1_cmd 2>&1 | tee "${DEBUGLOG_PREFIX}-1.log" | grep -E "frame|fps|size|time|bitrate|speed"; then
        local error_msg=$(grep -i "error\|failed\|invalid" "${DEBUGLOG_PREFIX}-1.log" | head -1)
        echo -e "${RED}第一次编码失败: ${error_msg:-未知错误}${NC}"
        # 清理可能遗留的临时文件
        rm -f ${PASSLOG_PREFIX}-*.log ${PASSLOG_PREFIX}-*.log.mbtree ${DEBUGLOG_PREFIX}-*.log 2>/dev/null
        return 1
    fi

    # 执行第二遍
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始第二次编码...${NC}"
    if eval $pass2_cmd 2>&1 | tee "${DEBUGLOG_PREFIX}-2.log" | grep -E "frame|fps|size|time|bitrate|speed"; then
        echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') 编码成功${NC}"
        rm -f ${PASSLOG_PREFIX}-*.log ${PASSLOG_PREFIX}-*.log.mbtree ${DEBUGLOG_PREFIX}-*.log 2>/dev/null
        return 0
    else
        local error_msg=$(grep -i "error\|failed\|invalid" "${DEBUGLOG_PREFIX}-2.log" | head -1)
        echo -e "${RED}第二次编码失败: ${error_msg:-未知错误}${NC}"
        rm -f ${PASSLOG_PREFIX}-*.log ${PASSLOG_PREFIX}-*.log.mbtree ${DEBUGLOG_PREFIX}-*.log 2>/dev/null
        return 1
    fi
}

#==============================================================================
# 自动缩放比例计算（仅用于文件夹模式且没有手动指定缩放比例的情况）
# 参数：$1 - 原始宽度，$2 - 原始高度
# 输出：如果触发缩放，打印 "分子 分母"；否则输出空字符串
# 逻辑：确定视频的较短边，若其大于 height_limit，则计算缩放到 height_refer 的比例
#==============================================================================
calculate_auto_scale() {
    local width=$1
    local height=$2

    local reference_dimension
    if [ $height -gt $width ]; then
        # 竖屏视频：宽度为较短边
        reference_dimension=$width
    else
        # 横屏或正方形：高度为较短边
        reference_dimension=$height
    fi

    if [ -n "$height_refer" ] && [ $reference_dimension -gt $height_limit ]; then
        # 返回比例值：高度参考值 / 原始参考维度
        echo "$height_refer $reference_dimension"
    else
        echo ""
    fi
}

#==============================================================================
# 核心函数：处理单个视频文件
# 参数：$1 - 输入文件路径，$2 - 输出目录，$3 - 时间范围（如 [00:10:00-00:20:00]），
#       $4 - 裁剪参数（如 (x,y,w,h)），$5 - 手动缩放比例（如 <1/2>），$6 - 日志文件路径
# 返回：0 成功，1 失败
#==============================================================================
encode_video() {
    local input_file="$1"
    local output_dir="$2"
    local time_range="${3:-}"
    local crop_params="${4:-}"
    local scale_ratio="${5:-}"
    local log_file="$6"

    # 提取文件名、基本名，生成输出路径（强制 .mp4 后缀）
    local filename=$(basename -- "$input_file")
    local basename="${filename%.*}"
    local output_file="${output_dir}/${basename}-encoded.mp4"

    echo -e "${GREEN}开始处理:${NC} $filename"
    echo -e "输出到: $output_file"

    # 确定实际编码模式（CUDA下2-pass会被降级）
    local actual_mode_name
    if [ $enc_cuda -eq 1 ] && [ $enc_2pass -eq 1 ]; then
        actual_mode_name="CQP（原2-pass已降级）"
    elif [ $enc_2pass -eq 1 ]; then
        actual_mode_name="2-pass"
    else
        actual_mode_name="CRF/CQP"
    fi
    echo -e "编码配置: $CODEC_NAME, 模式: $actual_mode_name"

    #---------------------------------------------------------------------
    # 1. 获取源文件信息
    #---------------------------------------------------------------------
    local video_info
    if ! video_info=$(get_video_info "$input_file"); then
        log_status "$filename" "ERROR" "无法获取视频信息" "$log_file"
        echo -e "${RED}错误: 无法获取视频信息${NC}"
        return 1
    fi

    read width height duration bitrate codec_name audio_codec <<< "$video_info"
    if [ $width -eq 0 ] || [ $height -eq 0 ]; then
        log_status "$filename" "ERROR" "无效的视频分辨率" "$log_file"
        echo -e "${RED}错误: 无法获取视频信息${NC}"
        return 1
    fi

    echo -e "分辨率: ${width}x${height}, 时长: ${duration}秒"
    echo -e "原始码率: ${bitrate}kbps"
    echo -e "视频编码: $codec_name, 音频编码: $audio_codec"

    # 获取帧率并判断是否需要降低
    local fps=$(get_video_fps "$input_file")
    echo -e "原始帧率: ${fps}fps"

    local need_reduce_fps=false
    local output_fps=$fps
    if [ -n "$fps_limit" ] && [ $fps -gt $fps_limit ]; then
        need_reduce_fps=true
        output_fps=$fps_limit
        echo -e "帧率限制: ${fps_limit}fps (需要从${fps}fps降低)"
    fi

    #---------------------------------------------------------------------
    # 2. 解析时间范围（用于剪切）
    #---------------------------------------------------------------------
    local start_time=""
    local end_time=""
    if [ -n "$time_range" ]; then
        # 去掉外层方括号，分割开始和结束时间
        local time_range_clean=${time_range:1:-1}
        if [[ "$time_range_clean" == *-* ]]; then
            start_time="${time_range_clean%-*}"
            end_time="${time_range_clean#*-}"
        fi
    fi

    #---------------------------------------------------------------------
    # 3. 处理裁剪参数（crop）
    #---------------------------------------------------------------------
    local actual_width=$width
    local actual_height=$height
    local filter_complex=""

    if [ -n "$crop_params" ]; then
        local crop_clean=${crop_params:1:-1}
        IFS=',' read -r crop_x crop_y crop_w crop_h <<< "$crop_clean"
        actual_width=$crop_w
        actual_height=$crop_h
        filter_complex="crop=$crop_w:$crop_h:$crop_x:$crop_y"
        echo -e "裁剪后分辨率: ${actual_width}x${actual_height}"
    fi

    #---------------------------------------------------------------------
    # 4. 处理缩放参数（手动指定 或 自动缩放）
    #---------------------------------------------------------------------
    local scaled_width=$actual_width
    local scaled_height=$actual_height
    local need_scale=false
    local scale_num=1
    local scale_den=1
    local auto_scale_applied=false

    if [ -n "$scale_ratio" ]; then
        # 手动缩放比例（来自配置文件）
        local scale_clean=${scale_ratio:1:-1}
        if [[ "$scale_clean" =~ ^([0-9]+)/([0-9]+)$ ]]; then
            scale_num=${BASH_REMATCH[1]}
            scale_den=${BASH_REMATCH[2]}
            if [ "$scale_den" -eq 0 ]; then
                echo -e "${RED}错误: 缩放分母不能为0${NC}"
                return 1
            fi
            if [ $scale_num -ne 1 ] || [ $scale_den -ne 1 ]; then
                need_scale=true
                scaled_width=$((actual_width * scale_num / scale_den))
                scaled_height=$((actual_height * scale_num / scale_den))
                # 确保宽度和高度为偶数（视频编码普遍要求）
                [ $((scaled_width % 2)) -eq 1 ] && scaled_width=$((scaled_width - 1))
                [ $((scaled_height % 2)) -eq 1 ] && scaled_height=$((scaled_height - 1))
                # 追加到滤镜链
                if [ -n "$filter_complex" ]; then
                    filter_complex="$filter_complex,scale=${scaled_width}:${scaled_height}"
                else
                    filter_complex="scale=${scaled_width}:${scaled_height}"
                fi
                echo -e "手动缩放比例: ${scale_num}/${scale_den}"
                echo -e "缩放后分辨率: ${scaled_width}x${scaled_height}"
            fi
        fi
    elif [ -z "$time_range" ] && [ -z "$crop_params" ]; then
        # 文件夹模式且无手动缩放、无裁剪：尝试自动缩放
        local auto_scale_result=$(calculate_auto_scale $actual_width $actual_height)
        if [ -n "$auto_scale_result" ]; then
            read scale_num scale_den <<< "$auto_scale_result"
            need_scale=true
            auto_scale_applied=true

            # 根据视频方向计算缩放后的实际尺寸（保持宽高比）
            if [ $actual_height -gt $actual_width ]; then
                # 竖屏：将宽度缩放到 height_refer
                scaled_width=$height_refer
                scaled_height=$((actual_height * height_refer / actual_width))
            else
                # 横屏：将高度缩放到 height_refer
                scaled_height=$height_refer
                scaled_width=$((actual_width * height_refer / actual_height))
            fi

            # 确保偶数
            [ $((scaled_width % 2)) -eq 1 ] && scaled_width=$((scaled_width - 1))
            [ $((scaled_height % 2)) -eq 1 ] && scaled_height=$((scaled_height - 1))

            if [ -n "$filter_complex" ]; then
                filter_complex="$filter_complex,scale=${scaled_width}:${scaled_height}"
            else
                filter_complex="scale=${scaled_width}:${scaled_height}"
            fi

            echo -e "自动缩放: 较短边 > ${height_limit}px，缩放到 ${height_refer}px"
            echo -e "缩放后分辨率: ${scaled_width}x${scaled_height}"
        fi
    fi

    #---------------------------------------------------------------------
    # 5. 应用帧率限制（添加fps滤镜）
    #---------------------------------------------------------------------
    if [ "$need_reduce_fps" = true ]; then
        if [ -n "$filter_complex" ]; then
            filter_complex="$filter_complex,fps=$output_fps"
        else
            filter_complex="fps=$output_fps"
        fi
        echo -e "帧率限制: 从${fps}fps降低到${output_fps}fps"
    fi

    #---------------------------------------------------------------------
    # 6. 计算目标码率（基于最终缩放后的分辨率）
    #---------------------------------------------------------------------
    local target_bitrate=$(calculate_bitrate $scaled_width $scaled_height)
    echo -e "目标码率: ${target_bitrate}kbps"

    #---------------------------------------------------------------------
    # 7. 是否需要重新编码判断
    #    满足以下任一条件时必须编码：
    #    a) 需要缩放/裁剪/帧率降低
    #    b) 原始码率 > 目标码率 × 1.2
    #    否则直接复制流
    #---------------------------------------------------------------------
    local need_encode=true
    if [ "$need_scale" = true ] || [ -n "$crop_params" ] || [ "$need_reduce_fps" = true ]; then
        need_encode=true
        [ "$need_scale" = true ] && echo -e "${YELLOW}需要缩放，重新编码${NC}"
        [ -n "$crop_params" ] && echo -e "${YELLOW}需要裁剪，重新编码${NC}"
        [ "$need_reduce_fps" = true ] && echo -e "${YELLOW}需要降低帧率，重新编码${NC}"
    elif [ $bitrate -gt 0 ]; then
        local threshold_bitrate=$(echo "$target_bitrate * 1.2" | bc 2>/dev/null | cut -d. -f1)
        [ -z "$threshold_bitrate" ] && threshold_bitrate=$((target_bitrate + target_bitrate / 5))
        if [ $bitrate -gt $threshold_bitrate ]; then
            need_encode=true
            echo -e "${YELLOW}重新编码: 原始码率(${bitrate}kbps) > 目标码率(${target_bitrate}kbps) × 1.2${NC}"
        else
            need_encode=false
            echo -e "${BLUE}跳过编码: 原始码率(${bitrate}kbps) ≤ 目标码率(${target_bitrate}kbps) × 1.2${NC}"
        fi
    else
        echo -e "${YELLOW}无法获取原始码率，重新编码${NC}"
        need_encode=true
    fi

    # 如果无需编码，直接复制/剪切
    if [ "$need_encode" = false ]; then
        if copy_or_cut_video "$input_file" "$output_file" "$start_time" "$end_time"; then
            log_status "$filename" "SUCCESS" "直接复制完成" "$log_file"
            echo -e "${GREEN}处理完成${NC}"
            return 0
        else
            log_status "$filename" "ERROR" "直接复制失败" "$log_file"
            echo -e "${RED}处理失败${NC}"
            return 1
        fi
    fi

    #---------------------------------------------------------------------
    # 8. 构建编码命令基础部分
    #---------------------------------------------------------------------
    # 优化：-ss 放在 -i 之前以实现快速 seek（注意：若时间范围精确要求，-ss 在 -i 之后更精确）
    # 这里使用快速 seek 方式，适用于绝大多数场景
    local ffmpeg_cmd="ffmpeg"
    if [ -n "$start_time" ] && [ "$start_time" != "0" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -ss $start_time"
    fi
    ffmpeg_cmd="$ffmpeg_cmd -i \"$input_file\""
    if [ -n "$end_time" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -to $end_time"
    fi

    # 滤镜和映射：若存在滤镜链，使用 -filter_complex 并映射输出标签 [v]
    if [ -n "$filter_complex" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -filter_complex \"$filter_complex[v]\" -map \"[v]\""
    else
        # 无滤镜时直接映射第一个视频流
        ffmpeg_cmd="$ffmpeg_cmd -map 0:v:0"
    fi

    #---------------------------------------------------------------------
    # 9. 根据编码模式选择执行函数（CUDA下强制使用CRF/CQP）
    #---------------------------------------------------------------------
    local actual_2pass=$enc_2pass
    if [ $enc_cuda -eq 1 ] && [ $enc_2pass -eq 1 ]; then
        echo -e "${YELLOW}警告: CUDA不支持2-pass，将采用CQP恒定质量模式${NC}"
        actual_2pass=0
    fi

    local encode_result=0
    if [ $actual_2pass -eq 1 ]; then
        if encode_2pass "$ffmpeg_cmd" "$target_bitrate" "$output_file" "$output_fps"; then
            encode_result=0
        else
            encode_result=1
        fi
    else
        if encode_crf "$ffmpeg_cmd" "$target_bitrate" "$output_file" "$output_fps"; then
            encode_result=0
        else
            encode_result=1
        fi
    fi

    #---------------------------------------------------------------------
    # 10. 记录结果
    #---------------------------------------------------------------------
    if [ $encode_result -eq 0 ]; then
        log_status "$filename" "SUCCESS" "编码完成" "$log_file"
        echo -e "${GREEN}编码完成:${NC} $filename"
    else
        log_status "$filename" "ERROR" "编码过程失败" "$log_file"
        echo -e "${RED}编码失败:${NC} $filename"
    fi

    echo ""
    return $encode_result
}

#==============================================================================
# 主函数：程序入口
#==============================================================================
main() {
    # 显示当前配置
    echo -e "${GREEN}=== 视频转码脚本 ===${NC}"
    echo -e "视频编码: $CODEC_NAME"
    if [ $enc_cuda -eq 1 ]; then
        echo -e "硬件加速: CUDA (NVENC)"
    fi
    echo -e "编码模式: $([ $enc_2pass -eq 1 ] && [ $enc_cuda -eq 0 ] && echo "2-pass" || echo "CRF/CQP")"
    echo -e "音频编码: $AUDIO_CODEC ${AUDIO_BITRATE}"
    if [ -n "$height_refer" ]; then
        echo -e "高度参考值: ${height_refer}px (限制: ${height_limit}px)"
    fi
    if [ -n "$fps_limit" ]; then
        echo -e "帧率限制: ${fps_limit}fps"
    fi
    echo ""

    # 参数检查：必须提供两个参数
    if [ $# -ne 2 ]; then
        show_help
    fi

    local input="$1"
    local output_dir="$2"

    # 若输出目录不存在则创建
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        echo -e "创建输出目录: $output_dir"
    fi

    # 创建日志文件（带时间戳，存储在输出目录中）
    local log_file="${output_dir}/encode_$(date '+%Y%m%d_%H%M%S').log"
    echo -e "${PURPLE}日志文件: $log_file${NC}"
    echo "转码任务开始: $(date '+%Y-%m-%d %H:%M:%S')" > "$log_file"
    echo "输入: $input" >> "$log_file"
    echo "输出目录: $output_dir" >> "$log_file"
    echo "配置: $CODEC_NAME, 模式: $([ $enc_2pass -eq 1 ] && [ $enc_cuda -eq 0 ] && echo "2-pass" || echo "CRF/CQP")" >> "$log_file"
    if [ -n "$height_refer" ]; then
        echo "高度参考值: ${height_refer}px (限制: ${height_limit}px)" >> "$log_file"
    fi
    if [ -n "$fps_limit" ]; then
        echo "帧率限制: ${fps_limit}fps" >> "$log_file"
    fi
    echo "" >> "$log_file"

    #---------------------------------------------------------------------
    # 检查必要的依赖工具
    #---------------------------------------------------------------------
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}错误: ffmpeg未安装${NC}"
        log_status "SYSTEM" "ERROR" "ffmpeg未安装" "$log_file"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}错误: jq未安装，请先安装jq${NC}"
        log_status "SYSTEM" "ERROR" "jq未安装" "$log_file"
        echo "Ubuntu/Debian: sudo apt-get install jq"
        echo "CentOS/RHEL: sudo yum install jq"
        echo "macOS: brew install jq"
        exit 1
    fi
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}错误: bc未安装，请先安装bc${NC}"
        log_status "SYSTEM" "ERROR" "bc未安装" "$log_file"
        echo "Ubuntu/Debian: sudo apt-get install bc"
        echo "CentOS/RHEL: sudo yum install bc"
        echo "macOS: brew install bc"
        exit 1
    fi

    #---------------------------------------------------------------------
    # 构建待处理文件列表
    # - 若输入是目录：搜索所有支持的视频文件
    # - 若输入是文件：视为配置文件，逐行解析
    #---------------------------------------------------------------------
    local file_list=()
    local parse_line=n   # n=直接处理文件路径；y=按配置文件解析行
    if [ -d "$input" ]; then
        echo -e "${GREEN}处理目录:${NC} $input"

        # 常见视频扩展名列表（不区分大小写）
        local video_extensions=("mp4" "avi" "mkv" "mov" "wmv" "flv" "webm" "m4v" "mpg" "mpeg" "ts" "3gp" "f4v" "rmvb" "rm" "asf" "vob" "dat" "mts" "m2ts")

        # 使用临时文件存储找到的文件路径（以空字符分隔，避免路径中的空格问题）
        tmpfile=$(mktemp)
        for ext in "${video_extensions[@]}"; do
            find "$input" -type f \( -iname "*.${ext}" \) -print0 2>/dev/null >> "$tmpfile"
        done

        # 读取临时文件到数组
        while IFS= read -r -d '' file; do
            file_list+=("$file")
        done < "$tmpfile"
        rm -f "$tmpfile"

    elif [ -f "$input" ]; then
        echo -e "${GREEN}处理配置文件:${NC} $input"
        parse_line=y

        local line_number=0
        while IFS= read -r line || [ -n "$line" ]; do
            line_number=$((line_number + 1))

            # 去除首尾空白
            local line_trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            # 跳过空行和注释行（以#开头）
            if [[ -z "$line_trimmed" || "$line_trimmed" =~ ^# ]]; then
                continue
            fi

            # 解析行格式：文件名 [时间] (裁剪) <缩放>
            if [[ "$line_trimmed" =~ ^([^[\(<]+)(\[.*\])?[[:space:]]*(\(.*\))?[[:space:]]*(<.*>)?$ ]]; then
                local fname=$(echo "${BASH_REMATCH[1]}" | xargs)  # 去掉多余空格
                if [ ! -f "$fname" ]; then
                    echo -e "${RED}错误 (第${line_number}行): 文件不存在 - $fname${NC}"
                    log_status "$fname" "ERROR" "第${line_number}行: 文件不存在" "$log_file"
                    continue
                fi
                file_list+=("$line_trimmed")
            else
                echo -e "${RED}错误 (第${line_number}行): 格式不正确${NC}"
                log_status "LINE $line_number" "ERROR" "格式不正确: $line_trimmed" "$log_file"
            fi
        done < "$input"
    else
        echo -e "${RED}错误: 输入不存在${NC}"
        show_help
    fi

    #---------------------------------------------------------------------
    # 依次处理每个文件
    #---------------------------------------------------------------------
    local total=${#file_list[@]}
    local count=0
    local success_count=0
    local error_count=0
    echo -e "需要处理 $total 个视频文件"

    for file in "${file_list[@]}"; do
        count=$((count + 1))
        echo -e "${CYAN}==================== $count/$total ====================${NC}"

        if [ $parse_line = n ]; then
            # 目录模式：直接传递文件路径
            if [ ! -f "$file" ]; then
                echo -e "${RED}错误: 文件不存在 - $file${NC}"
                log_status "$file" "ERROR" "文件不存在" "$log_file"
                error_count=$((error_count + 1))
                continue
            fi
            echo -e "${YELLOW}文件: $file${NC}"

            # 临时关闭 set -e，允许单个文件失败后继续处理下一个
            set +e
            encode_video "$file" "$output_dir" "" "" "" "$log_file"
            local result=$?
            set -e
        else
            # 配置文件模式：再次解析行内容，提取各个参数
            if [[ "$file" =~ ^([^[\(<]+)(\[.*\])?[[:space:]]*(\(.*\))?[[:space:]]*(<.*>)?$ ]]; then
                local fname=$(echo "${BASH_REMATCH[1]}" | xargs)
                local time_range="${BASH_REMATCH[2]}"
                local crop_params="${BASH_REMATCH[3]}"
                local scale_ratio="${BASH_REMATCH[4]}"

                if [ ! -f "$fname" ]; then
                    echo -e "${RED}错误: 文件不存在 - $fname${NC}"
                    log_status "$fname" "ERROR" "文件不存在" "$log_file"
                    error_count=$((error_count + 1))
                    continue
                fi

                echo -e "${YELLOW}文件: $fname${NC}"
                [ -n "$time_range" ] && echo -e "${YELLOW}时间范围: $time_range${NC}"
                [ -n "$crop_params" ] && echo -e "${YELLOW}裁剪参数: $crop_params${NC}"
                [ -n "$scale_ratio" ] && echo -e "${YELLOW}缩放比例: $scale_ratio${NC}"

                set +e
                encode_video "$fname" "$output_dir" "$time_range" "$crop_params" "$scale_ratio" "$log_file"
                local result=$?
                set -e
            else
                # 安全兜底：正常情况下不会执行到这里
                echo -e "${RED}错误: 无法解析行 - $file${NC}"
                log_status "LINE" "ERROR" "无法解析: $file" "$log_file"
                error_count=$((error_count + 1))
                continue
            fi
        fi

        # 统计结果（使用安全的自增写法）
        case $result in
            0) success_count=$((success_count + 1)) ;;
            *) error_count=$((error_count + 1)) ;;
        esac

        # 文件之间增加空行提高可读性
        if [ $count -lt $total ]; then
            echo ""
        fi
    done

    #---------------------------------------------------------------------
    # 输出最终统计信息
    #---------------------------------------------------------------------
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}任务完成统计:${NC}"
    echo -e "总共处理: $total 个文件"
    echo -e "${GREEN}成功:${NC} $success_count"
    echo -e "${RED}失败:${NC} $error_count"
    echo -e "${PURPLE}日志文件:${NC} $log_file"

    # 同时写入日志文件
    echo "" >> "$log_file"
    echo "任务完成统计:" >> "$log_file"
    echo "总共处理: $total 个文件" >> "$log_file"
    echo "成功: $success_count" >> "$log_file"
    echo "失败: $error_count" >> "$log_file"
    echo "转码任务结束: $(date '+%Y-%m-%d %H:%M:%S')" >> "$log_file"

    echo -e "${GREEN}所有任务完成！${NC}"
}

# 脚本入口
main "$@"
