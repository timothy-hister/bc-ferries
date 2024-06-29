pacman::p_load(rvest, tidyverse)
session = session("https://www.bcferries.com/RouteSelectionPage")

forms = html_form(session)
farefinder = forms[[2]]

farefinder = farefinder %>%
  html_form_set(
    routeInfoForm.departureLocationName = "Vancouver (Tsawwassen)",
    routeInfoForm.departureLocation = "TSA",
    routeInfoForm.arrivalLocationName = "Victoria (Swartz Bay)",
    routeInfoForm.arrivalLocation = "VSB",
    routeInfoForm.departingDateTime
 = "03/20/2024")

resp = html_form_submit(farefinder)
#session = session_submit(session, farefinder)
session = session %>% session_jump_to("https://www.bcferries.com/PassengerSelectionPage")

forms = html_form(session)
farefinder = forms[[2]]
farefinder = html_form_set(farefinder, "passengerInfoForm.passengerTypeQuantityList[0].quantity" = 1)
resp = html_form_submit(farefinder)

session = session_submit(session, farefinder)


session = session %>% session_jump_to("https://www.bcferries.com/VehicleSelectionPage")
forms = html_form(session)
farefinder = forms[[2]]
farefinder = html_form_set(farefinder, "vehicleInfoForm.vehicleInfo[0].height" = 1,
"vehicleInfoForm.vehicleInfo[0].length" = 1
)
session = session_submit(session, farefinder)
resp = html_form_submit(farefinder)



session = session %>% session_jump_to("https://www.bcferries.com/fare-selection")

session %>% read_html() %>% html_text2()
session %>% html_table()
session %>% read_html() %>% html_table()

html_form(session)

resp %>% read_html() %>% html_text2()
resp %>% read_html() %>% html_table()
resp %>% html_elements("ul") %>% html_text2()


forms = html_form(session)
session = session_submit(session, forms[[2]])
