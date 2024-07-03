from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import os

URL_TO_SCRAPE = "https://www.bcferries.com"

chrome_options = Options()
chrome_options.add_argument("--headless")  # Ensure GUI is off for running in non-GUI environments
chrome_options.add_argument("--no-sandbox")  # Bypass OS security model
chrome_options.add_argument("--disable-dev-shm-usage")  # Overcome limited resource problems

# Set up Chrome webdriver
#service = Service(executable_path=CHROMEDRIVER_PATH)
service = Service()
driver = webdriver.Chrome(service=service, options=chrome_options)
driver.get(URL_TO_SCRAPE)
p_elements = driver.find_elements(By.TAG_NAME, 'p')
p_texts = [element.text for element in p_elements if element.text != '']


file_path = "output.txt"

# Open the file in write mode and save the message
with open(file_path, "w") as file:
  file.write(html_content)

print(f"Saved '{html_content}' to {file_path}")

print(html_content)
