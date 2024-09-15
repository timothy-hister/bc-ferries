is_test_run = T

pacman::p_load(shiny, bslib, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs, gh, httr2, jsonlite, fs, tippy)

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

#session_id = if_else(is_test_run, sample(c(22733055L, 2641081L), 1), as.integer(runif(1, 0, 10^8)))
session_id = if_else(is_test_run, sample(7070247, 1), as.integer(runif(1, 0, 10^8)))
# note: the repo needs this: actions > general > workflow permissions > read and write

ui = page_sidebar(
  theme =  bs_theme(),
  useShinyjs(),
  title = "Because the BC Ferries Website Sucks",
  sidebar = sidebar(
    pickerInput("departure_terminal", "Departure Terminal", choices = berths, selected = "Vancouver (Tsawwassen)", multiple = F),
    pickerInput("arrival_terminal", "Arrival Terminal", choices = berths, selected = "Victoria (Swartz Bay)", multiple = F),
    prettySwitch("is_roundtrip", "Roundtrip?", value = F),
    airDatepickerInput("departure_date", "Departure Date", minDate = today(), value = today() + 2),
    hidden(airDatepickerInput("return_date", "Select Your Return Date", minDate = today(), value = today() + 4)),
    sliderInput("plusminus", "How many days before/after do you wanna search?", min = 0, max = 10, value = 2),
    actionBttn("go", "Search Sailings!")
  ),
  accordion(
    id = "accordion", 
    accordion_panel(
      title = "Outbound Sailings",
      reactableOutput("outbound_tbl") |> withSpinner(),
      value = "outbound_panel"
    ),
    div(
      id = "return_accordion",
      accordion_panel(
        title = "Return Sailings",
        reactableOutput("return_tbl") |> withSpinner(),
        value = "return_panel"
      )
    )
  )
)

server = function(input, output, session) {
  
  # initialize reactive values
  github_file = reactiveVal(F)
  python_file = reactiveVal()
  sailings_tbls = reactiveValues()
  
  # show/hide return panel
  observeEvent(input$is_roundtrip, if (input$is_roundtrip) {
    show("return_accordion")
    show("return_date")
  } else {
    hide("return_accordion")
    hide("return_date")
  })
  
  observeEvent(input$go, {
    print("Let's A Go!")
    
    github_file = reactiveVal(F)
    python_file = reactiveVal()
    sailings_tbls = reactiveValues()
    
    showSpinner("outbound_tbl")
    showSpinner("return_tbl")
  })
  
  # make df of all the sailings to search
  sailings = eventReactive(input$go, {
    df = crossing(is_outbound = T, departure_terminal = input$departure_terminal, arrival_terminal = input$arrival_terminal, date = input$departure_date + seq(-input$plusminus, input$plusminus))
    if (input$is_roundtrip) df = bind_rows(df, crossing(is_outbound = F, departure_terminal = input$arrival_terminal, arrival_terminal = input$departure_terminal, date = input$return_date + seq(-input$plusminus, input$plusminus)))
    return(df)
  })
  
  observe(print(sailings()))
  
  # commit to github
  observeEvent(sailings(), {
    if (!is_test_run) {
      if (!dir_exists("from_r")) dir_create("from_r")
      write_json(sailings(), "from_r/from_r_" %,% session_id %,% ".json")
      github_commit(
        repo = "bcftest", 
        branch = "main", 
        token = token, 
        file_path = "from_r/from_r_" %,% session_id %,% ".json", 
        message = "This is a Shiny commit with session_id" %,,% session_id %,,% "and n_sailings" %,,% nrow(sailings())
      )
    }
  })
  
  # get your data from github
  observeEvent(input$go, {
    for (i in 1:nrow(sailings())) {
      print(i)
      tryCatch({
        'https://raw.githubusercontent.com/timothy-hister/bcftest/main/from_python/from_python_' %,% session_id %,% '_' %,% i %,% '.json' |>
          request() |>
          req_auth_bearer_token(token) |>
          req_perform() |>
          resp_body_json(check_type = F) |>
          unlist() |>
          str_split("\n") |>
          map(function(sailing) tibble(depart_time = sailing[2], length = sailing[3], arrive_time = sailing[5], vessel = sailing[6], fare = sailing[8], sold_out = str_detect(sailing[9], "sold out"))) |>
          bind_rows() |>
          mutate(fare = as.double(str_remove(fare, "\$"))) |>
          python_file()
          break
        }, error = function(e) {
          print("nope")
          Sys.sleep(4)
        }
      )
    
    
    
    dfs = make_table(fileContent())
    outputs$outbound_cost = dfs[[1]]
    outputs$outbound_vessel = dfs[[2]]
    outputs$return_cost = dfs[[3]]
    outputs$return_vessel = dfs[[4]]
  })
  
  observe({
    accordion_panel_update(id = "accordion", target = "outbound_panel", title = HTML("<strong>Outbound</strong>:", input$departure, "==>", input$arrival))
    accordion_panel_update(id = "accordion", target = "return_panel", title = HTML("<strong>Return</strong>:", input$arrival, "==>", input$departure))
  })
  
  output$header_outbound = renderText(paste("Outbound:", input$departure))
  output$header_return = renderText(paste("Return:", input$arrival))
  
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