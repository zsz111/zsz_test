<#
.SYNOPSIS
    zsz_test 本机初始化脚本（Windows PowerShell）

.DESCRIPTION
    一键完成：备份旧目录 → 克隆仓库 → 建 venv → 装依赖 →
    装浏览器内核 → 跑冒烟测试。

.EXAMPLE
    # 在 PowerShell 里执行（可能需要先放开执行策略）
    powershell -ExecutionPolicy Bypass -File .\setup_local.ps1

    # 跳过浏览器内核下载（已有系统 Chrome 时）
    .\setup_local.ps1 -SkipBrowserDownload

    # 只初始化不跑测试
    .\setup_local.ps1 -SkipTest
#>
[CmdletBinding()]
param(
    [string]$Repo   = "https://github.com/zsz111/zsz_test.git",
    [string]$Target = "E:\colude\test",
    [string]$Python = "py -3.11",
    [switch]$SkipBrowserDownload,
    [switch]$SkipTest,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"
$step = 0

function Write-Step($text) {
    $script:step++
    Write-Host ""
    Write-Host ("=" * 62) -ForegroundColor DarkCyan
    Write-Host ("  {0}/6  {1}" -f $script:step, $text) -ForegroundColor Cyan
    Write-Host ("=" * 62) -ForegroundColor DarkCyan
}

function Fail($msg) {
    Write-Host "[X] $msg" -ForegroundColor Red
    exit 1
}

function Ok($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Info($msg) { Write-Host "[..] $msg" -ForegroundColor Yellow }

# ============================================================
Write-Step "检查前置环境"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "未找到 git，请先安装 Git for Windows"
}
Ok ("git " + (git --version))

$pyExe, $pyArgs = $Python -split ' ', 2
if (-not (Get-Command $pyExe -ErrorAction SilentlyContinue)) {
    Fail "未找到 $pyExe，请安装 Python 3.11 或修改 -Python 参数"
}
$pyVer = & $pyExe $pyArgs --version 2>&1
if ($LASTEXITCODE -ne 0) { Fail "Python 执行失败：$pyVer" }
Ok $pyVer

# ============================================================
Write-Step "备份并重新克隆到 $Target"

if (Test-Path $Target) {
    if ($NoBackup) {
        Info "跳过备份，直接删除旧目录"
        Remove-Item $Target -Recurse -Force
    } else {
        $stamp  = Get-Date -Format "yyyyMMdd_HHmmss"
        $backup = "E:\backup\test_$stamp"
        Info "发现已有目录，备份到 $backup"
        New-Item -ItemType Directory -Path "E:\backup" -Force | Out-Null
        Copy-Item $Target $backup -Recurse -Force
        Ok "已备份"
        Remove-Item $Target -Recurse -Force
    }
}

$parent = Split-Path $Target -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

git clone $Repo $Target
if ($LASTEXITCODE -ne 0) { Fail "clone 失败，检查网络或仓库地址" }
Ok "已克隆到 $Target"

Set-Location $Target

# ============================================================
Write-Step "创建虚拟环境"

if (-not (Test-Path ".venv")) {
    & $pyExe $pyArgs -m venv .venv
    if ($LASTEXITCODE -ne 0) { Fail "venv 创建失败" }
}
Ok ".venv 就绪"

$venvPy = Join-Path $Target ".venv\Scripts\python.exe"
if (-not (Test-Path $venvPy)) { Fail "找不到 $venvPy" }

# ============================================================
Write-Step "安装依赖"

& $venvPy -m pip install --upgrade pip -q
if ($LASTEXITCODE -ne 0) { Fail "pip 升级失败" }

& $venvPy -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { Fail "依赖安装失败" }
Ok "依赖已安装"

# ============================================================
Write-Step "安装 Playwright 浏览器内核"

if ($SkipBrowserDownload) {
    Info "已跳过（-SkipBrowserDownload）"
} else {
    & $venvPy -m playwright install chromium
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] chromium 下载失败。如果本机有 Chrome，代码会自动复用它。" -ForegroundColor Yellow
    } else {
        Ok "chromium 已安装"
    }
}

# ============================================================
Write-Step "冒烟验证"

if ($SkipTest) {
    Info "已跳过（-SkipTest）"
    Write-Host ""
    Ok "环境已就绪，手动运行： $venvPy -m pytest -s"
    exit 0
}

& $venvPy -m pytest -s
$rc = $LASTEXITCODE

Write-Host ""
Write-Host ("=" * 62) -ForegroundColor DarkCyan
if ($rc -eq 0) {
    Write-Host "  [PASS] 环境就绪" -ForegroundColor Green
    Write-Host "  截图：$Target\data\baidu_hello122.png" -ForegroundColor Gray
} else {
    Write-Host "  [FAIL] 请检查上方输出" -ForegroundColor Red
}
Write-Host ("=" * 62) -ForegroundColor DarkCyan

exit $rc
