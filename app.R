pacman::p_load(shiny, bslib, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs, gh, httr2, jsonlite)

`%,,%` = function(a,b) paste(a,b)
`%,%`= function(a,b) paste0(a,b)

codes = tribble(~long_name, ~short_name, ~code,
  "Vancouver (Tsawwassen)", "Vancouver (TSA)", "TSA",
  "Vancouver (Horseshoe Bay)", "Vancouver (HSB)", "HSB",
  "Victoria (Swartz Bay)", "Victoria (SWB)", "SWB",
  "Sunshine Coast (Langdale)", "Sunshine Coast (LNG)", "LNG",
  "Nanaimo (Departure Bay)", "Nanaimo (NAN)", "NAN"
)

token = read_lines("token.txt")

#source("functions.R", local = T)
source("github.R", local = T)
source("ui.R", local = T)

if (fs::file_exists("python_output.txt")) fs::file_delete("python_output.txt")
if (fs::file_exists("shiny_inputs.txt")) fs::file_delete("shiny_inputs.txt")
fs::file_create("python_output.txt")
github_commit(repo = "bc-ferries", branch = "main", token = token, file_path = "python_output.txt", message = "push blank python_output.txt")

server = function(input, output, session) {
  
  observeEvent(input$search, {
    inputs = list(departure = input$departure, arrival = input$arrival, roundtrip = input$roundtrip, date = format(input$date, "%Y-%m-%d"), return_date = format(input$return_date, "%Y-%m-%d"), plusminus= input$plusminus)
    
    writeLines(paste(names(inputs), inputs, sep = "=", collapse = "\n"), "shiny_inputs.txt")
    github_commit(repo = "bc-ferries", branch = "main", token = token, file_path = "shiny_inputs.txt", message = "shiny commit")
    fs::file_delete("shiny_inputs.txt")
  })
  
  result = eventReactive(input$search, {
    sailings_list = readLines("https://raw.githubusercontent.com/timothy-hister/bc-ferries/main/python_output.txt")
    
    w = which(sailings_list == "DEPART")
    tibble(
      departure_time = sailings_list[w+1],
      duration = sailings_list[w+2],
      arrival_time = sailings_list[w+4],
      ferry = sailings_list[w+5],
      cost = sailings_list[w+7]
    )
  })
  
  output$leg_1 = renderReactable(reactable(result()))
  
  
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
    
  
  observe({
    req(input$REQUEST)
    payload <- fromJSON(input$REQUEST)
    
    # Process the payload as needed
    # Example: Log the event
    cat("Received webhook event:", payload$hook_id, "\n")
    
    # Example: Update data or trigger some action based on the webhook event
    # Your logic here...
    
    # Output the event to UI (for demonstration purposes)
    output$webhook_event <- renderText({
      paste("Received webhook event:", payload$hook_id)
    })
  })
  
}

shinyApp(ui = ui, server = server)