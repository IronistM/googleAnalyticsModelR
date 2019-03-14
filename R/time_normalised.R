#' Time normalised traffic
#'
#' Based on \url{http://www.dartistics.com/googleanalytics/int-time-normalized.html} by Tim Wilson
#'
#' @param viewId The viewId to use
#' @param first_day_pageviews_min threshold for first day of content
#' @param total_unique_pageviews_cutoff threshold of minimum unique pageviews
#' @param days_live_range How many days to show
#' @param page_filter_regex Select which pages to appear
#'
#' @return A \link[googleAnalyticsR]{ga_model} object
#'
#' @export
#' @importFrom googleAnalyticsR ga_model_load ga_model
ga_time_normalised <- function(viewId,
                               first_day_pageviews_min = 2,
                               total_unique_pageviews_cutoff = 500,
                               days_live_range = 60,
                               page_filter_regex = ".*"){

  model <- ga_model_load(filename = "inst/models/time-normalised.gamr")

  ga_model(viewId,
           model,
           first_day_pageviews_min = first_day_pageviews_min,
           total_unique_pageviews_cutoff = total_unique_pageviews_cutoff,
           days_live_range = days_live_range,
           page_filter_regex = page_filter_regex)

}

#' Run this manually when you want to alter the saved model
#' @noRd
make_time_normalised <- function(){

  data_f <- function(viewId, page_filter_regex, ...){
    page_filter_object <- dim_filter("pagePath",
                                     operator = "REGEXP",
                                     expressions = page_filter_regex)
    page_filter <- filter_clause_ga4(list(page_filter_object),
                                     operator = "AND")

    google_analytics(viewId = viewId,
                     date_range = c(Sys.Date() - 365, Sys.Date() - 1),
                     metrics = "uniquePageviews",
                     dimensions = c("date","pagePath"),
                     dim_filters = page_filter,
                     anti_sample = TRUE)

  }
  model_f <- function(ga_data,
                      first_day_pageviews_min,
                      total_unique_pageviews_cutoff,
                      days_live_range,
                      ...){
    normalize_date_start <- function(page){
      ga_data_single_page <- ga_data %>% filter(pagePath == page)
      first_live_row <- min(which(ga_data_single_page$uniquePageviews > first_day_pageviews_min))
      ga_data_single_page <- ga_data_single_page[first_live_row:nrow(ga_data_single_page),]
      normalized_results <- data.frame(date = seq.Date(from = min(ga_data_single_page$date),
                                                       to = max(ga_data_single_page$date),
                                                       by = "day"),
                                       days_live = seq(min(ga_data_single_page$date):
                                                         max(ga_data_single_page$date)),
                                       page = page) %>%
        left_join(ga_data_single_page) %>%
        mutate(uniquePageviews = ifelse(is.na(uniquePageviews), 0, uniquePageviews)) %>%
        mutate(cumulative_uniquePageviews = cumsum(uniquePageviews)) %>%
        select(page, days_live, uniquePageviews, cumulative_uniquePageviews)
    }

    pages_list <- ga_data %>%
      group_by(pagePath) %>% summarise(total_traffic = sum(uniquePageviews)) %>%
      filter(total_traffic > total_unique_pageviews_cutoff)

    ga_data_normalized <- map_dfr(pages_list$pagePath, normalize_date_start)

    ga_data_normalized %>% filter(days_live <= days_live_range)
  }

  output_f <- function(ga_data_normalized, ...){
    gg <- ggplot(ga_data_normalized,
                 mapping=aes(x = days_live, y = cumulative_uniquePageviews, color=page)) +
      geom_line() +                                          # The main "plot" operation
      scale_y_continuous(labels=comma) +                     # Include commas in the y-axis numbers
      labs(title = "Unique Pageviews by Day from Launch",
           x = "# of Days Since Page Launched",
           y = "Cumulative Unique Pageviews") +
      theme_light() +                                        # Clean up the visualization a bit
      theme(panel.grid = element_blank(),
            panel.border = element_blank(),
            legend.position = "none",
            panel.grid.major.y = element_line(color = "gray80"),
            axis.ticks = element_blank())

    ggplotly(gg)
  }
  required_columns <- c("date","pagePath","uniquePageviews")
  required_packages <- c("plotly", "scales", "dplyr", "purrr", "ggplot2")

  model <- ga_model_make(
    data_f = data_f,
    required_columns = required_columns,
    model_f = model_f,
    output_f = output_f,
    required_packages = required_packages,
    description = "Cumalitive visualisation of time-normalised traffic",
    outputShiny = plotly::plotlyOutput,
    renderShiny = plotly::renderPlotly
  )

  ga_model_save(model, filename = "inst/models/time-normalised.gamr")

  model

}
