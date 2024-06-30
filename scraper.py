# scraper.py

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import os

# Path to the chromedriver executable
# CHROMEDRIVER_PATH = "C:/Users/djsch\OneDrive\Documents\Computer_Projects/BC_Ferries"

# URL of the web page you want to scrape
URL_TO_SCRAPE = "https://example.com"

def scrape_page(url):
    # Configure Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Ensure GUI is off for running in non-GUI environments
    chrome_options.add_argument("--no-sandbox")  # Bypass OS security model
    chrome_options.add_argument("--disable-dev-shm-usage")  # Overcome limited resource problems

    # Set up Chrome webdriver
    #service = Service(executable_path=CHROMEDRIVER_PATH)
    service = Service()
    driver = webdriver.Chrome(service=service, options=chrome_options)

    try:
        # Load page
        driver.get(url)

        # Get page source (HTML)
        page_source = driver.page_source

        return page_source

    finally:
        # Quit webdriver
        driver.quit()

if __name__ == "__main__":
    html_content = scrape_page(URL_TO_SCRAPE)
    file_path = "output.txt"

    # Open the file in write mode and save the message
    with open(file_path, "w") as file:
        file.write(html_content)
    
    print(f"Saved '{html_content}' to {file_path}")

    print(html_content)
