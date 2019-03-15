#' A ga_model for prophet forecasting
#'
#' @param viewId The viewID of the Ga account to forecast from
#' @param date_range The date range of training data
#' @param forecast_days The amount of days forward to forecast
#' @param metric The metric to forecast
#' @param dim_filter A \link[googleAnalyticsR]{filter_clause_ga4} when fetching data
#' @param interactive_plot Whether to output an interactive plot or not
#'
#' @return A \link[googleAnalyticsR]{ga_model} object
#'
#' @export
#' @importFrom googleAnalyticsR ga_model_load ga_model
#'
#' @examples
#'
#' \dontrun{
#' library(prophet)
#' library(dygraphs)
#' library(googleAnalyticsR)
#'
#' ga_model_prophet(81416156)
#'
#' }
ga_model_prophet <- function(viewId,
                             date_range = c(Sys.Date() - 400, Sys.Date() - 1),
                             forecast_days = 30,
                             metric = "sessions",
                             dim_filter=NULL,
                             interactive_plot=FALSE){

  model <- ga_model_load(system.file("models", "prophet.gamr",
                                     package = "googleAnalyticsModelR"))

  ga_model(viewId,
           model,
           date_range = date_range,
           metric = metric,
           forecast_days = forecast_days,
           dim_filter = dim_filter,
           interactive_plot = interactive_plot)
}


#' Manually run to create the model object
#' @noRd
make_model_prophet <- function(){

  data_f <- function(viewId, date_range, metric, dim_filter, ...){

    o <- google_analytics(viewId = viewId,
                     date_range = date_range,
                     metrics = metric,
                     dimensions = "date",
                     dim_filters = dim_filter,
                     anti_sample = TRUE)

    o$ds <- o$date
    o$y <- o[[metric]]

    o[ , c("ds","y")]

  }
  model_f <- function(ga_data,
                      forecast_days,
                      ...){

    m <- prophet::prophet(ga_data)
    future <- prophet::make_future_dataframe(m, periods = forecast_days)

    forecast <- predict(m, future)

    list(
      forecast = forecast,
      model = m
    )

  }

  output_f <- function(model, interactive_plot, ...){

    if(interactive_plot){
      prophet::dyplot.prophet(model$model, model$forecast)
    } else {
      plot(model$model, model$forecast)
    }

  }
  required_columns <- c("y","ds")
  required_packages <- c("prophet", "dygraphs")

  model <- ga_model_make(
    data_f = data_f,
    required_columns = required_columns,
    model_f = model_f,
    output_f = output_f,
    required_packages = required_packages,
    description = "Prophet forecast for GA data",
    outputShiny = dygraphs::dygraphOutput,
    renderShiny = dygraphs::renderDygraph
  )

  ga_model_save(model, filename = "inst/models/prophet.gamr")

  model

}
