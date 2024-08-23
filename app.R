pacman::p_load(shiny, bslib, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders, shinyjs, gh, httr2, jsonlite, reticulate)

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

session_id = as.integer(runif(1, 0, 10^8))
token = "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"
# note: the repo needs this: actions > general > workflow permissions > read and write

ui = page_sidebar(
  useShinyjs(),
  pickerInput("departure", "Departure", choices = berths, selected = "Vancouver (Tsawwassen)", multiple = F),
  pickerInput("arrival", "Arrival", choices = berths, selected = "Victoria (Swartz Bay)", multiple = F),
  prettySwitch("roundtrip", "Roundtrip?", value = T),
  airDatepickerInput("date", "Select Your Date", minDate = today(), value = today() + 10),
  airDatepickerInput("return_date", "Select Your Return Date", minDate = today(), value = today() + 1),
  sliderInput("plusminus", "How many days before/after do you wanna search?", min = 0, max = 10, value = 2),
  actionBttn("go", "Search Sailings!"),
  #reactableOutput("t1")
  textOutput("t1")
)

server = function(input, output, session) {
  
  # commit to the repo
  observeEvent(input$go, {
    list(
      session_id = session_id,
      departure = input$departure,
      arrival = input$arrival,
      date = input$date
    ) |>
      write_json("jsons/bcf_" %,% session_id %,% ".json")
    github_commit(
      repo = "bcftest", 
      branch = "main", 
      token = token, 
      file_path = "jsons/bcf_" %,% session_id %,% ".json", 
      message = "shiny_commit_" %,% session_id
    )
  })
  
  fileContent <- reactiveVal("Checking for file...")
  
  checkFile <- function() {
    response = tryCatch({
      "https://raw.githubusercontent.com/timothy-hister/bcftest/main/dfs/df_" %,% session_id %,% ".txt" |>
        httr2::request() |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        fileContent()
    }, error = function(e) fileContent("File not found or still being written...")
    )
  }
  
    
  observe({
    invalidateLater(5000, session)  # Check every 5 seconds
    checkFile()
  })
  
  
  output$t1 = renderText(fileContent())
  
  
  # output$t1 = renderReactable({
  #   y = fileContent() |> 
  #     str_split("DEPART") |>
  #     unlist() |>
  #     str_split("\n")
  #   
  #   z = map(y, function(x) keep(x, \(z) str_detect(z, "Spirit|Coastal|Queen|\\$|am$|pm$")))
  #   
  #   done = map(z, \(x) t(x) |> as_tibble(.name_repair)) |>
  #     bind_rows() |>
  #     na.omit() |>
  #     setNames(c("Departure Time", "Arrival Time", "Vessel", "Cost"))
  #   
  #   reactable(done)
  # })
  
}

shinyApp(ui = ui, server = server)