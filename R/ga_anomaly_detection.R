#'
#' A function to perform Anomaly Detection
#' This is based on Twitter's package
#' @param df Data frame
#' @param time_col Column that has time data. We assume this is either `date`, `datehour`` from Google Analytics API
#' @param value_col Column that has value data
#' @param time_unit Time unit for aggregation.
#' @param fun.aggregate Function to aggregate values.
#' @param direction Direction of anomaly. Positive ("posi"), Negative ("neg") or "both".
#' @param longterm Increase anom detection efficacy for time series that are greater than a month.
#' This automatically becomes TRUE if the data is longer than 30 days.
#' @param e_value Whether expected values should be returned.
#' @param na_fill_type - Type of NA fill:
#'                       "previous" - Fill with previous non-NA value.
#'                       "value" - Fill with the value of na_fill_value.
#'                       "interpolate" - Linear interpolation.
#'                       "spline" - Spline interpolation.
#'                       NULL - Skip NA fill. Use this only when you know there is no NA.
#' @param na_fill_value - Value to fill NA when na_fill_type is "value"
#' @param ... extra values to be passed to AnomalyDetection::AnomalyDetectionTs.
#' @export
#' @importFrom exploratory do_anomaly_detection_
ga_check_anomaly <- function(...,
                          df = NULL,
                          time_col = 'date',
                          value_col = NULL,
                          title = NULL,
                          anoms = 0.02,
                          direction = direction,
                          piecewise_median_period_wk = NULL,
                          y_log = y_log,
                          longterm = NULL) {

  if("date" %in% colnames(df)){
    # modify date column to Date object from integer like 20140101
    loadNamespace("lubridate")
    df <- df %>% dplyr::mutate( date = lubridate::ymd(date) )
    time_unit <- 'day'
  }

  if("dateHour" %in% colnames(df)){
    # modify date column to POSIXct object from integer like 2014010101
    loadNamespace("lubridate")
    df <- df %>% dplyr::mutate(dateHour = lubridate::ymd_h(dateHour) )
    time_unit <- 'hour'
  }

  # now we can use `do_anomaly_detection` from exploratory
  exploratory::do_anomaly_detection_(df, time_col, value_col, ...)
}
