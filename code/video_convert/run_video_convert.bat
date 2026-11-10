@echo off

if "%~1"=="" (
    echo 请把要转码的视频文件夹或配置文件拖到本 bat 上运行。
    pause
    exit /b
)

set "INPUT=%~1"
set "INPUT_DIR=%~dp1"

rem 去掉末尾反斜杠（%~dp1 对文件夹会带结尾 \）
if "%INPUT_DIR:~-1%"=="\" set "INPUT_DIR=%INPUT_DIR:~0,-1%"

rem 判断是文件夹还是文件
if exist "%INPUT%\" (
    rem 文件夹：取文件夹名
    for %%F in ("%INPUT%") do set "NAME=%%~nxF"
) else (
    rem 文件：取不带后缀的文件名
    for %%F in ("%INPUT%") do set "NAME=%%~nF"
)

set "OUTPUT=%INPUT_DIR%\%NAME%-enc"

echo 输入: %INPUT%
echo 输出: %OUTPUT%
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0video_convert.ps1" "%INPUT%" "%OUTPUT%"

pause