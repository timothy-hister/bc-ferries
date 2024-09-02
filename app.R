pacman::p_load(shiny, bslib, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs, gh, httr2, jsonlite, fs, tippy)

is_test_run = F

berths = list(
  "Vancouver (Tsawwassen)",
  "Victoria (Swartz Bay)",
  "Vancouver (Horseshoe Bay)",
  "Sunshine Coast (Langdale)",
  "Nanaimo (Departure Bay)"
)

`%,,%` = function(a,b) paste(a,b)
`%,%`= function(a,b) paste0(a,b)

source("github.R", local = T)
source("token.R", local = T)
source("make_table.R", local = T)
source("make_reactable.R", local = T)

session_id = if_else(is_test_run, sample(c(22733055L, 2641081L), 1), as.integer(runif(1, 0, 10^8)))
# note: the repo needs this: actions > general > workflow permissions > read and write

ui = page_sidebar(
  theme =  bs_theme(),
  useShinyjs(),
  title = "Because the BC Ferries Website Sucks",
  sidebar = sidebar(
    pickerInput("departure", "Departure", choices = berths, selected = "Vancouver (Tsawwassen)", multiple = F),
    pickerInput("arrival", "Arrival", choices = berths, selected = "Victoria (Swartz Bay)", multiple = F),
    prettySwitch("roundtrip", "Roundtrip?", value = F),
    airDatepickerInput("date", "Select Your Date", minDate = today(), value = today() + 2),
    hidden(airDatepickerInput("return_date", "Select Your Return Date", minDate = today(), value = today() + 4)),
    sliderInput("plusminus", "How many days before/after do you wanna search?", min = 0, max = 10, value = 2),
    actionBttn("go", "Search Sailings!")
  ),
  accordion(
    id = "accordion", 
    accordion_panel(
      title = "Outbound",
      reactableOutput("outbound") |> withSpinner(),
      value = "outbound_panel"
    ),
    div(
      id = "return_accordion",
      accordion_panel(
        title = "Return",
        reactableOutput("return") |> withSpinner(),
        value = "return_panel"
      )
    )
  )
)

server = function(input, output, session) {
  observe({
    accordion_panel_update(id = "accordion", target = "outbound_panel", title = HTML("<strong>Outbound</strong>:", input$departure, "==>", input$arrival))
    accordion_panel_update(id = "accordion", target = "return_panel", title = HTML("<strong>Return</strong>:", input$arrival, "==>", input$departure))
  })
  
  output$header_outbound = renderText(paste("Outbound:", input$departure))
  output$header_return = renderText(paste("Return:", input$arrival))
                                      
  
  observeEvent(input$roundtrip, if (input$roundtrip) {
    show("return_accordion")
    show("return_date")
  } else {
    hide("return_accordion")
    hide("return_date")
  })
  
  github_file = reactiveVal(F)
  fileContent = reactiveVal()
  outputs = reactiveValues()
  
  observeEvent(input$go, {
    print("Let's A Go!")
    
    github_file = reactiveVal(F)
    fileContent = reactiveVal()
    outputs = reactiveValues()
    go_clicked = reactiveVal(T)
    
    showSpinner("outbound")
    showSpinner("return")
  })
  
  # commit to the repo
  observeEvent(input$go, {
    if (!is_test_run) {
      if (!dir_exists("jsons")) dir_create("jsons")
      
      sailings = list(session_id = session_id)
      sailings$outbound_dates = input$date + seq(-input$plusminus, input$plusminus)
      sailings$departure = input$departure
      sailings$arrival = input$arrival
      sailings$roundtrip = as.integer(input$roundtrip)
      sailings$return_dates = input$return_date + seq(-input$plusminus, input$plusminus)
      
      sailings |>
        write_json("jsons/bcf_" %,% session_id %,% ".json")
      github_commit(
        repo = "bcftest", 
        branch = "main", 
        token = token, 
        file_path = "jsons/bcf_" %,% session_id %,% ".json", 
        message = "shiny_commit_" %,% session_id
      )
    }
  })
  
  observeEvent(input$go, {
    while(T) {
      print("github:" %,,% github_file())
      tryCatch({
        "https://raw.githubusercontent.com/timothy-hister/bcftest/main/dfs/df_" %,% session_id %,% ".json" |>
          httr2::request() |>
          httr2::req_perform() |>
          httr2::resp_body_json(check_type = F) |>
          fileContent()
        github_file(T)
      }, error = function(e) return()
      )
      if (github_file()) break
      Sys.sleep(4)
    }
    
    print("github:" %,,% github_file())
    
    
    dfs = make_table(fileContent())
    outputs$outbound_cost = dfs[[1]]
    outputs$outbound_vessel = dfs[[2]]
    outputs$return_cost = dfs[[3]]
    outputs$return_vessel = dfs[[4]]
  })
  
  output$outbound = renderReactable({
    req(outputs$outbound_cost)
    make_reactable(outputs$outbound_cost, outputs$outbound_vessel, input$date)
  })
  
  output$return = renderReactable({
    req(outputs$return_cost)
    if (!is.null(outputs$return_cost)) make_reactable(outputs$return_cost, outputs$return_vessel, input$return_date)
  })
  
}

shinyApp(ui = ui, server = server)