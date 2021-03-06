% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ga_model_prophet.R
\name{ga_model_prophet}
\alias{ga_model_prophet}
\title{A ga_model for prophet forecasting}
\usage{
ga_model_prophet(viewId, date_range = c(Sys.Date() - 400, Sys.Date() -
  1), forecast_days = 30, metric = "sessions", dim_filter = NULL,
  interactive_plot = FALSE)
}
\arguments{
\item{viewId}{The viewID of the Ga account to forecast from}

\item{date_range}{The date range of training data}

\item{forecast_days}{The amount of days forward to forecast}

\item{metric}{The metric to forecast}

\item{dim_filter}{A \link[googleAnalyticsR]{filter_clause_ga4} when fetching data}

\item{interactive_plot}{Whether to output an interactive plot or not}
}
\value{
A \link[googleAnalyticsR]{ga_model} object
}
\description{
A ga_model for prophet forecasting
}
\examples{

\dontrun{
library(prophet)
library(dygraphs)
library(googleAnalyticsR)

ga_model_prophet(81416156)

}
}
