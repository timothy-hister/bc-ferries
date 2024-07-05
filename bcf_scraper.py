from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os
import json
import datetime
from os.path import exists

codes = {
  "Vancouver (Tsawwassen)": "TSA",
  "Victoria (Swartz Bay)": "SWB",
  "Vancouver (Horseshoe Bay)": "HSB",
  "Sunshine Coast (Langdale)": "LNG",
  "Nanaimo (Departure Bay)": "NAN"
  }


if exists('shiny_inputs.txt'):
  
  inputs = {}
  with open('shiny_inputs.txt', 'r') as file:
    lines = file.readlines()
    for line in lines:
      key, value = line.strip().split('=')
      inputs[key.strip()] = value.strip()
  
  
  #     "long_name": ["Vancouver (Tsawwassen)", "Vancouver (Horseshoe Bay)", "Victoria (Swartz Bay)", "Sunshine Coast (Langdale)", "Nanaimo (Departure Bay)"],
  #     "short_name": ["Vancouver (TSA)", "Vancouver (HSB)", "Victoria (SWB)", "Sunshine Coast (LNG)", "Nanaimo (NAN)"],
  #     "code": ["TSA", "HSB", "SWB", "LNG", "NAN"]
  # })
  
  URL_TO_SCRAPE = "https://www.bcferries.com"
  
  chrome_options = Options()
  chrome_options.add_argument("--headless")  # Ensure GUI is off for running in non-GUI environments
  chrome_options.add_argument("--no-sandbox")  # Bypass OS security model
  chrome_options.add_argument("--disable-dev-shm-usage")  # Overcome limited resource problems
  
  # Set up Chrome webdriver
  service = Service()
  driver = webdriver.Chrome(service=service, options=chrome_options)
  driver.get(URL_TO_SCRAPE)
  
  # Set up variables
  from_css = "[data-code = '" + codes[inputs['departure']] + "']"
  to_css = "[data-code = '" + codes[inputs['arrival']] + "']"
  date_css = datetime.datetime.strptime(inputs['date'], "%Y-%m-%d").strftime("%m/%d/%Y")
  
  from_element = driver.find_element(By.ID, "fromLocationDropDown")
  from_element.click()
  from_terminal = driver.find_element(By.CSS_SELECTOR, from_css)
  from_terminal.click()
  
  to_element = driver.find_element(By.ID, "toLocationDropDown")
  to_element.click()
  
  to_terminal = driver.find_elements(By.CSS_SELECTOR, to_css)
  to_terminal[1].click()
  
  date_element = driver.find_element(By.CLASS_NAME, "datePickerWrapper")
  date_element.click()
  
  input_elem = driver.find_element(By.ID, "routeInfoForm.departingDateTime")
  input_elem.clear()
  input_elem.send_keys(date_css)
  
  continue_element = driver.find_element(By.ID, "y_confirmaddpassenger")
  continue_element.click()
  
  ## PAGE 2
  
  for i in range(5):
    minus1 = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "y_outboundPassengerQtySelectorMinus")))
    minus1.click()
  
  # Finding and clicking the add button once
  add1 = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "y_outboundPassengerQtySelectorPlus")))
  add1.click()
  
  # Finding and clicking the continue button
  continue_element = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "fareFinderFindButton")))
  continue_element.click()
  
  ## PAGE 3
  
  under7 = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID, "under7Height_0")))
  under7.click()
  
  # Clicking on the under20Length_0 checkbox
  under20 = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID, "under20Length_0")))
  under20.click()
  
  # Finding and clicking the continue button
  continue_element = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "fareFinderFindButton")))
  continue_element.click()
  
  cards = driver.find_elements(By.CLASS_NAME, "p-card")
  cards_text = '\n'.join([element.text for element in cards if element.text != ''])
  cards_text = str(datetime.datetime.now()) + '\n' + cards_text
  
  file_path = "python_output.txt"
  with open(file_path, 'w') as file:
      file.write(cards_text)
  
  print('done')
