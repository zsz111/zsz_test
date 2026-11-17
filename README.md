# test

Playwright + pytest 网页自动化项目（在容器内运行，不依赖 Windows 虚拟环境）。

## 环境

- Python 3.11（`.venv`，由 `uv venv` 创建，Linux x86_64）
- Playwright 驱动**系统自带的 Google Chrome**（`/opt/google/chrome/chrome`），
  因为容器内没有安装 Playwright 自带的 chromium 内核。

`pytest.ini` 里已经写死 `--browser-channel=chrome`，所以直接 `pytest` 即可，
不需要额外传参。

## 目录

```
.
├── pytest.ini                  testpaths=tests，--browser-channel=chrome
├── requirements.txt            playwright / pytest / pytest-playwright
├── data/                       截图等产物（.gitignore 不排除）
└── tests/
    └── test_smoke_browser.py   连通性冒烟：打开百度 → 输入 hello122 → 截图
```

## 运行

```bash
uv pip install -r requirements.txt   # 首次
pytest                                # 全部
pytest -s                             # 带 print 输出
pytest -m smoke                       # 只跑冒烟
```

## 已知坑

百度首页的搜索框是 `textarea#chat-textarea`。
老版 `input#kw` 仍然存在于 DOM，但宽高为 0（`display:inline-block` + 尺寸塌陷），
用 `#kw` 会一直卡在 `waiting for element to be visible`。
