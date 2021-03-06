googleAnalyticsModelR
=====================

Creating ready made models to work with `googleAnalyticsR` data

Setup
-----

    install.packages(c("remotes","googleAnalyticsR"))
    remotes::install_github("IronistM/googleAnalyticsModelR")

Useage
------

For end users, they can just load the model then apply it to their data:

    library(googleAnalyticsR)  # assume auto-authentication
    library(googleAnalyticsModelR)

    # fetches data and outputs decomposition
    my_viewid <- 81416156
    decomp_ga <- "inst/models/decomp_ga.gamr"
    d1 <- ga_model(my_viewid, model = decomp_ga)

![](README_files/figure-markdown_strict/unnamed-chunk-1-1.png)

    #repeat with another viewId
    d2 <- ga_model(123875646, model = decomp_ga)

![](README_files/figure-markdown_strict/unnamed-chunk-1-2.png)

    # Example CausalImpact
    ci <- ga_model(81416156, model = "inst/models/causalImpact_model.gamr", 
             event_date = Sys.Date() - 51, 
             predictors = "Direct", 
             response = "Organic Search")

![](README_files/figure-markdown_strict/unnamed-chunk-1-3.png)

Forecasting example with prophet
--------------------------------

The model loading can itself be done in a function, until the final end
user works with data like:

    library(prophet)
    library(dygraphs)
    library(googleAnalyticsR)

    forecast_data <- ga_model_prophet(81416156,
                       date_range = c(Sys.Date() - 400, Sys.Date() - 1),
                       forecast_days = 30,
                       metric = "sessions",
                       dim_filter=NULL,
                       interactive_plot = FALSE)
    print(forecast_data$plot)

![](README_files/figure-markdown_strict/unnamed-chunk-2-1.png)

Creating model `.gamr` objects
------------------------------

To create your own models, you need to predefine all the functions to
look after the fetching, modelling and viewing of the data. You then
pass those functions to the `ga_model_make()` function.

The functions need to follow these specifications:

-   `data_f` - A function to collect the data you will need. The first
    argument should be the `view_id` which will be pass the viewId of
    Google Analytics property to fetch data from.
-   `model_f` - A function to work with the data you have fetched. The
    first argument should be the data.frame that is produced by the data
    fetching function, `data_f()`.
-   `output_f` - A function to plot the data. The first argument should
    be the data.frame that is produced by the model function,
    `model_f()`.
-   All functions you create must include `...` as an argument.
-   All functions must use different arguments (apart from `...`), to
    avoid clashes.

If you want to also create the Shiny modules, then you also need to
specify: \* `outputShiny` - the output function for the UI, such as
`plotOutput` \* `renderShiny` - the render function for the server, such
as `renderPlot`

You then supply supporting information to make sure the user can run the
model:

-   `required_columns` - Specification of which columns the data will
    fetch. It will fail if they are not present.
-   `required_packages` - The packages the end user needs to have
    installed to run your functions.
-   `description` - A sentence on what the model is so they can be
    distinguished.

To create the example model above, the above was applied as shown below:

    get_model_data <- function(viewId,
                               date_range = c(Sys.Date()- 300, Sys.Date()),
                               ...){
       google_analytics(viewId,
                        date_range = date_range,
                        metrics = "sessions",
                        dimensions = "date",
                        max = -1)
     }

    decompose_sessions <- function(df, ...){
       decompose(ts(df$sessions, frequency = 7))
     }
     
    decomp_ga <- ga_model_make(get_model_data,
                               required_columns = c("date", "sessions"),
                               model_f = decompose_sessions,
                               output_f = graphics::plot,
                               description = "Performs decomposition and creates a plot",
                               outputShiny = shiny::plotOutput,
                               renderShiny = shiny::renderPlot)

Advanced use
------------

The more arguments you provide to the model creation functions, the more
complicated it is for the end user, but the more flexible the model. It
is suggested making several narrow useage models is better than one
complicated one.

For instance, you could modify the above model to allow the end user to
specify the metric, timespan and seasonality of the decomposition:

    get_model_data <- function(viewId,
                               date_range = c(Sys.Date()- 300, Sys.Date()),
                               metric,
                               ...){
       o <- google_analytics(viewId,
                        date_range = date_range,
                        metrics = metric,
                        dimensions = "date",
                        max = -1)
        # rename the metric column so its found for modelling
        o$the_metric <- o[, metric]
        
        o
        
     }

    decompose_sessions <- function(df, frequency, ...){
       decompose(ts(df$the_metric, frequency = frequency))
     }
     
    decomp_ga_advanced <- ga_model_make(get_model_data,
                               required_columns = c("date"), # less restriction on column
                               model_f = decompose_sessions,
                               output_f = graphics::plot,
                               description = "Performs decomposition and creates a plot",
                               outputShiny = shiny::plotOutput,
                               renderShiny = shiny::renderPlot)

It would then be used via:

    result <- ga_model(81416156, decomp_ga_advanced, metric="users", frequency = 30)

