@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================================
REM  zsz_test 本机初始化脚本（Windows / PowerShell 或 cmd）
REM  用法：把本文件放到 E:\colude\ 下，双击运行；
REM        或在 PowerShell 里执行  .\setup_local.bat
REM ============================================================

set "REPO=https://github.com/zsz111/zsz_test.git"
set "TARGET=E:\colude\test"
set "PYTHON=py -3.11"

echo.
echo ============================================================
echo   1/5  检查前置环境
echo ============================================================

where git >nul 2>&1
if errorlevel 1 (
    echo [X] 未找到 git，请先安装 Git for Windows
    pause & exit /b 1
)
echo [OK] git

%PYTHON% --version >nul 2>&1
if errorlevel 1 (
    echo [X] 未找到 Python 3.11，请安装或改用 python 命令
    echo     安装后重试，或修改本脚本里的 PYTHON 变量
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('%PYTHON% --version 2^>^&1') do echo [OK] %%v

echo.
echo ============================================================
echo   2/5  备份并重新克隆仓库到 %TARGET%
echo ============================================================

if exist "%TARGET%" (
    set "BACKUP=E:\backup\test_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "BACKUP=!BACKUP: =0!"
    echo [..] 发现已有目录，备份到 !BACKUP!
    if not exist "E:\backup" mkdir "E:\backup"
    xcopy "%TARGET%" "!BACKUP!" /E /I /H /Y >nul
    if errorlevel 1 (
        echo [X] 备份失败，中止
        pause & exit /b 1
    )
    echo [OK] 已备份
    rmdir /s /q "%TARGET%"
)

if not exist "E:\colude" mkdir "E:\colude"
cd /d "E:\colude"
git clone "%REPO%" test
if errorlevel 1 (
    echo [X] clone 失败，检查网络或仓库地址
    pause & exit /b 1
)
echo [OK] 已克隆到 %TARGET%

cd /d "%TARGET%"

echo.
echo ============================================================
echo   3/5  创建虚拟环境并安装依赖
echo ============================================================

if not exist ".venv" (
    %PYTHON% -m venv .venv
    if errorlevel 1 (
        echo [X] venv 创建失败
        pause & exit /b 1
    )
)
echo [OK] .venv

call ".venv\Scripts\activate.bat"
python -m pip install --upgrade pip -q
python -m pip install -r requirements.txt -q
if errorlevel 1 (
    echo [X] 依赖安装失败
    pause & exit /b 1
)
echo [OK] 依赖已安装

echo.
echo ============================================================
echo   4/5  安装 Playwright 浏览器内核
echo ============================================================

python -m playwright install chromium
if errorlevel 1 (
    echo [!] chromium 下载失败，尝试复用系统 Chrome
) else (
    echo [OK] chromium 已安装
)

echo.
echo ============================================================
echo   5/5  冒烟验证
echo ============================================================

python -m pytest -s
set "RC=%errorlevel%"

echo.
echo ============================================================
if "%RC%"=="0" (
    echo   [PASS] 环境就绪，截图见 data\baidu_hello122.png
) else (
    echo   [FAIL] 请检查上方输出
)
echo ============================================================

pause
endlocal
