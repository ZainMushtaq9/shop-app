import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys

os.makedirs('test/sucessful/image', exist_ok=True)

def run():
    print("Starting Selenium script...")
    options = Options()
    options.add_argument('--window-size=1280,1024')
    driver = webdriver.Chrome(options=options)
    
    try:
        print("Navigating to http://localhost:8081...")
        driver.get("http://localhost:8081")
        time.sleep(15)
        
        driver.save_screenshot("test/sucessful/image/1_login.png")
        
        print("Entering PIN '1234'...")
        actions = ActionChains(driver)
        for _ in range(5):
            actions.send_keys(Keys.TAB).perform()
            time.sleep(0.5)
            actions.send_keys("1234").perform()
            
        time.sleep(1)
        actions.send_keys(Keys.ENTER).perform()
        
        time.sleep(10)
        driver.save_screenshot("test/sucessful/image/2_dashboard.png")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        driver.quit()
        print("Done.")

if __name__ == '__main__':
    run()
