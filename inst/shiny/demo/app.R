library(shiny)
library(googleAuthR)
library(googleAnalyticsR)
library(googleAnalyticsModelR)

googleAuthR::gar_set_client(scopes = "https://www.googleapis.com/auth/analytics.readonly")

decomp_model <- ga_model_load("decomp_ga.gamr")

## ui.R
ui <- fluidPage(title = "googleAnalyticsR Model Shiny Demo",
                authDropdownUI("picker"),
                textOutput("view_id"),
                h1("Decomp Model"),
                decomp_model$shiny_module$ui("demo1")
)

## server.R
server <- function(input, output, session){

  # create a non-reactive access_token as we should never get past this if not authenticated
  gar_shiny_auth(session)

  view_id <- callModule(authDropdown, "picker", ga.table = reactive(ga_account_list()))

  callModule(decomp_model$shiny_module$server, "demo1", view_id = view_id)

  output$view_id <- renderText(view_id())

}

shinyApp(gar_shiny_ui(ui, login_ui = gar_shiny_login_ui), server)
