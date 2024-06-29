setup_remote = function() {
  driver = RSelenium::rsDriver(browser="firefox", chromever = NULL, geckover = "latest", iedrver = NULL, phantomver = NULL)
  remote <<- driver[['client']]
}

# page 1
page_1 = function(from = "Vancouver (Horseshoe Bay)", to = "Sunshine Coast (Langdale)", date = Sys.Date() + 1) {
  
  from_css = "[data-code = '" %,% filter(codes, long_name == from)$code %,% "']"
  to_css = "[data-code = '" %,% filter(codes, long_name == to)$code %,% "']"
  date_css = format(as.Date(date), "%m/%d/%Y")
  
  from_element = remote$findElement("id", "fromLocationDropDown")
  from_element$clickElement()
  from_terminal = remote$findElement("css", from_css)
  from_terminal$clickElement()
  
  to_element = remote$findElement("id", "toLocationDropDown")
  to_element$clickElement()
  to_terminal = remote$findElements("css", to_css)
  to_terminal[[2]]$clickElement()
  
  date_element = remote$findElement("class", "datePickerWrapper")
  date_element$clickElement()
  input = remote$findElement("id", "routeInfoForm.departingDateTime")
  input$clearElement()
  input$sendKeysToElement(list(date_css))
  
  continue_element = remote$findElement("id", "y_confirmaddpassenger")
  continue_element$clickElement()
}

page_2 = function() {
  minus1 = remote$findElement("class", "y_outboundPassengerQtySelectorMinus")
  for (i in 1:5) minus1$clickElement()
  add1 = remote$findElement("class", "y_outboundPassengerQtySelectorPlus")
  add1$clickElement()
  continue_element = remote$findElement("class", "fareFinderFindButton")
  continue_element$clickElement()
}

page_3 = function() {
  under7 = remote$findElement("id", "under7Height_0")
  under7$clickElement()
  under20 = remote$findElement("id", "under20Length_0")
  under20$clickElement()
  continue_element = remote$findElement("class", "fareFinderFindButton")
  continue_element$clickElement()
}

get_sailings = function(date = today() + 1) {
  pageSource = remote$getPageSource()[[1]]
  html = read_html(pageSource)
  cards = html %>% html_elements(".p-card")
  
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
      as.double() %>%
      dollar()
    
    tibble_row(date = format(as.Date(date), "%b-%d"), depart=depart, arrive=arrive, ferry=ferry, cost=cost)
  }) %>%
    bind_rows() %>%
    set_names(c("Date", "Depart Time", "Arrive Time", "Ferry Name", "Cost"))
}

make_results = function(t1, t2, dates) {
  sailings = tibble()
  for (date in dates) {
    tryCatch({
      remote$navigate("https://www.bcferries.com")
      page_1(t1, t2, date)
      page_2()
      page_3()
      sailings_i = get_sailings(date)
      sailings = bind_rows(sailings, sailings_i)
    }, error = function(e) print("error with date = " %,% date))
  }
  sailings %>% 
    pivot_wider(id_cols="Depart Time", names_from = "Date", values_from = "Cost") %>%
    mutate(is_am = str_detect(`Depart Time`, "AM")) %>%
    mutate(hour = as.integer(str_extract(`Depart Time`, "[0-9]+(?=:)"))) %>%
    mutate(minute = as.integer(str_extract(`Depart Time`, "(?<=:)[0-9]+"))) %>%
    mutate(is_am = case_when(hour == 12 ~ !is_am, TRUE ~ is_am)) %>%
    arrange(desc(is_am), hour, minute) %>%
    select(-is_am, -hour, -minute)
}