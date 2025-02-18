
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Address coordinates and metadata for climate app

<!-- badges: start -->
<!-- badges: end -->

This repository holds the workflow for address coordinates and metadata
for the climate app. This includes the

- Australian Geoscape Geocoded National Address File (GNAF) from
  [Geoscape](https://geoscape.com.au/), a publicly available dataset
  (database and flat file),
- the Commonwealth Electoral Divisions boundaires from ABS
- Member of Parliament (MPs, politicans) metadata, including electoral
  division
- Street suffix synonyms for the address search database of the app

## The data

### GNAF

We use the GNAF Core file (A single table Geocoded National Address
File), that is hosted on Amazon
[here](https://aws.amazon.com/marketplace/pp/prodview-4uaw3hqqu73ls). A
user needs to subscribe to the dataset to be able download it (all
free). The dataset is a flat CSV file with address ID, coordinates, and
address components (street number, name, location, etc) split into
multiple columns.

### CED boundaries

From ABS
[here](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files).
Chose “Commonwealth Electoral Divisions - 2021 - Shapefile”

### Electorate MP

[theyvoteforyou.org.au](https://theyvoteforyou.org.au/) provide
information of Australian Member of Parliament (MPs, politicans). They
have a list of MPs and their electorates. An API key is required (free)
and is required in the scripts below (a temporary file is included from
early 2024).

### Street suffix forms

The meilisearch address database can incorporate synonyms for words, and
this is useful for address information where full street types may not
be given/used e.g. PLACE or PL. There are lists on the internet to help
create this synonym table, and here we use one from
<https://api-doc.cacheinvest.com.au/street_type_guideline.html>

## Workflow

- For the address database, we require a subset of the GNAF columns. For
  the app MVP we extract only NSW addresses.

- We next need to allocate address into CED boundaries and then link
  politician IDs using electorate names

### Obtain data

Obtain the GNAF core, CED boundaries and people.json, and store in
`data`

### Wrangle GNAF

`00-wrangle-gnaf-core.R` obtains NSW addresses and a subset of columns
and outputs into `gnaf-core-in-columns/gnaf-core-in-columns-nsw.csv`.

**This file is used in the meilisearch database**

### Allocate address into CED and link politician ID

`01-join-electorate-to-gnaf-address-coords.R` does

- extract NSW CED boundaries
- wrangles the people.json from they vote for you
- allocates address into CED using `sf::st_intersects`
- conducts QC and fix on allocation (some address are slightly outside
  given CED boundaries), using the file
  `naf-coords-to-electorate-and-mp/missing-ced-update.csv` (this file is
  tracked in the repo)

outputs
`gnaf-coords-to-electorate-and-mp/address-id-coordinates-mp-id-gnaf-core-columns.csv`

**This file is used in the climate app `data/` folder**

### Generate street suffix synonyms

`02-street-suffix-synonyms.R` generates a synonyms file for use in the
mielesearch database. The output is
`street-suffix-synonyms/street-suffix-forms.json`.

**This file is uses in the meilisearch database**
