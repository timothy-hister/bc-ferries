is_test_run = T

pacman::p_load(shiny, bslib, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs, gh, httr2, jsonlite, fs, tippy, lubridate, RColorBrewer)

terminals = list(
  "Vancouver (Tsawwassen)" = "TSA",
  "Victoria (Swartz Bay)" = "VSB",
  "Vancouver (Horseshoe Bay)" = "HSB",
  "Sunshine Coast (Langdale)" = "LAN",
  "Nanaimo (Departure Bay)" = "NAN"
)

`%,,%` = function(a,b) paste(a,b)
`%,%`= function(a,b) paste0(a,b)

source("github.R", local = T)
source("token.R", local = T)
#source("make_table.R", local = T)
source("make_reactable.R", local = T)

#session_id = if_else(is_test_run, sample(c(22733055L, 2641081L), 1), as.integer(runif(1, 0, 10^8)))
session_id = if_else(is_test_run, 7070247, as.integer(runif(1, 0, 10^8)))
# note: the repo needs this: actions > general > workflow permissions > read and write

ui = page_sidebar(
  theme =  bs_theme(),
  useShinyjs(),
  title = "Because the BC Ferries Website Sucks",
  sidebar = sidebar(
    pickerInput("departure_terminal", "Departure Terminal", choices = names(terminals), selected = "Vancouver (Tsawwassen)", multiple = F),
    pickerInput("arrival_terminal", "Arrival Terminal", choices = names(terminals), selected = "Victoria (Swartz Bay)", multiple = F),
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
  
  
  observe({
    accordion_panel_update(id = "accordion", target = "outbound_panel", title = HTML("<strong>Outbound</strong>:", input$departure_terminal, "==>", input$arrival_terminal))
    accordion_panel_update(id = "accordion", target = "return_panel", title = HTML("<strong>Return</strong>:", input$arrival_terminal, "==>", input$departure_terminal))
  })
  
  # card headers
  #output$header_outbound = renderText(paste("Outbound:", input$departure_terminal))
  #output$header_return = renderText(paste("Return:", input$arrival_terminal))
  
  
  # initialize reactive values
  github_file = reactiveVal(F)
  python_file = reactiveVal()
  sailings_tbl = reactiveVal()
  
  # show/hide return panel
  observeEvent(input$is_roundtrip, {
    if (input$is_roundtrip) {
      show("return_accordion")
      show("return_date")
    } else {
      hide("return_accordion")
      hide("return_date")
    }
  })
  
  # make df of all the sailings to search
  sailings = eventReactive(input$go, {
    df = crossing(is_outbound = T, departure_terminal = terminals[input$departure_terminal], arrival_terminal = terminals[input$arrival_terminal], date = input$departure_date + seq(-input$plusminus, input$plusminus))
    if (input$is_roundtrip) df = bind_rows(df, crossing(is_outbound = F, departure_terminal = terminals[input$arrival_terminal], arrival_terminal = terminals[input$departure_terminal], date = input$return_date + seq(-input$plusminus, input$plusminus)))
    df |>
      mutate(arr = case_when(is_outbound ~ abs(date - input$departure_date), T ~ abs(date - input$return_date))) |>
      arrange(arr, desc(is_outbound), desc(date)) |>
      select(-arr)
  })
  
  # commit to github
  observeEvent(input$go, {
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
    github_file = reactiveVal(F)
    python_file = reactiveVal()
    showSpinner("outbound_tbl")
    showSpinner("return_tbl")
    
    for (i in 1:(nrow(sailings()))) {
      while (T) {
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
            mutate(fare = as.double(str_remove(fare, "\\$"))) |>
            bind_cols(sailings()[i, ]) |>
            python_file()
            sailings_tbl(bind_rows(sailings_tbl(), python_file()))
            break
        }, error = function(e) {
          print("nope")
          Sys.sleep(4)
        })
      }
    }
  })
  
  
  output$outbound_tbl = renderReactable({
    req(sailings_tbl())
    make_reactable(sailings_tbl(), T, input$date)
  })
  
  output$return_tbl = renderReactable({
    req(sailings_tbl())
    if (nrow(filter(sailings_tbl(), is_outbound == F)) > 0) make_reactable(sailings_tbl(), F, input$return_date)
  })
  
  
}

shinyApp(ui = ui, server = server)
