pacman::p_load(shiny, bslib, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs, gh, httr2, jsonlite, fs)

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

session_id = as.integer(runif(1, 0, 10^8))
# note: the repo needs this: actions > general > workflow permissions > read and write

ui = page_sidebar(
  theme =  bs_theme(),
  useShinyjs(),
  title = "Because the BC Ferries Website Sucks",
  sidebar = sidebar(
    pickerInput("departure", "Departure", choices = berths, selected = "Vancouver (Tsawwassen)", multiple = F),
    pickerInput("arrival", "Arrival", choices = berths, selected = "Victoria (Swartz Bay)", multiple = F),
    prettySwitch("roundtrip", "Roundtrip?", value = F),
    airDatepickerInput("date", "Select Your Date", minDate = today(), value = today() + 10),
    hidden(airDatepickerInput("return_date", "Select Your Return Date", minDate = today(), value = today() + 1)),
    sliderInput("plusminus", "How many days before/after do you wanna search?", min = 0, max = 10, value = 2),
    actionBttn("go", "Search Sailings!")
  ),
  accordion(
    id = "accordion", 
    accordion_panel(
    "Outbound",
    #reactableOutput("outbound") |> withSpinner()
    uiOutput("outbound_ui")
  ),
  accordion_panel( 
    "Return",
    value = "return_accordion",
    reactableOutput("return") |> withSpinner()
    )
  )
)

server = function(input, output, session) {
  github_file = reactiveVal(F)
  fileContent = reactiveVal()
  outputs = reactiveValues()
  
  observeEvent(input$roundtrip, if (input$roundtrip) {
    show("return_accordion")
    show("return_date")
  } else {
    hide("return_accordion")
    hide("return_date")
  })
  
  observeEvent(input$go, {
    github_file = reactiveVal(F)
    fileContent = reactiveVal()
    outputs = reactiveValues()
  })
  
  # commit to the repo
  observeEvent(input$go, {
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
    
    all_df =  fileContent() |>
      map(\(x) str_split(x[[4]], "\n") |> 
            map(\(y) y[c(2, 5, 6, 8)] |> 
                  t() |> 
                  as_tibble()
            ) |> 
            bind_rows() |> 
            mutate(date = x[[3]]) |> 
            set_names("depart_time", "arrive_time", "vessel", "cost", "date") |>
            mutate(cost = as.double(str_replace(cost, "\\$", ""))) |>
            mutate(date = ymd(date))
      )
    
    which_outbound = map_lgl(fileContent(), \(x) x[[1]][[1]] == fileContent()[[1]][[1]])
    
    outbound_df = all_df[which_outbound] |>
      bind_rows() |>
      select(-arrive_time, -vessel) |>
      pivot_wider(names_from = date, values_from = cost)
    
    return_df = if (all(which_outbound)) NULL else all_df[!which_outbound] |> 
      bind_rows() |>
      select(-arrive_time, -vessel) |>
      pivot_wider(names_from = date, values_from = cost)
    
    outputs$outbound = outbound_df
    outputs$return = return_df
  })
  
  output$outbound = renderReactable({
    #req(outputs$outbound)
    reactable(outputs$outbound)
  })
  
  output$return = renderReactable({
    req(outputs$return)
    reactable(outputs$return)
  })
  
  output$outbound_ui = renderUI(if (github_file()) withSpinner(reactableOutput("t1")))
  
}

shinyApp(ui = ui, server = server)