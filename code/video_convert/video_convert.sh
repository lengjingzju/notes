#!/bin/bash

# 编码配置选项
enc_hevc=1          # 0=H.264, 1=HEVC
enc_2pass=1         # 0=CRF模式,恒定质量；1=2-pass模式，恒定码率

# 高度参考值配置（仅用于文件夹处理模式）
# height_refer为空时不限制；不为空时宽或高的较小者大于height_limit时限制到height_refer
height_refer=1080   # 参考高度
height_limit=1100   # 高度限制

# 帧率限制配置
fps_limit=30        # 帧率限制：为空时不限制；不为空时帧率限制到设定值

# 编码脚本：批量视频转码
# 用法：
#   ./encode.sh <输入目录> <输出目录>    # 处理目录下所有视频文件
#   ./encode.sh <输入文件> <输出目录>    # 按配置文件处理

# 设置错误时退出（修改为在特定位置退出）
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 根据配置设置编码参数
if [ $enc_hevc -eq 1 ]; then
    VIDEO_CODEC="libx265"
    CODEC_NAME="HEVC (H.265)"
    # HEVC的CRF值范围：0-51，默认23
    CRF_VALUE="23"
else
    VIDEO_CODEC="libx264"
    CODEC_NAME="H.264"
    # H.264的CRF值范围：0-51，默认23
    CRF_VALUE="23"
fi

AUDIO_CODEC="aac"
AUDIO_BITRATE="64k"

# 显示帮助信息
show_help() {
    echo "视频批量转码脚本"
    echo "当前配置: $CODEC_NAME, 编码模式: $([ $enc_2pass -eq 1 ] && echo "2-pass" || echo "CRF")"
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
    exit 1
}

# 获取视频容器格式
get_container_format() {
    local input_file="$1"
    local format=$(ffprobe -v quiet -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null)
    echo "$format" | tr '[:upper:]' '[:lower:]'
}

# 获取视频信息
get_video_info() {
    local input_file="$1"
    local info_json=$(ffprobe -v quiet -print_format json -show_format -show_streams "$input_file")

    # 获取视频流
    local video_stream=$(echo "$info_json" | jq -r '.streams[] | select(.codec_type=="video")')

    # 获取宽度和高度
    local width=$(echo "$video_stream" | jq -r '.width')
    local height=$(echo "$video_stream" | jq -r '.height')
    local duration=$(echo "$info_json" | jq -r '.format.duration')

    # 获取原始码率（如果存在）
    local bitrate=$(echo "$info_json" | jq -r '.format.bit_rate')
    if [ "$bitrate" = "null" ] || [ -z "$bitrate" ]; then
        bitrate=0
    else
        bitrate=$((bitrate / 1000)) # 转换为kbps
    fi

    # 获取视频编码格式
    local codec_name=$(echo "$video_stream" | jq -r '.codec_name')

    # 获取音频编码格式
    local audio_stream=$(echo "$info_json" | jq -r '.streams[] | select(.codec_type=="audio")')
    local audio_codec=""
    if [ -n "$audio_stream" ] && [ "$audio_stream" != "null" ]; then
        audio_codec=$(echo "$audio_stream" | jq -r '.codec_name')
    fi

    echo "$width $height $duration $bitrate $codec_name $audio_codec"
}

# 获取视频帧率
get_video_fps() {
    local input_file="$1"

    # 获取帧率信息
    local fps_info
    fps_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null | head -1)

    if [ -z "$fps_info" ] || [ "$fps_info" = "N/A" ]; then
        echo "25"  # 默认帧率
        return
    fi

    # 如果帧率是分数形式（如30000/1001），计算小数
    if [[ "$fps_info" =~ ^([0-9]+)/([0-9]+)$ ]]; then
        local numerator=${BASH_REMATCH[1]}
        local denominator=${BASH_REMATCH[2]}
        if [ "$denominator" -ne 0 ]; then
            local fps=$(echo "scale=2; $numerator / $denominator" | bc 2>/dev/null || echo "25")
            # 四舍五入到整数
            echo $(printf "%.0f" "$fps")
            return
        fi
    fi

    # 如果是整数或小数，直接输出整数部分
    echo $(printf "%.0f" "$fps_info")
}

