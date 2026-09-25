library(glue)
library(lubridate)
library(dplyr)
library(odbc)

Sys.setenv("MILESTONES_USE_SAMPLE" = 0) # uncomment for database
Sys.setenv("MILESTONES_USE_LUDIS" = 0)

team <- "'NSW Blues M'"
series <- 4
series_name <- "Aus Domestic OD M"
season <- "2025-26"

source("./milestone_def.R")
source("./select_choices.R")
source("./constants.R")

filters <- list(
  series = series,
  venue = NULL,
  team = NULL
)

source("./connection.R")
source("./auth.R")
source("./filters.R")
source("./lookups.R")
source("./local_data.R")
source("./milestone_helpers.R")
source("./email_milestone_helpers.R")
source("./email_query_builder.R")

enabled <- milestones_for_series(filters$series)

if(Sys.getenv("MILESTONES_USE_LUDIS") == 1) {
  con <- get_connection_ludis()
} else {
  con <- get_connection_local()
}


results <- purrr::map_df(seq_len(nrow(enabled)), function(i) {
  definition <- enabled[i, ]

  res <- tryCatch(
    execute_milestone_query(
      definition = definition,
      filters = filters,
      con = con
    ),
    error = function(e) NULL
  )

  res

})

source("./query_builders.R")

progress <- purrr::map_df(seq_len(nrow(enabled)), function(i) {
  definition <- enabled[i, ]
  
  res <- tryCatch(
    execute_milestone_query(
      definition = definition,
      filters = filters,
      con = con
    ),
    error = function(e) NULL
  )
  
  res
  
})



if (Sys.getenv("MILESTONES_USE_LUDIS") == 1) {
  query <- glue(
    "SELECT 
            [ams_id]
          FROM 
            [elite].[LISTS_contract_lists]
          WHERE
            team_id in {series} AND season = '{this_year}'"
  )
  
  team_list <- tryCatch(
    QueryDBFunction(con = con, query = query),
    error = function(e) NULL
  )
} else {
  query <- get_players_query(team, series, season)
  team_list <- tryCatch(
    QueryDBFunction(con = con, query = query),
    error = function(e) NULL
  )
}


source("./email_html.R")
message("Wrote player_milestone_update.html")


