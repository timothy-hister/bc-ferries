make_reactable = function(df_cost, df_vessel, today_col) {
  with_tooltip <- function(value, tooltip, ...) {
    div(style = "text-decoration: underline; text-decoration-style: dotted; cursor: help",
        tippy(scales::label_currency()(value), tooltip, ...))
  }
  
  colDefs = map(names(df_vessel)[2:ncol(df_vessel)], function(x) {
    colDef(
      cell = function(value, index) with_tooltip(value, df_vessel[[index, x]])
      #format = colFormat(currency = "USD")
    )
  }) |>
    set_names(names(df_vessel)[2:ncol(df_vessel)] |> format.Date(format = "%a, %b %d"))
  
  today_col = format.Date(today_col, format = "%a, %b %d")
  
  colDefs[[today_col]][['style']][['fontWeight']] = 600
  colDefs[[today_col]][['style']][['background']] = 'lightgray'
  colDefs[["depart_time"]][['header']] = ''
  
  df_cost |>
    set_names(c("depart_time", format.Date(names(df_cost)[-1], format = "%a, %b %d"))) |>
    reactable(
      defaultColDef = colDef(),
      columns = colDefs
    )
  
}