# 根据分辨率计算推荐码率（使用更精细的层次）
calculate_bitrate() {
    local width=$1
    local height=$2

    # 如果使用CRF模式，返回0（表示不使用码率控制）
    #if [ $enc_2pass -eq 0 ]; then
    #    echo "0"
    #    return
    #fi

    # 计算像素数
    local pixels=$((width * height))

    # 四舍五入到最近的100的倍数
    round100() {
        local value=$1
        echo $(( ((value + 50) / 100) * 100 ))
    }

    # 根据像素数确定H.264码率，以1280x720的分辨率使用1300kbps作为基准
    local h264_bitrate
    if [ $pixels -le 1000000 ]; then
        h264_bitrate=$(( pixels * 13 / 9216 ))
    else
        h264_bitrate=$(( pixels * 12 / 9216 ))
    fi

    # 根据编码类型输出码率
    if [ $enc_hevc -eq 1 ]; then
        # HEVC码率 = H.264码率 × 0.8，然后四舍五入到100的倍数
        local hevc_rate=$(( h264_bitrate * 8 / 10 ))
        echo $(round100 $hevc_rate)
    else
        # H.264码率已经是100的倍数
        echo $(round100 $h264_bitrate)
    fi
}

calculate_gop_size() {
    local fps=$1

    # 计算GOP大小（2秒的帧数）
    local gop_size=$((fps * 2))
    # 限制GOP在合理范围内
    if [ $gop_size -lt 24 ]; then
        gop_size=24
    elif [ $gop_size -gt 250 ]; then
        gop_size=250
    fi
    echo "$gop_size"
}

get_gop_params() {
    local gop_size=$1
    # no-scenecut=1(HEVC)/sc_threshold=0(H.264)是禁用场景检测(场景切换处插入了额外的关键帧)
    local gop_params=""
    if [ $enc_hevc -eq 1 ]; then
        gop_params="-g $gop_size -x265-params keyint=${gop_size}:min-keyint=${gop_size}:no-scenecut=1"
    else
        gop_params="-g $gop_size -keyint_min $gop_size -sc_threshold 0"
    fi

    echo "$gop_params"
}

# 记录处理状态到日志文件
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

