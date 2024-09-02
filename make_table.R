make_table = function(py_list) {

  all_df =  suppressWarnings(suppressMessages(py_list |>
    map(\(x) str_split(x[[4]], "\n") |> 
          map(\(y) y[c(2, 5, 6, 8)] |> 
                t() |> 
                as_tibble(.name_repair = 'minimal')
          ) |> 
          bind_rows() |> 
          mutate(date = x[[3]]) |> 
          set_names("depart_time", "arrive_time", "vessel", "cost", "date") |>
          mutate(cost = as.double(str_replace(cost, "\\$", ""))) |>
          mutate(date = ymd(date))
    )))
  
  which_outbound = map_lgl(py_list, \(x) x[[1]][[1]] == py_list[[1]][[1]])
  
  outbound_cost =  all_df |>
    bind_rows() |>
    select(date, depart_time, cost) |>
    pivot_wider(names_from = date, values_from = cost)
  
  outbound_vessel =  all_df |>
    bind_rows() |>
    select(date, depart_time, vessel) |>
    pivot_wider(names_from = date, values_from = vessel)
  
  return_cost = if (all(which_outbound)) NULL else all_df[!which_outbound] |>
    bind_rows() |>
    select(date, depart_time, cost) |>
    pivot_wider(names_from = date, values_from = cost)
  
  return_vessel = if (all(which_outbound)) NULL else all_df[!which_outbound] |>
    bind_rows() |>
    select(date, depart_time, vessel) |>
    pivot_wider(names_from = date, values_from = vessel)
  
  print("table made!")
  
  return(list(outbound_cost, outbound_vessel, return_cost, return_vessel))
  
}
