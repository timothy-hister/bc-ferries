pacman::p_load(shiny, bslib, RSelenium, tidyverse, rvest, stringr, reactable, scales, shinyWidgets, shinycssloaders)

`%,,%` = function(a,b) paste(a,b)
`%,%`= function(a,b) paste0(a,b)
source("functions.R")  

codes = tribble(~long_name, ~short_name, ~code,
  "Vancouver (Tsawwassen)", "Vancouver (TSA)", "TSA",
  "Vancouver (Horseshoe Bay)", "Vancouver (HSB)", "HSB",
  "Victoria (Swartz Bay)", "Victoria (SWB)", "SWB",
  "Sunshine Coast (Langdale)", "Sunshine Coast (LNG)", "LNG",
  "Nanaimo (Departure Bay)", "Nanaimo (NAN)", "NAN"
)

route_codes = list(c(2, 4), c(1, 3), c(2, 5))

routes = c()
for (r in route_codes) {
  routes[length(routes) + 1] = codes$code[r][1] %,,% "=>" %,,% codes$code[r][2]
  routes[length(routes) + 1] = codes$code[r][2] %,,% "=>" %,,% codes$code[r][1]
}


ui <- page_sidebar(
  title = "Because the BC Ferries Website Sucks",
    
  sidebar = sidebar(
    pickerInput("routes", "Select Your Route(s)", choices = routes, multiple = T),
    airDatepickerInput("date", "Select Your Date", minDate = today(), value = today()),
    sliderInput("plusminus", "How many days before/after do you wanna search?", min = 0, max = 10, value = 0)
  ),
  
  uiOutput("acc") %>% withSpinner()
  #accordion(id="acc")
)

shinyApp(ui, function(input, output) {
  
  departures = eventReactive(input$routes, substr(input$routes, 1, 3))
  arrivals = eventReactive(input$routes, substr(input$routes, 8, 10))
  dates = reactive(seq.Date(from = input$date - input$plusminus, to = input$date + input$plusminus, by=1))
  
  output$acc = renderUI({
    #if (remote$getCurrentUrl() == "https://reservations.mybcf.com/planned-outage-sc-cc/") return("Maintenance. BC FERRIES YOU SUCK!")

    panels = list()
    
    if (is.null(input$routes)) return(NULL)
    
    for (route in input$routes) {
      
      departure = substr(route, 1, 3)
      arrival = substr(route, 8, 10)
      
      t = map(dates(), function(date) {
        print(route %,% ": " %,% date)
        selenium = seleniumize(departure, arrival, date)
        result = get_sailings(selenium, date)
        }) %>%
        bind_rows() %>%
        mutate(cost = dollar(cost)) %>%
        mutate(date = format(date, "%Y-%b-%d")) %>%
        pivot_wider(id_cols=date, names_from = depart, values_from = cost) %>%
        reactable()
      
      panels[[length(panels) + 1]] = accordion_panel(route, t)
      
      #panels = append(panels, accordion_panel(title = route))
      #print(acc)
      #ap = accordion_panel(route, route)
      #accordion_panel_insert('acc', ap)
    }
    accordion(panels, open = F)
  })
  
  
  # t = reactive({
  #   map(input$routes, function(route) {
  #     print(route)
  #     departure = substr(route, 1, 3)
  #     arrival = substr(route, 8, 10)
  #     
  #     map(dates(), function(date) {
  #       print(date)
  #       selenium = seleniumize(departure, arrivals, date)
  #       result = get_sailings(selenium, date)
  #     }) %>%
  #     bind_rows() %>%
  #     mutate(cost = dollar(cost)) %>%
  #     mutate(date = format(date, "%Y-%b-%d")) %>%
  #     pivot_wider(id_cols=date, names_from = depart, values_from = cost) %>%
  #     reactable()
  #   })
  # })
  
  
  # observeEvent(input$routes, {
  #   accordion_panel_remove(id='acc', target='1')
  #   for (route in input$routes) accordion_panel_insert(id = "acc", panel = accordion_panel(title = route), target = "1")
  # })
  
  # z = eventReactive(input$routes, map(input$routes, function(route) accordion_panel(title = route, value = route)))
  # 
  # output$acc = renderUI({
  #   accordion(z(), open = F)
  # })
  # 
  # accordion_panel_update(id = "acc", reactableOutput(cars), value=route)
  
  #accordions = reactive(list())
  
  # t = reactive({
  #   for (i in length(input$routes)) {
  #     map(dates()[i], function(date) {
  #       print(input$routes[i] %,,% date)
  #       selenium = seleniumize(departures()[i], arrivals()[i], date)
  #       result = get_sailings(selenium, date)
  #     }) %>%
  #     bind_rows() %>%
  #     mutate(cost = dollar(cost)) %>%
  #     mutate(date = format(date, "%Y-%b-%d")) %>%
  #     pivot_wider(id_cols=date, names_from = depart, values_from = cost) %>%
  #     reactable()
  #   }
  # })

  # accordions()[length(accordions()) + 1] = accordion_panel(
  #     title = input$routes[i],
  #     reactableOutput(t())
  #   )
  # 
  # output$cards = renderUI(accordion(accordions(), open=F))

# output$cards = renderUI({
#   accordions = map(input$routes, function(route) {
#     accordion_panel(
#       title = route,
#       reactableOutput("t_depart"),
#     )
#   })
#   accordion(accordions, open=F)
# })
    
})
