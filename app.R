pacman::p_load(shiny, bslib, RSelenium, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs)

`%,,%` = function(a,b) paste(a,b)
`%,%`= function(a,b) paste0(a,b)

codes = tribble(~long_name, ~short_name, ~code,
  "Vancouver (Tsawwassen)", "Vancouver (TSA)", "TSA",
  "Vancouver (Horseshoe Bay)", "Vancouver (HSB)", "HSB",
  "Victoria (Swartz Bay)", "Victoria (SWB)", "SWB",
  "Sunshine Coast (Langdale)", "Sunshine Coast (LNG)", "LNG",
  "Nanaimo (Departure Bay)", "Nanaimo (NAN)", "NAN"
)

#source("functions.R", local = T)
source("ui.R", local = T)

# devtools::source_url("https://raw.githubusercontent.com/timothy-hister/bc-ferries/main/test.R")

# remote = setup_remote()
# remote$navigate("https://www.bcferries.com")
# pageSource = driver$getPageSource()[[1]]
# html = read_html(pageSource)
# txt = html %>% html_elements("p") %>% paste(collapse=",")
  
server = function(input, output, session) {
  
  # constrain arrivals
  observeEvent(input$departure, {
    if (input$departure == codes$long_name[1]) updatePickerInput(session = session, inputId = "arrival", choices = c(codes$long_name[3]))
    if (input$departure == codes$long_name[2]) updatePickerInput(session = session, inputId = "arrival", choices = c(codes$long_name[4:5]))
    if (input$departure == codes$long_name[3]) updatePickerInput(session = session, inputId = "arrival", choices = c(codes$long_name[1]))
    if (input$departure == codes$long_name[4]) updatePickerInput(session = session, inputId = "arrival", choices = c(codes$long_name[2]))
    if (input$departure == codes$long_name[5]) updatePickerInput(session = session, inputId = "arrival", choices = c(codes$long_name[2]))
  })
  
  # show/hide return date
  observeEvent(input$roundtrip, if (input$roundtrip) shinyjs::show("return_date") else shinyjs::hide("return_date"))

  # show/hide ui return
  observeEvent(input$roundtrip, if (input$roundtrip) shinyjs::show("panel2") else shinyjs::hide("panel2"))
  
  # show/hide accordion panel
  observeEvent(input$roundtrip, if (input$roundtrip) accordion_panel_insert(id = "accordion", accordion_panel("Return Leg: " %,% filter(codes, long_name == input$arrival)$short_name %,% " ==> " %,% filter(codes, long_name == input$departure)$short_name, reactableOutput("return_leg") %>% withSpinner(), value = "panel2"
  ), target = "panel1", session = session) else accordion_panel_remove(id = "accordion", target = "panel2", session = session)) 
  
  # update panel names
  observe(accordion_panel_update(id = "accordion", target = "panel1", title = "First Leg: " %,% filter(codes, long_name == input$departure)$short_name %,% " ==> " %,% filter(codes, long_name == input$arrival)$short_name))
  
  # constrain return leg
  observeEvent(input$date, updateAirDateInput(session = session, inputId = "return_date", value = input$date + 1))
  
  observe({
    i = round(runif(1) * 10)
    system("git pull")
    system("rm output.txt")
    system(paste0("echo '", i, "' >> output.txt"))
    system("git add .")
    system("git commit -m 'committed'")
    system("git push")
  })
  
  txt = reactive(if (fs::file_exists("output.txt")) readLines("output.txt") else "no file")
  output$txt = renderText(txt())
  
  #results = eventReactive(input$search, {
   # remote$navigate("https://www.bcferries.com")
    
    
    #driver = RSelenium::rsDriver(browser="firefox", chromever = NULL, geckover = "latest", iedrver = NULL, phantomver = NULL)
  #   driver = RSelenium::rsDriver(browser="chrome", chromever = 'latest', geckover = NULL, iedrver = NULL, phantomver = NULL)
  #   
  #   remote <<- driver$client
  #   remote$setTimeout(type = "page load", milliseconds = 20000)
  #   remote$navigate("https://www.bcferries.com")
  #   if (remote$getCurrentUrl() == "https://reservations.mybcf.com/planned-outage-sc-cc/") return("Website is down. You suck, BC Ferries.")
  #   
  #   dates = seq.Date(from = input$date - input$plusminus, to = input$date + input$plusminus, by=1)
  #   dates = dates[dates >= today()]
  #   make_results(input$departure, input$arrival, dates)
  # })
  # 
  # results2 = eventReactive(input$search, {
  #   if (!input$roundtrip) return(NULL)
  #   dates = seq.Date(from = input$return_date - input$plusminus, to = input$return_date + input$plusminus, by=1)
  #   dates = dates[dates >= today()]
  #   make_results(input$arrival, input$departure, dates)
  # })
  # 
  # output$first_leg = renderReactable(reactable(results(), highlight = T, pagination = F))
  # 
  # output$return_leg = renderReactable(reactable(results2(), highlight = T, pagination = F))
    
}

shinyApp(ui = ui, server = server)