![](README_files/figure-markdown_strict/unnamed-chunk-4-1.png)

    str(result, max.level = 1)

    ## List of 3
    ##  $ input :'data.frame':  301 obs. of  3 variables:
    ##   ..- attr(*, "totals")=List of 1
    ##   ..- attr(*, "minimums")=List of 1
    ##   ..- attr(*, "maximums")=List of 1
    ##   ..- attr(*, "rowCount")= int 301
    ##  $ output:List of 6
    ##   ..- attr(*, "class")= chr "decomposed.ts"
    ##  $ plot  : NULL

### Working with the model object

The model objects prints to console in a friendly manner:

    decomp_ga_advanced

    ## ==ga_model object==
    ## Description:  Performs decomposition and creates a plot 
    ## Data args:    viewId date_range metric 
    ## Input data:   date 
    ## Model args:   df frequency 
    ## Packages:

You can save and load model objects from a file. It is suggested to save
them with the `.gamr` suffix.

    # save model to a file
    ga_model_save(decomp_ga_advanced, filename = "my_model.gamr")

    # load model again
    ga_model_load("my_model.gamr")

You can use models directly from the file:

    ga_model(81416156, "my_model.gamr")

If you need to change parts of a model, `ga_model_edit()` lets you
change individual aspects:

    ga_model_edit(decomp_ga_advanced, description = "New description")

    ## ==ga_model object==
    ## Description:  New description 
    ## Data args:    viewId date_range metric 
    ## Input data:   date 
    ## Model args:   df frequency 
    ## Packages:

You can also pass it the filename, which will load, make the edit, then
save the model to disk again:

    ga_model_edit("my_model.gamr", description = "New description")

More complicated example
------------------------

CausalImpact example
--------------------

To make your own portable GA Effect, this model uses the CausalImpact
and dygraphs libraries to make a plot of your GA data.

This example model is available via `ga_model_example("ga-effect.gamr")`

    library(googleAnalyticsR)

    get_ci_data <- function(viewId, 
                            date_range = c(Sys.Date()-600, Sys.Date()),
                            ...){
      
      google_analytics(viewId, 
                       date_range = date_range,
                       metrics = "sessions",
                       dimensions = c("date", "channelGrouping"), 
                       max = -1)
    }

    # response_dim is the channel to predict.
    # predictors help with forecast
    do_ci <- function(df, 
                      event_date,
                      response = "Organic Search",
                      predictors = c("Video","Social","Direct"),
                      ...){
      
      message("CausalImpact input data columns: ", paste(names(df), collapse = " "))
      # restrict to one response 
      stopifnot(is.character(response), 
                length(response) == 1,
                assertthat::is.date(event_date),
                is.character(predictors))
      
      pivoted <- df %>% 
        tidyr::spread(channelGrouping, sessions)
      
      stopifnot(response %in% names(pivoted))
      
      ## create a time-series zoo object
      web_data_xts <- xts::xts(pivoted[-1], order.by = as.Date(pivoted$date), frequency = 7)
      
      pre.period <- as.Date(c(min(df$date), event_date))
      post.period <- as.Date(c(event_date + 1, max(df$date)))
      
      predictors <- intersect(predictors, names(web_data_xts))

      ## data in order of response, predictor1, predictor2, etc.
      model_data <- web_data_xts[,c(response,predictors)]
      
      # deal with names
      names(model_data) <- make.names(names(model_data))
      # remove any NAs
      model_data[is.na(model_data)] <- 0

      CausalImpact::CausalImpact(model_data,  pre.period, post.period)

    }

    dygraph_plot <- function(impact, event_date, ...){
      require(dygraphs)
      ## the data for the plot is in here
      ci <- impact$series
      
      ci <- xts::xts(ci)

      ## the dygraph output
      dygraph(data=ci[,c('response', 'point.pred', 'point.pred.lower', 'point.pred.upper')], 
              main="Expected (95% confidence level) vs Observed", group="ci") %>%
        dyEvent(x = event_date, "Event") %>%
        dySeries(c('point.pred.lower', 'point.pred','point.pred.upper'), 
                 label='Expected') %>%
        dySeries('response', label="Observed")
    }

    req_packs <- c("CausalImpact", "xts", "tidyr", "googleAnalyticsR", "assertthat", "dygraphs")

    ci_model <- ga_model_make(get_ci_data,
                              required_columns = c("date","channelGrouping","sessions"),
                              model_f = do_ci,
                              output_f = dygraph_plot,
                              required_packages = req_packs,
                              description = "Causal Impact on channelGrouping data",
                              outputShiny = dygraphs::dygraphOutput,
                              renderShiny = dygraphs::renderDygraph)
    # print out model details
    ci_model

    ## ==ga_model object==
    ## Description:  Causal Impact on channelGrouping data 
    ## Data args:    viewId date_range 
    ## Input data:   date channelGrouping sessions 
    ## Model args:   df event_date response predictors 
    ## Packages:     CausalImpact xts tidyr googleAnalyticsR assertthat dygraphs

    # save it to a file for use later
    ga_model_save(ci_model, "causalImpact_model.gamr")

