`%,,%` = function(a,b) paste(a,b)
`%,%`= function(a,b) paste0(a,b)
pacman::p_load(RSelenium, rvest)

seleniumize = function(f, t, d) {
  #f_code = codes[f]
  #t_code = codes[t]
  f_code = f
  t_code = t
  d_formatted = format(as.Date(d), "%m/%d/%Y")
  from_css = "[data-code = '" %,% f_code %,% "']"
  to_css = "[data-code = '" %,% t_code %,% "']"
  
  port = 4567L
  while(T) {
    success = F
    tryCatch({
      remote = RSelenium::rsDriver(port = port, verbose=T, browser='firefox', chromever=NULL, phantomver = NULL, iedrver = NULL)$client
      success = T
      break
    }, error=function(e) {}
    )
    if (success) break
    port = port + 1
    print(port)
  }
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
