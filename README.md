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

    library(googleAnalyticsR)
    library(googleAnalyticsModelR)

    # fetches data and outputs decomposition
    my_viewid = 81416156
    model_location <- "inst/models/decomp_ga.gamodel"
    decomp <- ga_model(my_viewid, model = model_location)
    plot(decomp$d)

![](README_files/figure-markdown_strict/unnamed-chunk-1-1.png)

Creating models
---------------

It needs:

-   A function to collect the data you will need
-   A function to work with the data you have fetched
-   Specification of which R libraries the functions need

The functions need to not use the same arguments, and both include `...`
as the dots are shared between them.

    library(googleAnalyticsR)
    library(googleAnalyticsModelR)

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
       web_data_ts <- ts(df$sessions, frequency = 7)
       d <- decompose(web_data_ts)
       list(decom = d, plot = plot(d))
     }
     
     decomp_ga <- ga_model_make(get_model_data,
                                required_columns = c("date", "sessions"),
                                model_f = decompose_sessions,
                                description = "Performs decomposition on session data and creates a plot")
                                )
     
     # fetches data and outputs decomposition
     ga_model(81416156, decomp_ga)
     
     # save the model for later
     model_location <- "inst/models/decomp_ga.gamodel"
     ga_model_save(decomp_ga, filename = model_location)
     
     # can load model from file
     ga_model(81416156, model_location)
     
     # load model and use again
     model2 <- ga_model_load(model_location)
     
     ga_model(81416156, model2)