# 直接复制或剪切视频（不重新编码）
copy_or_cut_video() {
    local input_file="$1"
    local output_file="$2"
    local start_time="$3"
    local end_time="$4"

    echo -e "${BLUE}跳过编码，直接复制/剪切...${NC}"

    # 获取输入文件容器格式
    local container_format=$(get_container_format "$input_file")

    # 构建ffmpeg命令
    local ffmpeg_cmd="ffmpeg -i \"$input_file\""

    # 添加时间范围参数
    if [ -n "$start_time" ] && [ "$start_time" != "0" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -ss $start_time"
    fi

    if [ -n "$end_time" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -to $end_time"
    fi

    # 复制流，强制输出为MP4格式
    ffmpeg_cmd="$ffmpeg_cmd -c:v copy -c:a copy -map 0 -movflags +faststart -y \"$output_file\""

    # 执行命令
    echo -e "执行: $ffmpeg_cmd"
    if eval $ffmpeg_cmd 2>&1 | tee /tmp/ffmpeg_output.log | grep -E "frame|fps|size|time|bitrate|speed"; then
        echo -e "${GREEN}复制/剪切完成${NC}"
        return 0
    else
        # 检查错误信息
        local error_msg=$(grep -i "error\|failed\|invalid" /tmp/ffmpeg_output.log | head -1)
        echo -e "${RED}复制/剪切失败: ${error_msg:-未知错误}${NC}"
        return 1
    fi
}

# 使用CRF模式编码
encode_crf() {
    local ffmpeg_cmd="$1"
    local target_bitrate="$2"
    local output_file="$3"
    local fps="$4"

    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始CRF编码...${NC}"

    # 计算GOP大小和获取GOP编码参数
    local gop_size=$(calculate_gop_size $fps)
    local gop_params=$(get_gop_params $gop_size)

    echo -e "CRF参数: CRF=$CRF_VALUE, 最大码率=${target_bitrate}k, GOP=${gop_size}帧 (FPS: ${fps})"

    # 添加视频编码参数
    ffmpeg_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -crf $CRF_VALUE -maxrate ${target_bitrate}k -bufsize $((target_bitrate * 2))k"

    # 音频编码参数
    ffmpeg_cmd="$ffmpeg_cmd -c:a $AUDIO_CODEC -b:a $AUDIO_BITRATE -map 0:a?"

    # 输出参数，强制输出为MP4格式
    if [ $enc_hevc -eq 1 ]; then
        # HEVC需要添加hvc1标签以确保兼容性
        ffmpeg_cmd="$ffmpeg_cmd -movflags +faststart -tag:v hvc1 -y \"$output_file\""
    else
        ffmpeg_cmd="$ffmpeg_cmd -movflags +faststart -y \"$output_file\""
    fi

    # 执行编码
    if eval $ffmpeg_cmd 2>&1 | tee /tmp/ffmpeg_output.log | grep -E "frame|fps|size|time|bitrate|speed"; then
        echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') 编码成功${NC}"
        return 0
    else
        # 检查错误信息
        local error_msg=$(grep -i "error\|failed\|invalid" /tmp/ffmpeg_output.log | head -1)
        echo -e "${RED}编码失败: ${error_msg:-未知错误}${NC}"
        return 1
    fi
}

# 使用2-pass模式编码
encode_2pass() {
    local ffmpeg_cmd="$1"
    local target_bitrate="$2"
    local output_file="$3"
    local fps="$4"

    # 计算GOP大小和获取GOP编码参数
    local gop_size=$(calculate_gop_size $fps)
    local gop_params=$(get_gop_params $gop_size)

    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始2-pass编码...${NC}"
    echo -e "编码参数: 目标码率=${target_bitrate}k, GOP=${gop_size}帧 (FPS: ${fps})"

    # 使用脚本进程的PID作为唯一标识符，用于隔离临时文件
    local UNIQUE_ID="$$"
    local PASSLOG_PREFIX="ffmpeg2pass-${UNIQUE_ID}"
    local DEBUGLOG_PREFIX="/tmp/ffmpeg_output_${UNIQUE_ID}"

    # 第一次编码参数（生成日志）
    local pass1_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -b:v ${target_bitrate}k -pass 1 -passlogfile ${PASSLOG_PREFIX} -an -f mp4 -y /dev/null"

    # 第二次编码参数（加上音频）
    local pass2_cmd="$ffmpeg_cmd -c:v $VIDEO_CODEC $gop_params -b:v ${target_bitrate}k -pass 2 -passlogfile ${PASSLOG_PREFIX} -c:a $AUDIO_CODEC -b:a $AUDIO_BITRATE -map 0:a?"

    # 输出参数，强制输出为MP4格式
    if [ $enc_hevc -eq 1 ]; then
        # HEVC需要添加hvc1标签以确保兼容性
        pass2_cmd="$pass2_cmd -movflags +faststart -tag:v hvc1 -y \"$output_file\""
    else
        pass2_cmd="$pass2_cmd -movflags +faststart -y \"$output_file\""
    fi

    # 执行2-pass编码
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始第一次编码...${NC}"
    if ! eval $pass1_cmd 2>&1 | tee "${DEBUGLOG_PREFIX}-1.log" | grep -E "frame|fps|size|time|bitrate|speed"; then
        local error_msg=$(grep -i "error\|failed\|invalid" "${DEBUGLOG_PREFIX}-1.log" | head -1)
        echo -e "${RED}第一次编码失败: ${error_msg:-未知错误}${NC}"
        rm -f ${PASSLOG_PREFIX}-*.log 2>/dev/null
        rm -f ${PASSLOG_PREFIX}-*.log.mbtree 2>/dev/null
        rm -f ${DEBUGLOG_PREFIX}-*.log 2>/dev/null
        return 1
    fi

    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') 开始第二次编码...${NC}"
    if eval $pass2_cmd 2>&1 | tee "${DEBUGLOG_PREFIX}-2.log" | grep -E "frame|fps|size|time|bitrate|speed"; then
        echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') 编码成功${NC}"
        rm -f ${PASSLOG_PREFIX}-*.log 2>/dev/null
        rm -f ${PASSLOG_PREFIX}-*.log.mbtree 2>/dev/null
        rm -f ${DEBUGLOG_PREFIX}-*.log 2>/dev/null
        return 0
    else
        # 检查错误信息
        local error_msg=$(grep -i "error\|failed\|invalid" "${DEBUGLOG_PREFIX}-2.log" | head -1)
        echo -e "${RED}第二次编码失败: ${error_msg:-未知错误}${NC}"
        rm -f ${PASSLOG_PREFIX}-*.log 2>/dev/null
        rm -f ${PASSLOG_PREFIX}-*.log.mbtree 2>/dev/null
        rm -f ${DEBUGLOG_PREFIX}-*.log 2>/dev/null
        return 1
    fi
}

# 计算自动缩放比例
calculate_auto_scale() {
    local width=$1
    local height=$2

    # 确定哪个是较短边
    local reference_dimension
    if [ $height -gt $width ]; then
        # 如果是竖屏视频，高度大于宽度，取宽度作为参考
        reference_dimension=$width
    else
        # 如果是横屏视频或正方形，取高度作为参考
        reference_dimension=$height
    fi

    # 如果设置了height_refer且参考维度大于height_limit，则计算缩放比例
    if [ -n "$height_refer" ] && [ $reference_dimension -gt $height_limit ]; then
        # 计算缩放比例：目标高度 / 参考维度
        local scale_num=$height_refer
        local scale_den=$reference_dimension

        # 简化比例（可选）
        # 这里我们保持原始比例，不进行简化

        echo "$scale_num $scale_den"
    else
        # 不需要缩放
        echo ""
    fi
}

# 处理单个视频文件
encode_video() {
    local input_file="$1"
    local output_dir="$2"
    local time_range="${3:-}"
    local crop_params="${4:-}"
    local scale_ratio="${5:-}"  # 缩放比例参数
    local log_file="$6"

    # 获取文件名（不含路径和扩展名）
    local filename=$(basename -- "$input_file")
    local extension="${filename##*.}"
    local basename="${filename%.*}"

    # 输出文件路径（强制使用.mp4扩展名）
    local output_file="${output_dir}/${basename}-encoded.mp4"

    echo -e "${GREEN}开始处理:${NC} $filename"
    echo -e "输出到: $output_file"
    echo -e "编码配置: $CODEC_NAME, 模式: $([ $enc_2pass -eq 1 ] && echo "2-pass" || echo "CRF")"

    # 获取视频信息
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

    # 获取视频帧率
    local fps=$(get_video_fps "$input_file")
    echo -e "原始帧率: ${fps}fps"

    # 检查是否需要降低帧率
    local need_reduce_fps=false
    local output_fps=$fps
    if [ -n "$fps_limit" ] && [ $fps -gt $fps_limit ]; then
        need_reduce_fps=true
        output_fps=$fps_limit
        echo -e "帧率限制: ${fps_limit}fps (需要从${fps}fps降低)"
    fi

    # 解析时间范围
    local start_time=""
    local end_time=""
    if [ -n "$time_range" ]; then
        # 解析时间范围 [start-end]
        local time_range_clean=${time_range:1:-1}  # 去掉方括号
        if [[ "$time_range_clean" == *-* ]]; then
            start_time="${time_range_clean%-*}"
            end_time="${time_range_clean#*-}"
        fi
    fi

    # 确定实际使用的分辨率（考虑crop）
    local actual_width=$width
    local actual_height=$height
    local filter_complex=""

    if [ -n "$crop_params" ]; then
        # 解析裁剪参数 (x,y,w,h)
        local crop_clean=${crop_params:1:-1}  # 去掉圆括号
        IFS=',' read -r crop_x crop_y crop_w crop_h <<< "$crop_clean"
        actual_width=$crop_w
        actual_height=$crop_h
        filter_complex="crop=$crop_w:$crop_h:$crop_x:$crop_y"
        echo -e "裁剪后分辨率: ${actual_width}x${actual_height}"
    fi

    # 应用缩放
    local scaled_width=$actual_width
    local scaled_height=$actual_height
    local need_scale=false
    local scale_num=1
    local scale_den=1
    local auto_scale_applied=false

    # 首先检查是否有手动指定的缩放比例
    if [ -n "$scale_ratio" ]; then
        # 解析缩放比例
        local scale_clean=${scale_ratio:1:-1}  # 去掉尖括号
        if [[ "$scale_clean" =~ ^([0-9]+)/([0-9]+)$ ]]; then
            scale_num=${BASH_REMATCH[1]}
            scale_den=${BASH_REMATCH[2]}

            if [ "$scale_den" -eq 0 ]; then
                echo -e "${RED}错误: 缩放分母不能为0${NC}"
                return 1
            fi

            if [ $scale_num -ne 1 ] || [ $scale_den -ne 1 ]; then
                need_scale=true
                # 计算缩放后的分辨率
                scaled_width=$((actual_width * scale_num / scale_den))
                scaled_height=$((actual_height * scale_num / scale_den))

                # 确保分辨率是偶数（视频编码要求）
                if [ $((scaled_width % 2)) -eq 1 ]; then
                    scaled_width=$((scaled_width - 1))
                fi
                if [ $((scaled_height % 2)) -eq 1 ]; then
                    scaled_height=$((scaled_height - 1))
                fi

                # 添加到滤镜链
                if [ -n "$filter_complex" ]; then
                    filter_complex="$filter_complex,scale=${scaled_width}:${scaled_height}"
                else
                    filter_complex="scale=${scaled_width}:${scaled_height}"
                fi

                echo -e "手动缩放比例: ${scale_num}/${scale_den}"
                echo -e "缩放后分辨率: ${scaled_width}x${scaled_height}"
            fi
        elif [[ "$scale_clean" =~ ^([0-9]+)$ ]]; then
            # 如果只给了一个数字，比如 <1>，表示不缩放
            scale_num=${BASH_REMATCH[1]}
            scale_den=1
            if [ $scale_num -ne 1 ]; then
                echo -e "${YELLOW}警告: 缩放比例格式应为 <分子/分母>，如 <1/2>。已忽略缩放。${NC}"
            fi
        else
            echo -e "${YELLOW}警告: 缩放比例格式无效，应为 <分子/分母>，如 <1/2>。已忽略缩放。${NC}"
        fi
    # 如果没有手动指定缩放比例，检查是否需要自动缩放（仅适用于文件夹模式）
    elif [ -z "$time_range" ] && [ -z "$crop_params" ]; then
        # 计算是否需要自动缩放
        local auto_scale_result=$(calculate_auto_scale $actual_width $actual_height)
        if [ -n "$auto_scale_result" ]; then
            read scale_num scale_den <<< "$auto_scale_result"
            need_scale=true
            auto_scale_applied=true

            # 确定参考维度
            local reference_dimension
            if [ $actual_height -gt $actual_width ]; then
                reference_dimension=$actual_width
            else
                reference_dimension=$actual_height
            fi

            # 计算缩放后的分辨率（保持宽高比）
            # 注意：这里我们需要根据实际是竖屏还是横屏来计算
            if [ $actual_height -gt $actual_width ]; then
                # 竖屏视频：高度大于宽度
                # 将宽度缩放到height_refer，高度按比例缩放
                scaled_width=$height_refer
                scaled_height=$((actual_height * height_refer / actual_width))
            else
                # 横屏视频或正方形：宽度大于等于高度
                # 将高度缩放到height_refer，宽度按比例缩放
                scaled_height=$height_refer
                scaled_width=$((actual_width * height_refer / actual_height))
            fi

            # 确保分辨率是偶数（视频编码要求）
            if [ $((scaled_width % 2)) -eq 1 ]; then
                scaled_width=$((scaled_width - 1))
            fi
            if [ $((scaled_height % 2)) -eq 1 ]; then
                scaled_height=$((scaled_height - 1))
            fi

            # 添加到滤镜链
            if [ -n "$filter_complex" ]; then
                filter_complex="$filter_complex,scale=${scaled_width}:${scaled_height}"
            else
                filter_complex="scale=${scaled_width}:${scaled_height}"
            fi

            echo -e "自动缩放: 参考维度 ${reference_dimension}px > ${height_limit}px，缩放到 ${height_refer}px"
            echo -e "缩放比例: ${scale_num}/${scale_den}"
            echo -e "缩放后分辨率: ${scaled_width}x${scaled_height}"
        fi
    fi

    # 应用帧率限制
    if [ "$need_reduce_fps" = true ]; then
        if [ -n "$filter_complex" ]; then
            filter_complex="$filter_complex,fps=$output_fps"
        else
            filter_complex="fps=$output_fps"
        fi
        echo -e "帧率限制: 从${fps}fps降低到${output_fps}fps"
    fi

    # 计算目标码率（基于缩放后的分辨率）
    local target_bitrate=$(calculate_bitrate $scaled_width $scaled_height)
    echo -e "目标码率: ${target_bitrate}kbps"

    # 检查是否需要编码
    local need_encode=true
    local skip_reason=""

    # 如果有缩放、裁剪、时间范围或帧率降低，必须重新编码
    if [ "$need_scale" = true ] || [ -n "$crop_params" ] || [ "$need_reduce_fps" = true ]; then
        need_encode=true
        skip_reason=""
        if [ "$need_scale" = true ]; then
            if [ "$auto_scale_applied" = true ]; then
                echo -e "${YELLOW}需要自动缩放，必须重新编码${NC}"
            else
                echo -e "${YELLOW}需要缩放，必须重新编码${NC}"
            fi
        fi
        if [ -n "$crop_params" ]; then
            echo -e "${YELLOW}需要裁剪，必须重新编码${NC}"
        fi
        if [ "$need_reduce_fps" = true ]; then
            echo -e "${YELLOW}需要降低帧率，必须重新编码${NC}"
        fi
    # 如果没有缩放、裁剪、时间范围或帧率降低，检查是否需要跳过编码
    elif [ $bitrate -gt 0 ]; then
        # 计算原始码率的1.2倍
        local threshold_bitrate=$(echo "$bitrate * 1.2" | bc 2>/dev/null | cut -d. -f1)
        # 如果bc命令失败，使用整数计算
        if [ -z "$threshold_bitrate" ]; then
            threshold_bitrate=$((bitrate + bitrate / 5))
        fi

        if [ $target_bitrate -ge $threshold_bitrate ]; then
            need_encode=false
            skip_reason="目标码率(${target_bitrate}kbps) >= 原始码率(${bitrate}kbps) * 1.2"
        else
            echo -e "${YELLOW}需要降低码率 ${target_bitrate} < ${threshold_bitrate}，必须重新编码${NC}"
            need_encode=true
        fi
    else
        # 原始码率为0，保留编码
        echo -e "${YELLOW}无法获取码率，重新编码${NC}"
        need_encode=true
    fi

    if [ "$need_encode" = false ]; then
        echo -e "${BLUE}跳过编码: $skip_reason${NC}"

        # 直接复制或剪切
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

    # 需要编码的情况
    echo -e "${YELLOW}进行重新编码...${NC}"

    # 构建FFmpeg命令基础
    local ffmpeg_cmd="ffmpeg -i \"$input_file\""

    # 添加时间范围参数
    if [ -n "$start_time" ] && [ "$start_time" != "0" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -ss $start_time"
    fi

    if [ -n "$end_time" ]; then
        ffmpeg_cmd="$ffmpeg_cmd -to $end_time"
    fi

    # 添加滤镜参数
    if [ -n "$filter_complex" ]; then
        # 关键修改：在滤镜字符串末尾加上 , 并指定输出标签为 [v]
        ffmpeg_cmd="$ffmpeg_cmd -filter_complex \"$filter_complex[v]\" -map \"[v]\""
    else
        ffmpeg_cmd="$ffmpeg_cmd -map 0:v"
    fi

    # 根据编码模式选择不同的编码函数，使用降低后的帧率
    local encode_result=0
    if [ $enc_2pass -eq 1 ]; then
        # 2-pass编码模式
        if encode_2pass "$ffmpeg_cmd" "$target_bitrate" "$output_file" "$output_fps"; then
            encode_result=0
        else
            encode_result=1
        fi
    else
        # CRF编码模式
        if encode_crf "$ffmpeg_cmd" "$target_bitrate" "$output_file" "$output_fps"; then
            encode_result=0
        else
            encode_result=1
        fi
    fi

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

# 主函数
main() {
    # 显示当前配置
    echo -e "${GREEN}=== 视频转码脚本 ===${NC}"
    echo -e "视频编码: $CODEC_NAME"
    echo -e "编码模式: $([ $enc_2pass -eq 1 ] && echo "2-pass" || echo "CRF")"
    echo -e "音频编码: $AUDIO_CODEC ${AUDIO_BITRATE}"
    if [ -n "$height_refer" ]; then
        echo -e "高度参考值: ${height_refer}px (限制: ${height_limit}px)"
    fi
    if [ -n "$fps_limit" ]; then
        echo -e "帧率限制: ${fps_limit}fps"
    fi
    echo ""

    # 检查参数
    if [ $# -ne 2 ]; then
        show_help
    fi

    local input="$1"
    local output_dir="$2"

    # 检查输出目录是否存在，不存在则创建
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        echo -e "创建输出目录: $output_dir"
    fi

    # 创建日志文件
    local log_file="${output_dir}/encode_$(date '+%Y%m%d_%H%M%S').log"
    echo -e "${PURPLE}日志文件: $log_file${NC}"
    echo "转码任务开始: $(date '+%Y-%m-%d %H:%M:%S')" > "$log_file"
    echo "输入: $input" >> "$log_file"
    echo "输出目录: $output_dir" >> "$log_file"
    echo "配置: $CODEC_NAME, 模式: $([ $enc_2pass -eq 1 ] && echo "2-pass" || echo "CRF")" >> "$log_file"
    if [ -n "$height_refer" ]; then
        echo "高度参考值: ${height_refer}px (限制: ${height_limit}px)" >> "$log_file"
    fi
    if [ -n "$fps_limit" ]; then
        echo "帧率限制: ${fps_limit}fps" >> "$log_file"
    fi
    echo "" >> "$log_file"

    # 检查ffmpeg是否安装
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}错误: ffmpeg未安装${NC}"
        log_status "SYSTEM" "ERROR" "ffmpeg未安装" "$log_file"
        exit 1
    fi

    # 检查jq是否安装（用于解析JSON）
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}错误: jq未安装，请先安装jq${NC}"
        log_status "SYSTEM" "ERROR" "jq未安装" "$log_file"
        echo "Ubuntu/Debian: sudo apt-get install jq"
        echo "CentOS/RHEL: sudo yum install jq"
        echo "macOS: brew install jq"
        exit 1
    fi

    # 检查bc是否安装（用于计算）
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}错误: bc未安装，请先安装bc${NC}"
        log_status "SYSTEM" "ERROR" "bc未安装" "$log_file"
        echo "Ubuntu/Debian: sudo apt-get install bc"
        echo "CentOS/RHEL: sudo yum install bc"
        echo "macOS: brew install bc"
        exit 1
    fi

    # 判断输入类型，得到所有要处理的文件
    local file_list=()
    local parse_line=n
    if [ -d "$input" ]; then
        # 输入是目录，处理所有视频文件
        echo -e "${GREEN}处理目录:${NC} $input"
        parse_line=n

        # 支持的视频格式（扩展名不区分大小写）
        local video_extensions=("mp4" "avi" "mkv" "mov" "wmv" "flv" "webm" "m4v" "mpg" "mpeg" "ts" "3gp" "f4v" "rmvb" "rm" "asf" "vob" "dat" "mts" "m2ts")

        # 创建临时文件
        tmpfile=$(mktemp)
        # 将找到的文件名（以空字符分隔）存储到临时文件
        for ext in "${video_extensions[@]}"; do
            find "$input" -type f \( -iname "*.${ext}" \) -print0 2>/dev/null >> "$tmpfile"
        done

        # 读取临时文件到数组（使用循环，兼容低版本bash）
        while IFS= read -r -d '' file; do
            file_list+=("$file")
        done < "$tmpfile"

        # 删除临时文件
        rm -f "$tmpfile"

    elif [ -f "$input" ]; then
        # 输入是配置文件
        echo -e "${GREEN}处理配置文件:${NC} $input"
        parse_line=y

        # 读取配置文件
        local line_number=0
        while IFS= read -r line || [ -n "$line" ]; do
            let line_number+=1

            # 跳过空行和注释行
            local line_trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ -z "$line_trimmed" || "$line_trimmed" =~ ^# ]]; then
                continue
            fi

            # 解析行
            # 格式: <文件> [时间范围] (裁剪参数) <缩放比例>
            # 使用正则表达式解析
            if [[ "$line_trimmed" =~ ^([^[\(<]+)(\[.*\])?[[:space:]]*(\(.*\))?[[:space:]]*(<.*>)?$ ]]; then
                local filename=$(echo "${BASH_REMATCH[1]}" | sed 's/[[:space:]]*$//')
                # 去除文件名可能的多余空格
                filename=$(echo "$filename" | xargs)
                # 检查文件是否存在
                if [ ! -f "$filename" ]; then
                    echo -e "${RED}错误 (第${line_number}行): 文件不存在 - $filename${NC}"
                    log_status "$filename" "ERROR" "第${line_number}行: 文件不存在" "$log_file"
                    continue
                fi
                file_list+=("$line_trimmed")
            else
                echo -e "${RED}错误 (第${line_number}行): 格式不正确${NC}"
                echo -e "行内容: $line_trimmed"
                log_status "LINE $line_number" "ERROR" "格式不正确: $line_trimmed" "$log_file"
            fi
        done < "$input"
    else
        echo -e "${RED}错误: 输入不存在${NC}"
        show_help
    fi

    # 处理视频文件
    local total=${#file_list[@]}
    local count=0
    local success_count=0
    local error_count=0
    echo -e "需要处理 $total 个视频文件"

    for file in "${file_list[@]}"; do
        let count+=1
        echo -e "${CYAN}==================== $count/$total ====================${NC}"

        if [ $parse_line = n ]; then
            if [ ! -f "$file" ]; then
                echo -e "${RED}错误: 文件不存在 - $file${NC}"
                log_status "$file" "ERROR" "文件不存在" "$log_file"
                let error_count+=1
                continue
            fi
            echo -e "${YELLOW}文件: $file${NC}"
            # 临时禁用set -e，以便错误时继续执行
            set +e
            encode_video "$file" "$output_dir" "" "" "" "$log_file"
            local result=$?
            set -e
        else
            if [[ "$file" =~ ^([^[\(<]+)(\[.*\])?[[:space:]]*(\(.*\))?[[:space:]]*(<.*>)?$ ]]; then
                local filename=$(echo "${BASH_REMATCH[1]}" | sed 's/[[:space:]]*$//')
                local time_range="${BASH_REMATCH[2]}"
                local crop_params="${BASH_REMATCH[3]}"
                local scale_ratio="${BASH_REMATCH[4]}"

                # 去除文件名可能的多余空格
                filename=$(echo "$filename" | xargs)

                # 检查文件是否存在
                if [ ! -f "$filename" ]; then
                    echo -e "${RED}错误: 文件不存在 - $filename${NC}"
                    log_status "$filename" "ERROR" "文件不存在" "$log_file"
                    let error_count+=1
                    continue
                fi

                echo -e "${YELLOW}文件: $filename${NC}"
                if [ -n "$time_range" ]; then
                    echo -e "${YELLOW}时间范围: $time_range${NC}"
                fi
                if [ -n "$crop_params" ]; then
                    echo -e "${YELLOW}裁剪参数: $crop_params${NC}"
                fi
                if [ -n "$scale_ratio" ]; then
                    echo -e "${YELLOW}缩放比例: $scale_ratio${NC}"
                fi

                # 临时禁用set -e，以便错误时继续执行
                set +e
                encode_video "$filename" "$output_dir" "$time_range" "$crop_params" "$scale_ratio" "$log_file"
                local result=$?
                set -e
            fi
        fi

        case $result in
            0)
                let success_count+=1
                ;;
            1)
                let error_count+=1
                ;;
            *)
                let error_count+=1
                ;;
        esac

        # 添加间隔，提高可读性
        if [ $count -lt $total ]; then
            echo ""
        fi
    done

    # 输出统计信息
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}任务完成统计:${NC}"
    echo -e "总共处理: $total 个文件"
    echo -e "${GREEN}成功:${NC} $success_count"
    echo -e "${RED}失败:${NC} $error_count"
    echo -e "${PURPLE}日志文件:${NC} $log_file"

    # 记录统计信息到日志
    echo "" >> "$log_file"
    echo "任务完成统计:" >> "$log_file"
    echo "总共处理: $total 个文件" >> "$log_file"
    echo "成功: $success_count" >> "$log_file"
    echo "失败: $error_count" >> "$log_file"
    echo "转码任务结束: $(date '+%Y-%m-%d %H:%M:%S')" >> "$log_file"

    echo -e "${GREEN}所有任务完成！${NC}"
}

# 运行主函数
main "$@"
