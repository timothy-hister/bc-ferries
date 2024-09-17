with_tooltip <- function(value, tooltip, ...) {
  div(style = "text-decoration: underline; text-decoration-style: dotted; cursor: help",
      tippy(scales::label_currency(accuracy=.01)(value), tooltip, allowHTML = T))
}


create_flexible_style <- function(min_value, max_value, italic_column = NULL, alpha = 0.3) {
  base_palette <- brewer.pal(11, "RdYlGn")
  transparent_palette <- sapply(base_palette, function(color) {
    rgb_values <- col2rgb(color)
    rgb(rgb_values[1], rgb_values[2], rgb_values[3], alpha = alpha * 255, maxColorValue = 255)
  })
  palette <- colorRampPalette(transparent_palette)(100)
  
  function(value, index, name, id) {
    if (is.na(value) || !is.numeric(value)) return(NULL)
    
    normalized <- (value - min_value) / (max_value - min_value)
    color_index <- round(normalized * 99) + 1
    background_color <- palette[color_index]
    
    style <- list(
      background = background_color,
      color = "black",  # Changed to always black due to transparency
      fontWeight = "bold",
      padding = "0.5rem",
      borderRadius = "4px"
    )
    
    if (!is.null(italic_column) && name == italic_column) {
      style$fontStyle <- "italic"
    }
    
    style
  }
}

make_reactable = function(sailings_tbl, is_outbound, highlight_col) {
  #browser()
  
  sailings_df = sailings_tbl |>
    filter(is_outbound) |>
    select(date, depart_time, fare) |>
    pivot_wider(names_from = date, values_from = fare) |>
    arrange(parse_time(depart_time))
  
  min_amount <- min(sailings_tbl$fare, na.rm = TRUE)
  max_amount <- max(sailings_tbl$fare, na.rm = TRUE)
  
  highlight_col = format.Date(highlight_col, format = "%a, %b %d")
  
  style_func <- create_flexible_style(min_amount, max_amount, highlight_col)
  
  colDefs = lapply(names(sailings_df)[2:ncol(sailings_df)], function(col_name) {
    colDef(
      #style = style_func
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
  
  #print(sailings_df)
  
  sailings_df |>
    set_names(c("Depart Time", format.Date(names(sailings_df)[-1], format = "%a, %b %d"))) |>
    reactable(
      defaultColDef = colDef(),
      columns = colDefs,
      defaultPageSize = 100L,
      bordered = T
    )
}