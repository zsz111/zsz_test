语气要自然，先人后文，其他约束不变：

# Playwright MCP 集成

本仓库带一个 Playwright MCP server 的清单（manifest），可以在
MyFlicker / OpenClaw 类运行时里直接激活浏览器自动化工具集。

## 目录

```
mcp/playwright/server.json   ← MCP server manifest
```

## 容器 / CI 里激活（Linux）

```bash
# 1. 装 MCP server 包（内网 registry）
npm install @playwright/mcp --registry https://npm.corp.kuaishou.com/

# 2. server.json 已用相对路径 node_modules/@playwright/mcp/cli.js，
#    在仓库根目录激活即可被扫描到：
#    mcp_activate(["playwright"])  →  mcp_list_tools("playwright")
```

注意几个启动参数：

| 参数 | 原因 |
|---|---|
| `--browser chrome` | 容器没有 Playwright 自带内核，借用系统 Chrome |
| `--headless` | 无显示环境 |
| `--isolated` | 每次全新 profile，避免登录态串扰 |
| `--output-dir data` | 截图等产物统一落到 `data/` |

已知坑：`--output-dir` 会被 MCP 相对化到它自己的 cwd，
保存产物时**在 `filename` 参数里传绝对路径**最稳。

## Windows 本机激活

本机装了 Playwright 自带内核，把 `--browser chrome` 换成
`--browser chromium` 即可（或直接删掉该参数用默认）。

## 与 pytest 共存

两条链路互不影响：

- `pytest` → pytest-playwright 自己管理浏览器生命周期
- MCP → MCP server 自己管理

不要在 pytest 用例运行期间同时用 MCP 操作同一个 profile。