To use:

    library(googleAnalyticsR)
    library(xts)
    library(tidyr)
    library(dygraphs)

    ci <- ga_model(81416156, ci_model, event_date = as.Date("2019-01-01"))

Similarly, you can launch this in a Shiny app by slightly modifying the
example above.

This is available within the package via
`shiny::runApp(system.file("shiny/models-ga-effect", package="googleAnalyticsR"))`

### Using model objects within functions

You can go more meta by encasing the model definition and use in another
function. This is used by this example of [Dartistic's example "Time
normalised
pageviews"](http://www.dartistics.com/googleanalytics/int-time-normalized.html)
by Tim Wilson.

To use the end result:

    library(googleAnalyticsR)
    library(googleAnalyticsModelR)

    output <- ga_time_normalised(81416156, interactive_plot = FALSE)
    print(output$plot)

![](README_files/figure-markdown_strict/unnamed-chunk-9-1.png)

`ga_time_normalised()` wraps a call to `ga_model()`;

    #' Time normalised traffic
    #'
    #' Based on \url{http://www.dartistics.com/googleanalytics/int-time-normalized.html} by Tim Wilson
    #'
    #' @param viewId The viewId to use
    #' @param first_day_pageviews_min threshold for first day of content
    #' @param total_unique_pageviews_cutoff threshold of minimum unique pageviews
    #' @param days_live_range How many days to show
    #' @param page_filter_regex Select which pages to appear
    #' @param interactive_plot Whether to have a plotly or ggplot output
    #'
    #' @return A \link[googleAnalyticsR]{ga_model} object
    #'
    #' @export
    #' @importFrom googleAnalyticsR ga_model_load ga_model
    ga_time_normalised <- function(viewId,
                                   first_day_pageviews_min = 2,
                                   total_unique_pageviews_cutoff = 500,
                                   days_live_range = 60,
                                   page_filter_regex = ".*",
                                   interactive_plot = TRUE){

      model <- ga_model_load(filename = "inst/models/time-normalised.gamr")

      ga_model(viewId,
               model,
               first_day_pageviews_min = first_day_pageviews_min,
               total_unique_pageviews_cutoff = total_unique_pageviews_cutoff,
               days_live_range = days_live_range,
               page_filter_regex = page_filter_regex,
               interactive_plot = interactive_plot)

    }

The model itself is created by issuing `make_time_normalised()` and
wraps the code ported from the Dartistics code example, putting it in
the right function formats:

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

      output_f <- function(ga_data_normalized, interactive_plot, ...){
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

        if(interactive_plot){
          return(ggplotly(gg))
        }

        gg

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

Say we now save this model to `"time-normalised.gamr"`.

You can use the module functions to turn it into a Shiny app:

In this case, we need to build the UI, and the input selections:

    library(shiny)             # R webapps
    library(gentelellaShiny)   # ui theme
    library(googleAuthR)       # auth login
    library(googleAnalyticsR) # get google analytics

    # the libraries needed by the model
    library(dplyr)
    library(plotly)
    library(scales)
    library(ggplot2)
    library(purrr)

    # set your GCP project for the auth
    gar_set_client(web_json = "your-client-web.json",
                   scopes = "https://www.googleapis.com/auth/analytics.readonly")

    model <- ga_model_load(filename = "time-normalised.gamr")

    ui <- gentelellaPage(
      menuItems = list(sideBarElement(googleAuthUI("auth_menu"))),
      title_tag = "GA Time Normalised Pages",
      site_title = a(class="site_title", icon("phone"), span("Time normalised")),
      footer = "Made in Denmark",

      # shiny UI elements
      column(width = 12, authDropdownUI("auth_dropdown", inColumns = TRUE)),
      numericInput("first_day", "First day minimum pageviews", value = 2, min=0, max=100),
      numericInput("total_min_cutoff", "Minimum Total pageviews", value = 500, min = 0, max = 1000),
      numericInput("days_live", label = "Days Live", value = 60, min = 10, max = 400),
      textInput("page_regex", label = "Page filter regex", value = ".*"),
      h3("Time Normalised pages"),
      model$shiny_module$ui("model1"),
      br()

    )

    server <- function(input, output, session) {

      gar_shiny_auth(session)

      al <- reactive(ga_account_list())

      # module for authentication
      view_id <- callModule(authDropdown, "auth_dropdown", ga.table = al)

      callModule(model$shiny_module$server,
                 "model1",
                 view_id = view_id,
                 first_day_pageviews_min = reactive(input$first_day),
                 total_unique_pageviews_cutoff = reactive(input$total_min_cutoff),
                 days_live_range = reactive(input$days_live),
                 page_filter_regex = reactive(input$page_regex))

    }
    # Run the application
    shinyApp(gar_shiny_ui(ui, login_ui = silent_auth), server)
