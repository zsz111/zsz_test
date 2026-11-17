# -*- coding: utf-8 -*-
"""
全局配置

关键点：Playwright 浏览器内核的自动选择。

- 本机（Windows）：`python -m playwright install chromium` 装好了自带内核，
  直接用它，无需任何参数。
- 容器 / CI：镜像里没有装 Playwright 内核，但系统装了 Google Chrome，
  此时自动退化为 `channel="chrome"`，复用系统浏览器。

这样同一份代码在两种环境里都能直接 `pytest`，不用记参数。
"""
import pathlib

import pytest

HERE = pathlib.Path(__file__).resolve().parent


def _bundled_chromium_exists() -> bool:
    """检查 Playwright 自带 chromium 内核是否存在"""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        return False
    try:
        with sync_playwright() as p:
            return pathlib.Path(p.chromium.executable_path).exists()
    except Exception:
        return False


def pytest_configure(config):
    """若自带内核缺失，自动切到系统 Chrome"""
    if config.option.browser_channel:
        return  # 用户显式指定了，尊重
    if not _bundled_chromium_exists():
        config.option.browser_channel = "chrome"


@pytest.fixture(scope="session")
def artifacts_dir() -> pathlib.Path:
    """截图 / trace 输出目录"""
    d = HERE / "data"
    d.mkdir(parents=True, exist_ok=True)
    return d


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """记录每个阶段的结果，供失败截图使用"""
    outcome = yield
    rep = outcome.get_result()
    setattr(item, f"rep_{rep.when}", rep)


@pytest.fixture
def page(page, request, artifacts_dir):
    """
    在 pytest-playwright 的 page 之上加失败截图。

    用例失败时自动把当前页面截图存到 data/fail_<用例名>.png，
    并挂到 allure（如果装了 allure-pytest）。
    """
    yield page

    rep = getattr(request.node, "rep_call", None)
    if rep is not None and rep.failed:
        name = request.node.name.replace("[", "_").replace("]", "")
        shot = artifacts_dir / f"fail_{name}.png"
        try:
            page.screenshot(path=str(shot))
            print(f"\n[FAIL-SHOT] {shot}")
        except Exception as e:  # 页面可能已关闭
            print(f"\n[FAIL-SHOT] 截图失败: {e}")
