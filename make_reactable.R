with_tooltip <- function(value, tooltip, ...) {
  div(style = "text-decoration: underline; text-decoration-style: dotted; cursor: help",
      tippy(scales::label_currency(accuracy=.01)(value), tooltip, allowHTML = T))
}


create_color_scale <- function(min_value, max_value) {
  palette <- colorRampPalette(brewer.pal(11, "RdYlGn"))(100)
  
  function(value) {
    if (is.na(value)) return(NULL)
    
    normalized <- (value - min_value) / (max_value - min_value)
    color_index <- round(normalized * 99) + 1
    background_color <- palette[color_index]
    
    list(
      background = background_color,
      color = if (normalized < 0.5) "black" else "white",
      fontWeight = "bold",
      padding = "0.3rem",
      borderRadius = "4px"
    )
  }
}

make_reactable = function(sailings_tbl, is_outbound) {
  sailings_df = sailings_tbl |>
    filter(is_outbound) |>
    select(date, depart_time, fare) |>
    pivot_wider(names_from = date, values_from = fare) |>
    arrange(parse_time(depart_time))
  
  min_amount <- min(sailings_tbl$fare, na.rm = TRUE)
  max_amount <- max(sailings_tbl$fare, na.rm = TRUE)
  
  colDefs = lapply(names(sailings_df)[2:ncol(sailings_df)], function(col_name) {
    colDef(
      style = create_color_scale(min_amount, max_amount),
      cell = function(value, index, id) with_tooltip(value,
    "Date:" %,,% col_name %,%
    "<br>Departure Time:" %,,% sailings_df[[index, 1]] %,%
    "<br>Arrival Time:" %,,% pull(filter(sailings_tbl, is_outbound, depart_time == sailings_df[[index, 1]], date == col_name), arrive_time) %,%
    "<br>Vessel:" %,,% pull(filter(sailings_tbl, is_outbound, depart_time == sailings_df[[index, 1]], date == col_name), vessel) %,%
    "<br>Fare:" %,,% scales::label_currency(accuracy=.01)(value)
      )
    )
  }) |>
    set_names(names(sailings_df)[2:ncol(sailings_df)] |> format.Date(format = "%a, %b %d"))
  
  sailings_df |>
    set_names(c("Depart Time", format.Date(names(sailings_df)[-1], format = "%a, %b %d"))) |>
    reactable(
      columns = colDefs,
      defaultPageSize = 100L,
      bordered = T
    )
}