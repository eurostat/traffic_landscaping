link_to_country_osm_file <- "https://download.geofabrik.de/europe/netherlands/zuid-holland-latest.osm.pbf"
name_country_osm_file    <- "data/zuid-holland-latest.osm.pbf"

download.file(url      = link_to_country_osm_file,
              destfile = name_country_osm_file)
