import os
import time
from playwright.sync_api import sync_playwright

os.makedirs('test/sucessful/image', exist_ok=True)
os.makedirs('test/sucessful/video', exist_ok=True)

def run():
    print("Starting Playwright script...")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False) # Headless=False helps ensure rendering
        context = browser.new_context(
            record_video_dir="test/sucessful/video/",
            viewport={'width': 400, 'height': 800} # Mobile size
        )
        page = context.new_page()
        
        print("Navigating to http://localhost:8081...")
        page.goto("http://localhost:8081")
        
        print("Waiting for Flutter Web to load (15s)...")
        page.wait_for_timeout(15000)
        
        print("Saving login screenshot...")
        page.screenshot(path="test/sucessful/image/1_login.png")
        
        print("Entering PIN '1234'...")
        page.mouse.click(200, 400)
        page.wait_for_timeout(1000)
        
        for _ in range(3):
            page.keyboard.press("Tab")
            page.wait_for_timeout(300)
            page.keyboard.type("1234")
            
        page.wait_for_timeout(2000)
        print("Clicking Login/Enter...")
        page.keyboard.press("Enter")
        
        print("Waiting for Dashboard to load (10s)...")
        page.wait_for_timeout(10000)
        
        print("Saving dashboard screenshot...")
        page.screenshot(path="test/sucessful/image/2_dashboard.png")
        
        print("Exploring App - Nav Tabs...")
        page.mouse.click(200, 770)
        page.wait_for_timeout(4000)
        page.screenshot(path="test/sucessful/image/3_stock_tab.png")
        
        page.mouse.click(280, 770)
        page.wait_for_timeout(4000)
        page.screenshot(path="test/sucessful/image/4_customers_tab.png")
        
        page.mouse.click(120, 770)
        page.wait_for_timeout(4000)
        page.screenshot(path="test/sucessful/image/5_pos_tab.png")
        
        print("Closing context to save video...")
        context.close()
        browser.close()
        print("Done!")

if __name__ == '__main__':
    run()
