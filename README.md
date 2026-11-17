# zsz_test

Playwright + pytest 网页自动化项目。

同一份代码在 **Windows 本机** 和 **Linux 容器 / CI** 都能直接 `pytest`，
不需要记额外参数——`conftest.py` 会自动判断该用哪个浏览器。

## 快速开始（Windows 本机）

仓库根目录有现成的初始化脚本，**任选一个**：

### PowerShell（推荐）

```powershell
cd E:\colude\test
powershell -ExecutionPolicy Bypass -File .\setup_local.ps1
```

可选参数：

```powershell
.\setup_local.ps1 -SkipBrowserDownload   # 本机已有 Chrome，跳过 150MB 内核下载
.\setup_local.ps1 -SkipTest              # 只初始化，不跑测试
.\setup_local.ps1 -NoBackup              # 不备份旧目录，直接覆盖
.\setup_local.ps1 -Target "D:\work\test" # 换目标目录
```

### 批处理（双击即可）

```text
setup_local.bat
```

做的事完全一样：备份 → clone → venv → 装依赖 → 装内核 → 跑冒烟。

## 手动初始化

```powershell
git clone https://github.com/zsz111/zsz_test.git E:\colude\test
cd E:\colude\test
py -3.11 -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python -m playwright install chromium
pytest -s
```

## 日常运行

```bash
pytest              # 全部
pytest -s           # 显示 print
pytest -m smoke     # 只跑冒烟
pytest --headed     # 显示浏览器窗口
```

## 目录

```
.
├── conftest.py            浏览器自动选择 + 失败自动截图
├── pytest.ini             配置与 marker 声明
├── requirements.txt       playwright / pytest / pytest-playwright
├── setup_local.ps1        本机一键初始化（PowerShell）
├── setup_local.bat        本机一键初始化（批处理）
├── data/                  截图产物
└── tests/
    └── test_smoke_browser.py
```

## 两个环境差异

| | Windows 本机 | Linux 容器 |
|---|---|---|
| 浏览器内核 | `playwright install chromium` 装好的自带内核 | 复用系统 `/opt/google/chrome/chrome` |
| 启动方式 | 默认 | `channel="chrome"` |
| conftest 处理 | 检测到自带内核 → 用默认 | 检测不到 → 自动切 `chrome` |

这段逻辑在 `conftest.py` 的 `pytest_configure` 里，会自动判断，
所以**两边都是直接 `pytest`**。如果显式传了 `--browser-channel`，则以你的为准。

## 失败自动截图

用例失败时，`page` fixture 会把当前页面存到：

```
data/fail_<用例名>.png
```

控制台会打印 `[FAIL-SHOT] <路径>`。

## 已知坑

**百度首页搜索框换了。** 老版 `input#kw` 仍在 DOM 里，但宽高是 0；
实际可见的是 `textarea#chat-textarea`（AI 对话式搜索框）。
用 `#kw` 会一直卡在 `waiting for element to be visible`，重试几十次后失败。

## Playwright MCP

仓库里带 `mcp/playwright/server.json`，可在支持 MCP 的运行时激活
浏览器自动化工具集（21 个 browser_* 工具）。详见
[docs/mcp-integration.md](docs/mcp-integration.md)。

