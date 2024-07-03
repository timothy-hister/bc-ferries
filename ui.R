ui = page_sidebar(
  shinyjs::useShinyjs(),
  title = "Because the BC Ferries Website Sucks",
  
  sidebar = sidebar(
    useShinyjs(),
    pickerInput("departure", "Departure", choices = codes$long_name, multiple = F),
    pickerInput("arrival", "Arrival", choices = codes$long_name, multiple = F),
    prettySwitch("roundtrip", "Roundtrip?", value = T),
    airDatepickerInput("date", "Select Your Date", minDate = today(), value = today() + 1),
    airDatepickerInput("return_date", "Select Your Return Date", minDate = today(), value = today() + 1),
    sliderInput("plusminus", "How many days before/after do you wanna search?", min = 0, max = 10, value = 2),
    actionBttn("search", "Search Sailings!")
  )
  
  # accordion(
  #   id = "accordion",
  #   open = c("First Leg"),
  #   accordion_panel("First Leg", reactableOutput("first_leg") %>% withSpinner(), value = "panel1"
  #   ),
  #   accordion_panel("Return Leg", reactableOutput("return_leg") %>% withSpinner(), value = "panel2"
  #   )
  # )
)