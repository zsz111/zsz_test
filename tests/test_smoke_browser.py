# -*- coding: utf-8 -*-
"""
Playwright 环境连通性冒烟测试

验证链路：打开百度 → 输入 hello122 → 截图 → 输出 URL/标题/截图路径

注意：百度首页新版搜索框是 textarea#chat-textarea，
老版 input#kw 仍在 DOM 中但宽高为 0（隐藏），用 #kw 会一直 waiting for visible。
"""
import pathlib

import pytest
from playwright.sync_api import expect

DATA = pathlib.Path(__file__).resolve().parent.parent / "data"
SEARCH_BOX = "#chat-textarea"


@pytest.mark.smoke
def test_baidu_hello122(page):
    page.goto("https://baidu.com", wait_until="domcontentloaded")

    box = page.locator(SEARCH_BOX)
    box.wait_for(state="visible", timeout=15_000)
    box.fill("hello122")
    expect(box).to_have_value("hello122")

    out = DATA / "baidu_hello122.png"
    DATA.mkdir(parents=True, exist_ok=True)
    page.screenshot(path=str(out))

    print(f"\nURL   = {page.url}")
    print(f"TITLE = {page.title()}")
    print(f"SHOT  = {out}")

    assert "baidu.com" in page.url
    assert out.exists() and out.stat().st_size > 0
