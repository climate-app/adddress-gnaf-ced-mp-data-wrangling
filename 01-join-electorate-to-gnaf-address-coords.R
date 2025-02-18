#' Join address coordinatee with electorate and MP id
#'
#' - Federal electorate shapefile - boundary coordinates
#' - Address coordinates - address id, coordinates
#' - MP details: electorate, MP id
#'

# Extract NSW from National shapefile ----
shp <-
  sf::read_sf(here::here('data/CED_2021_AUST_GDA2020_SHP/CED_2021_AUST_GDA2020.shp'))


# NSW ----
nsw_ced <-
  shp |>
  dplyr::select(CED_CODE21, CED_NAME21, STE_NAME21) |>
  dplyr::filter(STE_NAME21 == 'New South Wales')

nsw_ced |>
  dplyr::select(CED_NAME21) |>
  plot()

# MP information (theyvoteforyou) ----
apikey = ""

people <-
  readLines(
    paste0("https://theyvoteforyou.org.au/api/v1/people.json?key=", apikey),
    warn = F
  )

writeLines(people, 'data/theyvoteforyou/people.json')


people <-
  readLines('data/theyvoteforyou/people.json') |>
  jsonlite::fromJSON()

people <-
  tibble::tibble(
    MP_ID = people$id,
    MP_NAME = people$latest_member$name |>
      as.data.frame() |>
      dplyr::mutate(name = paste(first, last)) |>
      dplyr::pull(name),
    MP_ELECTORATE = people$latest_member$electorate
  )

# All electorates are obtained/present
nsw_ced |>
  sf::st_drop_geometry() |>
  dplyr::left_join(
    data.frame(
      CED_NAME21 = people$MP_ELECTORATE,
      tvfy = 1
    ),
    by = 'CED_NAME21'
  ) |>
  print(n = Inf) |>
  dplyr::filter(is.na(tvfy))

# Add electorate to address ----
addresses <-
  readr::read_csv(here::here('gnaf/gnaf-core-in-columns/gnaf-core-in-columns-nsw.csv')) |>
  dplyr::select(id, LATITUDE, LONGITUDE)

addresses_sf <-
  addresses |>
  sf::st_as_sf(coords = c(x = 'LONGITUDE', y = 'LATITUDE'), crs = sf::st_crs(nsw_ced))

my_st_intersects <- function(x, y, ...){
  result <- sf::st_intersects(x, y, ...)
  result[lengths(result) == 0] <- NA
  result
}

nsw_ced_row_ids <-
  my_st_intersects(x = addresses_sf, y = nsw_ced)

addresses$CED_NAME21 <-
  nsw_ced$CED_NAME21[unlist(nsw_ced_row_ids)]

addresses |>
  dplyr::filter(is.na(CED_NAME21))

missing_ced_update <-
  readr::read_csv('gnaf/gnaf-coords-to-electorate-and-mp/missing-ced-update.csv')

for(i in 1:nrow(missing_ced_update)){
  row_ind <- match(missing_ced_update$id[i], addresses$id)
  addresses$CED_NAME21[row_ind] <- missing_ced_update$CED_NAME21[i]
}

addresses |>
  dplyr::filter(is.na(CED_NAME21))

addresses |>
  dplyr::count(CED_NAME21) |>
  print(n = Inf)

# FIX CED: done manually below and output to missing-ced-update.csv ----
# # 551 have no CED
# addresses_missing_ced <-
#   addresses |>
#   dplyr::filter(is.na(CED_NAME21))
#
# addresses_missing_ced
#
# missing_ced_update <-
#   readr::read_csv('gnaf/gnaf-coords-to-electorate-and-mp/missing-ced-update.csv')
#
# for(i in 1:nrow(missing_ced_update)){
#   row_ind <- addresses_missing_ced$id == missing_ced_update$id[i]
#   update_value <-  missing_ced_update$CED_NAME21[i]
#   addresses_missing_ced$CED_NAME21[row_ind] <- update_value
# }
#
# addresses_missing_ced <-
#   addresses_missing_ced |>
#   dplyr::filter(is.na(CED_NAME21))
#
# addresses_sf_missing_ced <-
#   addresses_sf |>
#   dplyr::filter(id %in% addresses_missing_ced$id)
#
# library(crosstalk)
# library(leaflet)
# library(DT)
#
# sd1 <-
#   addresses_sf_missing_ced |>
#   crosstalk::SharedData$new(group = 'meme')
#
# sd2 <-
#   addresses_sf_missing_ced |>
#   sf::st_drop_geometry() |>
#   dplyr::select(id) |>
#   crosstalk::SharedData$new(group = 'meme')
#
#
# crosstalk::bscols(
#   leaflet::leaflet(sd1) |>
#     leaflet::addPolygons(data = nsw_ced, weight = 1, label = ~CED_NAME21 ) |>
#     leaflet::addCircleMarkers(popup = ~id),
#   DT::datatable(sd2,
#                 extensions="Buttons",
#                 width="100%",
#                 options=list(
#                   deferRender=TRUE,
#                   dom = 'Bfrtip',
#                   buttons = c('copy')
#                 )
#   )
# )



# Final CED table
addresses_final <-
  addresses |>
  dplyr::left_join(
    people,
    by = c('CED_NAME21' = 'MP_ELECTORATE')
  )


addresses_final |>
  dplyr::filter(is.na(MP_ID))

# App expects CSV with columns id,LATITUDE,LONGITUDE,MP_ID
addresses_final |>
  dplyr::select(id,LATITUDE,LONGITUDE,MP_ID) |>
  readr::write_csv(file = here::here('gnaf-coords-to-electorate-and-mp/address-id-coordinates-mp-id-gnaf-core-columns.csv'))

##
addresses_final |>
  dplyr::filter(id == 'GANSW717275747')
