#' GNAF flat to climate app data assets
#'
#' Meilisearch synonyms
#' GNAF to meilisearch DB (id, address string/components)
#' GNAF to id DB (id, coords, other)

# Data import ----
# Flat file
ADDRESS_VIEW <-
  readr::read_csv('gnaf-core-in-columns/gnaf-core-in-columns-nsw.csv')

# Synonyms ----
street_suffix_forms <-
  readr::read_csv('data/street-suffix-forms/street-suffix-forms-concordance.csv')

# Examine synonyms verus those in the data

street_suffix_forms_final <-
  ADDRESS_VIEW |>
  dplyr::select(STREET_TYPE) |>
  dplyr::distinct(STREET_TYPE) |>
  dplyr::arrange(STREET_TYPE) |>
  dplyr::left_join(street_suffix_forms, by = c(STREET_TYPE = 'FULL_NAME')) |>
  # These are all the matches or not
  print(n = Inf) |>
  # This is what will be used in the end
  dplyr::filter(!is.na(STREET_TYPE), !is.na(SUFFIX_FORM))|>
  print(n = Inf)

# Search phone returns iphone, but iphone not phone
#{"phone": ["iphone"]}

street_suffix_forms_final_json <-
  with(street_suffix_forms_final,{
    STREET_TYPE |>
      as.list() |>
      setNames(SUFFIX_FORM)
  }) |>
  jsonlite::toJSON(pretty = F)

street_suffix_forms_final_json |>
  writeLines('street-suffix-forms/street-suffix-forms.json')
