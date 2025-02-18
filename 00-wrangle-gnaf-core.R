#' Wrangle GNAF core file for minified address file
#'
#' Only require a subset of columns for webapp:
#'  - id, lat, lon, address columns
#'
#'
#' The lat/lon then need be matched into the CED_2021 shapefile

gnaf_file <- 'data/G-NAFCore_AUG24_AUSTRALIA_GDA2020_PSV_108/G-NAF Core/G-NAF Core AUGUST 2024/Standard/GNAF_CORE.psv'


# Extract GNAF core NSW ----
readr::read_delim_chunked(
  file = gnaf_file,
  delim = "|",
  chunk_size = 1000000,
  callback =  readr::SideEffectChunkCallback$new(callback = function(x, pos){
    cat(pos, sep = "\n")
    append = ifelse(pos == 1, F, T)
    x |>
      dplyr::select(id = ADDRESS_DETAIL_PID, LATITUDE, LONGITUDE, ADDRESS_SITE_NAME:POSTCODE) |>
      dplyr::filter(STATE == 'NSW') |>
      readr::write_csv(file = 'gnaf-core-in-columns/gnaf-core-in-columns-nsw.csv', append = append, na = '')
  })
)

# Examine output
gnaf <-
  readr::read_csv('gnaf-core-in-columns/gnaf-core-in-columns-nsw.csv')

# This file is be imported into the mielesearch database
