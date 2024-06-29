pacman::p_load(RSelenium, tidyverse, histerr, rvest, stringr, reactable, scales)
driver <- rsDriver(browser = "firefox", chromever=NULL)
remote <- driver[["client"]]

codes = c("Vancouver (Tsawwassen)" = "TSA",  "Vancouver (Horseshoe Bay)" = "HSB", "Victoria (Swartz Bay)" = "SWB", "Sunshine Coast (Langdale" = "LNG", "Nanaimo (Departure Bay)" = "NAN")

seleniumize = function(f, t, d) {
  f_code = codes[f]
  t_code = codes[t]
  d_formatted = format(d, "%m/%d/%Y")
  from_css = "[data-code = '" %,% f_code %,% "']"
  to_css = "[data-code = '" %,% t_code %,% "']"
  
  remote$navigate("https://www.bcferries.com")
  
  from = remote$findElement("id", "fromLocationDropDown")
  from$clickElement()
  from_terminal = remote$findElement("css", from_css)
  from_terminal$clickElement()
  
  to = remote$findElement("id", "toLocationDropDown")
  to$clickElement()
  to_terminal = remote$findElements("css", to_css)
  to_terminal[[2]]$clickElement()
  
  date = remote$findElement("class", "datePickerWrapper")
  date$clickElement()
  input = remote$findElement("id", "routeInfoForm.departingDateTime")
  input$clearElement()
  input$sendKeysToElement(list(d_formatted))
  
  continue = remote$findElement("id", "y_confirmaddpassenger")
  continue$clickElement()
  
  add1 = remote$findElement("class", "y_outboundPassengerQtySelectorPlus")
  add1$clickElement()
  continue = remote$findElement("class", "fareFinderFindButton")
  continue$clickElement()
  
  under7 = remote$findElement("id", "under7Height_0")
  under7$clickElement()
  under20 = remote$findElement("id", "under20Length_0")
  under20$clickElement()
  continue = remote$findElement("class", "fareFinderFindButton")
  continue$clickElement()
  
  pageSource = remote$getPageSource()[[1]]
  html = read_html(pageSource)
  cards = html %>% html_elements(".p-card")
}

get_sailings = function(cards, date) {
  map(cards, function(card) {
    depart = card %>% 
      html_text2() %>%
      str_extract("(?<=DEPART\n).+(?=\n)")
      
    arrive = card %>% 
      html_text2() %>%
      str_extract("(?<=ARRIVE\n).+(?=\n)")
    
    ferry = card %>%
      html_text2() %>%
      str_extract("(?<=FERRY\n\n).+(?=\n)")
    
    cost = card %>%
      html_text2() %>%
      str_extract("(?<=Total From\n).+(?=\n)") %>%
      str_replace("\\$", "") %>%
      as.double()
    
    tibble_row(date = date, depart=depart, arrive=arrive, ferry=ferry, cost=cost)
  }) %>%
    bind_rows()
}

depart = names(codes)[3]
arrive = names(codes)[1]
dates = today() + 18:21

t = map(dates, function(date) {
  selenium = seleniumize(depart, arrive, date)
  result = get_sailings(selenium, date)
}) %>%
  bind_rows()

saveRDS(t, "t.Rds")


t %>%
  mutate(cost = dollar(cost)) %>%
  mutate(date = format(date, "%Y-%b-%d")) %>%
  pivot_wider(id_cols=date, names_from = depart, values_from = cost) %>%
  reactable()
