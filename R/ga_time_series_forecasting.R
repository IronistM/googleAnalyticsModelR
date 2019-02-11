#'
#' Forecast time series data using Facebook's Prophet API
#' @param df - Data frame
#' @param time_col - Column that has time data
#' @param value_col - Column that has value data
#' @param periods - Number of time periods (e.g. days. unit is determined by time_unit) to forecast.
#' @param time_unit - "second"/"sec", "minute"/"min", "hour", "day", "week", "month", "quarter", or "year".
#' @param include_history - Whether to include history data in forecast or not.
#' @param fun.aggregate - Function to aggregate values.
#' @param na_fill_type - Type of NA fill:
#'                       NULL - Skip NA fill. Default behavior.
#'                       "previous" - Fill with previous non-NA value.
#'                       "value" - Fill with the value of na_fill_value.
#'                       "interpolate" - Linear interpolation.
#'                       "spline" - Spline interpolation.
#' @param na_fill_value - Value to fill NA when na_fill_type is "value"
#' @param ... - extra values to be passed to prophet::prophet. listed below.
#' @param growth - This parameter used to specify type of Trend, which can be "linear" or "logistic",
#'        but now we determine this automatically by cap. It is here just to avoid throwing error from prophet,
#'        (about doubly specifying grouth param by our code and by "...") when old caller calls with this parameter.
#' @param cap - Achievable Maximum Capacity of the value to forecast.
#'        https://facebookincubator.github.io/prophet/docs/forecasting_growth.html
#'        It can be numeric or data frame. When numeric, the value is used as cap for both modeling and forecasting.
#'        When it is a data frame, it should be a future data frame with cap column for forecasting.
#'        When this is specified, the original data frame (df) should also have cap column for modeling.
#'        When either a numeric or a data frame is specified, growth argument for prophet becomes "logistic",
#'        as opposed to default "linear".
#' @param seasonality.prior.scale - Strength of seasonality. Default is 10.
#' @param yearly.seasonality - Whether to return yearly seasonality data.
#' @param weekly.seasonality - Whether to return weekly seasonality data.
#' @param n.changepoints - Number of potential changepoints. Default is 25.
#' @param changepoint.prior.scale - Flexibility of automatic changepoint selection. Default is 0.05.
#' @param changepoints - list of potential changepoints.
#' @param holidays.prior.scale - Strength of holiday effect. Default is 10.
#' @param holidays - Holiday definition data frame.
#' @param mcmc.samples - MCMC samples for full bayesian inference. Default is 0.
#' @param interval.width - Width of uncertainty intervals.
#' @param uncertainty.samples - Number of simulations made for calculating uncertainty intervals. Default is 1000.
#' @export
#' @importFrom exploratory do_prophet
ga_prophet_forecast <-
  function(df,
           time_col,
           value_col = NULL,
           periods = 10,
           time_unit = "day",
           include_history = TRUE,
           test_mode = FALSE,
           fun.aggregate = sum,
           na_fill_type = NULL,
           na_fill_value = 0,
           cap = NULL,
           floor = NULL,
           growth = NULL,
           weekly.seasonality = TRUE,
           yearly.seasonality = TRUE,
           holiday_col = NULL,
           holidays = NULL,
           regressors = NULL,
           funs.aggregate.regressors = NULL,
           ...) {
    # Make sure we a date or datetime column is formatted as expected
    if("date" %in% colnames(df)){
      # modify date column to Date object from integer like 20140101
      loadNamespace("lubridate")
      df <- df %>% dplyr::mutate( date = lubridate::ymd(date))
    }

    if("dateHour" %in% colnames(df)){
      # modify date column to POSIXct object from integer like 2014010101
      loadNamespace("lubridate")
      df <- df %>% dplyr::mutate(dateHour = lubridate::ymd_h(dateHour))
    }

    # now we can use `do_anomaly_detection` from exploratory
    if(require("prophet")){
      exploratory::do_prophet(df, time_col, value_col, ...)
    } else {
      stop("library(prophet) not available")
    }

  }
