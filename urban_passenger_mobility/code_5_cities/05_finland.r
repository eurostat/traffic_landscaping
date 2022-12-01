library(sf)           # To work with geospatial data
library(raster)       # To work with Raster data
library(glue)         # To work with text data
library(gtfstools)    # To work with GTFS data
library(tidyverse)    # To load the different data wrangling packages
library(lubridate)    # To work with dates
library(colorspace)   # For extra color options
library(terra)        # To work with Raster data
library(opentripplanner) # to access the OpenTripPlanner API
library(gtfs2gps)     # To work with GTFS data
library(elevatr)      # To download elevation data
library(stringi)      # To work with text data
library(openrouteservice) # to access the openrouteservice API
library(mapview)     # To create interactive maps
library(ggspatial)   # To create static maps

## Finland: Helsinki (note different dates)


# download 2022 data from https://www.hsl.fi/en/hsl/open-data#public-transport-network-and-timetables-gtfs
# pop data from https://hub.worldpop.org/geodata/summary?id=49971


name_country_folder       <- "05_Finland"
name_country_osm_file     <- "europe-latest.osm.pbf"
name_FUA_osm_file         <- "current_capital_file.osm.pbf"
urban_area_of_interest    <- "FI001C2"
path_to_shape_file        <- "URAU_RG_100K_2020_3857_CITIES.shp/URAU_RG_100K_2020_3857_CITIES.shp"
name_layer                <- "URAU_RG_100K_2020_3857_CITIES"
path_to_gtfs_file         <- "hsl.zip"
path_to_subset_gtfs_file  <- "current_city_GTFS_file.zip"
path_to_saved_elevation   <- "elevation_current_city.tif"
start_date                <- "2022-08-22"
end_date                  <- "2022-08-28"
population_data_path      <- "fin_ppp_2020_UNadj_constrained.tif"
name_OTP_folder           <- "OTP_folder"
date_and_time             <- as.POSIXct(strptime("2022-08-23 08:30", "%Y-%m-%d %H:%M", tz ="Europe/Amsterdam"))
max_walking_distance      <- 1000
output_population_reached <- "population_reached_data.csv"
grid_size                 <- 0.005
accesibility_stats_path   <- "accesibility_stats.csv"
output_OD_car <- "output_OD_car.rds"
output_OD_PS  <-  "output_OD_PS.rds"
# load shapefile
cities_shape_files <- read_sf(path_to_shape_file, layer= name_layer) 
cities_shape_files_list <- cities_shape_files %>% 
  st_drop_geometry()
# select FUA
city_shape_file <- cities_shape_files %>%
  filter(URAU_CODE  == urban_area_of_interest)

# reproject city shapefile to longlat
city_shape_file <- st_transform(city_shape_file, st_crs("+proj=longlat"))
mapview(city_shape_file)


# extract bounding box of shapefile
bbox_FUA <- round(st_bbox(city_shape_file) *100)/ 100



cutting_command <-
  glue(
    "osmconvert64-0.8.8p.exe {name_country_osm_file} -b={bbox_FUA$xmin -0.02},{bbox_FUA$ymin -0.02},{bbox_FUA$xmax +0.02},{bbox_FUA$ymax +0.02}  --complete-ways --out-pbf -o={file.path(name_country_folder,name_FUA_osm_file)}"
  )

system(cutting_command)


 # Load GTFS file
full_gtfs_file <- tidytransit::read_gtfs(file.path(name_country_folder,path_to_gtfs_file))

# Filter only the stops that are in the actual FUA
current_UA_stops <- full_gtfs_file$stops %>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat"))%>%
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in)) %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2]) 

mapview::mapview(city_shape_file) +
  mapview::mapview(current_UA_stops)
# Filter only the stop times of the stops that are within the FUA
current_UA_stoptimes <- full_gtfs_file$stop_times %>% 
  filter(stop_id  %in% unique(current_UA_stops$stop_id))

# Filter only trips that go by the stops that are within the FUA
current_UA_trips <- full_gtfs_file$trips%>% 
  filter(trip_id   %in% unique(current_UA_stoptimes$trip_id ))

# Filter only routes that go by the stops that are within the FUA
routes_of_interest <- full_gtfs_file$routes %>% 
  filter(route_id    %in% unique(current_UA_trips$route_id  )) %>% 
  pull(route_id ) %>% 
  unique()

full_gtfs_file$routes <-  full_gtfs_file$routes %>% 
  filter(route_id %in% routes_of_interest)


# subset the whole GTFS file
subset_gtfs_file <- gtfs2gps::filter_by_route_id(full_gtfs_file, routes_of_interest)

# Filter only the stops that are in the actual FUA
# needs to happen again after the filtering of the routes
subset_UA_stops <- subset_gtfs_file$stops%>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat")) %>%
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in)) %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2]) 

# Filter only the stop times of the stops that are within the FUA
subset_UA_stoptimes <- subset_gtfs_file$stop_times %>% 
  filter(stop_id  %in% unique(subset_UA_stops$stop_id))

# Filter out invalid stops
subset_gtfs_file <- gtfs2gps::remove_invalid(subset_gtfs_file)
subset_gtfs_file <- gtfs2gps::filter_valid_stop_times(subset_gtfs_file)

# save the subsetted GTFS file.

#gtfs2gps::write_gtfs(subset_gtfs_file, file.path(name_country_folder,path_to_subset_gtfs_file))


subset_gtfs_file$translations <- NULL
subset_gtfs_file$fare_attributes <- NULL
subset_gtfs_file$translations_new <- NULL
subset_gtfs_file$stops_old <- NULL
subset_gtfs_file$stops2 <- NULL
subset_gtfs_file$fare_rules <- NULL


# this is needed because there are some stops in the transfer data
# that are not in the actual stops data
subset_gtfs_file$transfers <- subset_gtfs_file$transfers %>% 
  filter(from_stop_id  %in% subset_gtfs_file$stop_times$stop_id)%>% 
  filter(to_stop_id   %in% subset_gtfs_file$stop_times$stop_id)



tidytransit::write_gtfs(subset_gtfs_file, file.path(name_country_folder,path_to_subset_gtfs_file))





subset_gtfs_file <- tidytransit::read_gtfs(file.path(name_country_folder,path_to_subset_gtfs_file))


elevation <- elevatr::get_elev_raster(city_shape_file,
                                      z = 12)
terra::writeRaster(elevation, 
                   filename = file.path(name_country_folder,
                                        path_to_saved_elevation),
                   overwrite=TRUE)


elevation <- terra::rast(file.path(name_country_folder,
                                   path_to_saved_elevation))

#docker run -dt --name ors-app -p 8080:8080 -e BUILD_GRAPHS=True -v /var/lib/docker/graphs:/ors-core/data/graphs -v /var/lib/docker/elevation_cache:/ors-core/data/elevation_cache -v /var/lib/docker/conf:/ors-conf -v C:/Users/laure/stack/Gopa/usecase_OTP_Project/03_Croatia/current_capital_file.osm.pbf:/ors-core/data/osm_file.pbf -e "JAVA_OPTS=-Djava.awt.headless=true -server -XX:TargetSurvivorRatio=75 -XX:SurvivorRatio=64 -XX:MaxTenuringThreshold=3 -XX:+UseG1GC -XX:ParallelGCThreads=4 -Xms1g -Xmx2g" -e "CATALINA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9001 -Dcom.sun.management.jmxremote.rmi.port=9001 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=localhost" giscience/openrouteservice:release-6.6.0


glue('docker run -dt --name ors-app -p 8080:8080 -e BUILD_GRAPHS=True -v /var/lib/docker/graphs:/ors-core/data/graphs -v /var/lib/docker/elevation_cache:/ors-core/data/elevation_cache -v /var/lib/docker/conf:/ors-conf -v {file.path(getwd(),name_country_folder)}/current_capital_file.osm.pbf:/ors-core/data/osm_file.pbf -e "JAVA_OPTS=-Djava.awt.headless=true -server -XX:TargetSurvivorRatio=75 -XX:SurvivorRatio=64 -XX:MaxTenuringThreshold=3 -XX:+UseG1GC -XX:ParallelGCThreads=4 -Xms1g -Xmx2g" -e "CATALINA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9001 -Dcom.sun.management.jmxremote.rmi.port=9001 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=localhost" giscience/openrouteservice:release-6.6.0')


population_data      <- terra::rast(file.path(name_country_folder,population_data_path))
population_data_city <- terra::crop(population_data, city_shape_file)
population_data_city <- terra::mask(population_data_city,terra::vect(city_shape_file))
population_data_city_brick <- raster::brick(population_data_city)

options(openrouteservice.url = "http://localhost:8080/ors")
options(openrouteservice.paths = list(directions = "v2/directions",
                                      isochrones = "v2/isochrones",
                                      matrix = "v2/matrix",
                                      geocode = "geocode",
                                      pois = "pois",
                                      elevation = "elevation",
                                      optimization = "optimization"))



all_stops <- subset_gtfs_file$stops %>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat")) %>% 
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in)) 


sf::sf_use_s2(TRUE)


subset_stops_buffer <- st_buffer(all_stops,dist = 500) %>% st_union()
subset_stops_buffer <- st_cast(subset_stops_buffer, "MULTIPOLYGON") %>%
  st_as_sf()

mapview(subset_stops_buffer)

# calculate the percentage of the population that lives within this
# polygon 
percent_500m  <- sum(raster::extract(population_data_city_brick,
                                 subset_stops_buffer,fun=sum, na.rm =TRUE) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE))



# 0.9900521
# percent_500m <- 0.9900521

total_pop <- sum(as.matrix(population_data_city_brick), na.rm = TRUE)
# 669450.1

mapview(all_stops)

all_stops_simple <- all_stops %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2])  %>%
  st_drop_geometry() %>% 
  select(stop_id , lon, lat)

# create empty tible for results
results <- tibble()

# https://giscience.github.io/openrouteservice/installation/Running-with-Docker
## validate profile

for(i in 1:nrow(all_stops_simple)){
  tryCatch({ # include a tryCatch to continue if there is an error
    res <- ors_isochrones(all_stops_simple %>%
                            slice(i) %>% 
                            select(-stop_id),
                          range = 500,
                          #profile  = "driving-car",
                          profile  = "foot-walking",
                          range_type = "distance",
                          smoothing = 0,
                          area_units = "m",
                          units = "m",
                          id = "myid",
                          output = "sf") %>% 
      mutate(stop_id = all_stops_simple %>%
               slice(i) %>% 
               pull(stop_id))
    
    if(nrow(results) == 0){
      results <-   res
      
    }else{
      results <- rbind(results,  res)
    }
  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}

sf::sf_use_s2(FALSE)
# combine all the results
walking_dist_500_m <- st_union(results) %>% 
  st_as_sf()

mapview::mapview(walking_dist_500_m)
percent_walk <- sum(raster::extract(population_data_city_brick,
                                    walking_dist_500_m,fun=sum, na.rm =TRUE)) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE)

#percent_walk <- 0.956955

# use the super helpful servicepatterns function from tidytransit https://cran.r-project.org/web/packages/tidytransit/vignettes/servicepatterns.html


gtfs_pattern <- tidytransit::read_gtfs(file.path(name_country_folder,path_to_subset_gtfs_file))
gtfs_pattern <-  tidytransit::set_servicepattern(gtfs_pattern)

gtfs_pattern$.$dates_servicepatterns %>% 
  count(date)
stops_2_per_weekday_average <- gtfs_pattern$.$dates_servicepatterns %>% 
  filter(date >= anytime::anydate(start_date),
         date <= anytime::anydate(end_date)) %>% 
  left_join(gtfs_pattern$.$servicepatterns, by = "servicepattern_id") %>% 
  left_join(gtfs_pattern$trips,  by = "service_id") %>% 
  select(date, service_id, route_id, trip_id ) %>% 
  left_join(gtfs_pattern$stop_times,  by = "trip_id") %>% 
  mutate(week_day = weekdays(date)) %>% 
  mutate(departure_date_time = anytime::anytime(str_glue("{as.character(date)} {departure_time}"))) %>%
  mutate(departure_date_standardized =anytime::anytime(paste0("2022-01-01 ", substr(as.character(departure_date_time), 12, 20)))) %>% 
  mutate(during_7_10_am = departure_date_standardized < ymd_hms(paste0("2022-01-01 09:00:00")) & departure_date_standardized > ymd_hms(paste0("2022-01-01 07:00:00"))) %>% 
  group_by(week_day, stop_id) %>% 
  summarise(sum_stops_during_7_10_am = sum(during_7_10_am)) %>%
  filter(!week_day %in% c("Saturday", "Sunday")) %>% 
  group_by(stop_id) %>% 
  summarise(mean_stops_during_7_10_am = mean(sum_stops_during_7_10_am)) %>% 
  filter(mean_stops_during_7_10_am >= 2)



filtered_results_mornings <- results %>% 
  filter(stop_id %in%stops_2_per_weekday_average$stop_id) 



filtered_walking_dist_500_m_morings <- st_union(filtered_results_mornings) %>% st_as_sf()


percent_walk_morning <- sum(raster::extract(population_data_city_brick,
                                            filtered_walking_dist_500_m_morings,fun=sum, na.rm =TRUE)) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE)


#percent_walk_morning <-    0.9486245


selected_stop_ids_wheelchair <- all_stops %>% 
  filter(wheelchair_boarding == 1) %>% 
  pull(stop_id )

filtered_results_wheel_chair <- results %>% 
  filter(stop_id %in%selected_stop_ids_wheelchair) 


filtered_walking_dist_500_m_wheelchair <- st_union(filtered_results_wheel_chair) %>% st_as_sf()

wheelchair_accessible <- round(sum(raster::extract(population_data_city_brick,filtered_walking_dist_500_m_wheelchair,fun=sum, na.rm =TRUE)) /
                                 sum(as.matrix(population_data_city_brick), na.rm = TRUE) *100, 1)


accesibility_stats <- tibble(percent_500m, percent_walk,percent_walk_morning, total_pop,wheelchair_accessible, country = "Finland", city = "Helsinki")
write_csv(accesibility_stats, file.path(name_country_folder,accesibility_stats_path))

#####
#####
#####

## because the Zagreb GTFS does not follow the right format (there are no shapes in the gtfs file), no gtfs plan can be derived.
# set top level folder
path_data <- file.path(file.path(name_country_folder,name_OTP_folder))

# create subfolders
ifelse(!dir.exists(path_data), dir.create(path_data), FALSE)
ifelse(!dir.exists( file.path(name_country_folder, name_OTP_folder, "graphs")), 
       dir.create( file.path(name_country_folder,name_OTP_folder, "graphs")), FALSE)


ifelse(!dir.exists( file.path(name_country_folder, name_OTP_folder,  "graphs", "default")), 
       dir.create( file.path(name_country_folder, name_OTP_folder,  "graphs",  "default")), FALSE)

# copy files into subfolder and rename them
file.copy(file.path(name_country_folder, name_FUA_osm_file),
          file.path(name_country_folder, name_OTP_folder,
                    "graphs", "default"))

file.rename(from = file.path(name_country_folder, name_OTP_folder,
                             "graphs", "default", name_FUA_osm_file),
            to   = file.path(name_country_folder, name_OTP_folder, 
                             "graphs", "default", "osm_file.osm.pbf"))


file.copy(file.path(name_country_folder, path_to_subset_gtfs_file),
          file.path(name_country_folder,name_OTP_folder,
                    "graphs", "default"))

file.rename(from = file.path(name_country_folder, name_OTP_folder, 
                             "graphs", "default", path_to_subset_gtfs_file),
            to   = file.path(name_country_folder, name_OTP_folder, 
                             "graphs", "default", "gtfs.zip"))


file.copy(file.path(name_country_folder, path_to_saved_elevation),
          file.path(name_country_folder, name_OTP_folder,  "graphs", "default"))

file.rename(from = file.path(name_country_folder, name_OTP_folder,  "graphs", "default", path_to_saved_elevation),
            to   = file.path(name_country_folder, name_OTP_folder,  "graphs", "default", "elevation.tif"))


otp_check_java()
path_otp <- otp_dl_jar(file.path(name_country_folder,path_data), cache = TRUE)
otp_stop()

log1 <- otp_build_graph(otp = path_otp, dir =  file.path(path_data),  memory = 8000)
log2 <- otp_setup(otp = path_otp, dir = path_data)
otpcon <- otp_connect(timezone = "Europe/Amsterdam")


bounding_box <- st_bbox(city_shape_file) 

grid <- expand.grid(seq(bounding_box[1], bounding_box[3], by = 0.005),
                    seq(bounding_box[2], bounding_box[4], by = 0.005)) %>%
  as_tibble() %>%
  mutate(id = 1:n()) %>%
  relocate(id) %>%
  setNames(c("id", "lon","lat")) %>%
  st_as_sf(coords = c("lon", "lat")) %>%
  st_set_crs(st_crs("+proj=longlat")) %>%
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in))%>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2])

total_pop <-  sum(as.matrix(terra::mask(population_data_city, vect(city_shape_file))),  na.rm = TRUE)
get_percentage_function <- function(y,
                                    data = complete_isochone,
                                    cur_total_pop = total_pop,
                                    cur_population_data_city = population_data_city){
  
  cur_isochone <-  data %>% slice(y)
  percent_population_reached <- sum(as.matrix(terra::mask(cur_population_data_city, vect(cur_isochone)) ), 
                                    na.rm = TRUE) / cur_total_pop
  
  area <- st_area(cur_isochone)
  output <- tibble(percent_population_reached = percent_population_reached,
                   time = cur_isochone$time,
                   area = area)
  output
}


mapview(grid)
# create empty list to store results
list_results <- list()

# loop over rows in grid
for (i in 1:nrow(grid)) {
  tryCatch({
    
    #only look at one point at a time
    test_point <- grid %>%
      slice(i)
    
    # select current point data    
    id <- test_point$id
    
    cur_lon <- test_point$lon
    cur_lat <- test_point$lat
    
    # compute 24 isochrones per point
    complete_isochone <- otp_isochrone(
      otpcon = otpcon,
      fromPlace = c(cur_lon, cur_lat),
      mode = c("WALK", "TRANSIT"),
      maxWalkDistance = max_walking_distance,
      date_time = date_and_time,
      cutoffSec = seq(5, 120, 5) * 60
    )
    
    # use the custom get_percentage_function function 
    # to estimate which percentage of the FUA can be
    # reached and bind all the results
    output2 <-
      data.table::rbindlist(
        lapply(1:nrow(complete_isochone), 
               FUN = get_percentage_function)
      ) %>%
      as_tibble() %>%
      mutate(id = id,
             cur_lon,
             cur_lat)
    
    # store the results in a list
    list_results[[i]] <- output2
    print(paste0(i, " of ", nrow(grid)))
  },
  error = function(e) {
    cat("ERROR :", conditionMessage(e), "\n")
  })
}


 # save a ll the results
population_reached_data <- data.table::rbindlist(list_results)%>% 
  as_tibble()

write_csv(population_reached_data, file.path(name_country_folder,output_population_reached))


bounding_box <- st_bbox(city_shape_file) 

grid_2 <- expand.grid(seq(bounding_box[1], bounding_box[3], by = 0.02),
                      seq(bounding_box[2], bounding_box[4], by = 0.02)) %>%
  as_tibble() %>%
  mutate(id = 1:n()) %>%
  relocate(id) %>%
  setNames(c("id", "lon","lat")) %>%
  st_as_sf(coords = c("lon", "lat")) %>%
  st_set_crs(st_crs("+proj=longlat")) %>%
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in))%>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2])

dest_matrix <- grid_2 %>%
  select(id, lon, lat) %>% 
  st_drop_geometry() %>% 
  as.matrix()

dest_matrixt_tib <- as_tibble(dest_matrix) %>% 
  mutate(str_loc  = paste0(substr(as.character(format(round(lat, 7), nsmall = 7)),1 ,10),
                           ",",
                           ifelse(nchar(qdap::beg2char(as.character(format(round(lon, 7), nsmall = 7)), ".")) == 1, 
                                  substr(as.character(format(round(lon, 7), nsmall = 7)),1 ,9),
                                  substr(as.character(format(round(lon, 7), nsmall = 7)),1 ,10)))) %>% 
  rename(end_id = id)


list_results_org_dest_car <- list()
list_results_org_dest_PS <- list()


# loop over points in grid
for (i in 1:nrow(grid_2)) {
  tryCatch({
    
    # select current point    
    test_point <- grid_2 %>%
      slice(i)
    
    id <- test_point$id
    
    start_lon <- test_point$lon
    start_lat <- test_point$lat
    
    # compute the the travel times for the car    
    complete_plan_car <- otp_plan(
      otpcon = otpcon,
      fromPlace = c(start_lon, start_lat),
      toPlace = dest_matrix[, 2:3],
      mode = c("CAR"),
      ncores = 4,
      maxWalkDistance = 2000,
      date_time = date_and_time
    )
    
    # compute the the travel times for public transport
    
    complete_plan_public_transport <- otp_plan(
      otpcon = otpcon,
      fromPlace = c(start_lon, start_lat),
      toPlace = dest_matrix[, 2:3],
      mode = c("WALK", "TRANSIT"),
      ncores = 4,
      maxWalkDistance = 2000,
      date_time = date_and_time
    )
    
    # per OD point compute the fastest route and if the route 
    # consists of different legs, then combine these
    
    output_car <- left_join(complete_plan_car %>%
                              group_by(fromPlace, toPlace, route_option) %>% 
                              summarize(startTime = unique(startTime),
                                        endTime = unique(endTime),
                                        duration = unique(duration),
                                        geometry = st_union(geometry)) %>% 
                              ungroup() %>% 
                              filter(!st_is(. , "POINT")) %>% 
                              group_by(fromPlace, toPlace) %>% 
                              filter(duration == min(duration)) %>% 
                              slice(1)%>%
                              ungroup(),
                            dest_matrixt_tib, by = c("toPlace" = "str_loc")) %>% 
      mutate(start_id = id) %>%
      mutate(start_lon,
             start_lat)
    
    
    output_PS <- left_join(complete_plan_public_transport %>%
                             group_by(fromPlace, toPlace, route_option) %>% 
                             summarize(startTime = unique(startTime),
                                       endTime = unique(endTime),
                                       duration = unique(duration),
                                       geometry = st_union(geometry)) %>% 
                             ungroup() %>% 
                             filter(!st_is(. , "POINT")) %>% 
                             group_by(fromPlace, toPlace) %>% 
                             filter(duration == min(duration)) %>% 
                             slice(1) %>%
                             ungroup() ,
                           dest_matrixt_tib, by = c("toPlace" = "str_loc")) %>% 
      mutate(start_id = id)%>%
      mutate(start_lon,
             start_lat)
    
    # store the results in a list    
    list_results_org_dest_car[[i]] <- output_car
    list_results_org_dest_PS[[i]] <- output_PS
    
    print(paste0(i, " of ", nrow(grid_2)))
  },
  error = function(e) {
    cat("ERROR :", conditionMessage(e), "\n")
  })
}

# combine the results in a single dataframe
org_dest_PS <- do.call("rbind", list_results_org_dest_PS)
org_dest_car <- do.call("rbind", list_results_org_dest_car)


write_rds(org_dest_PS, file.path(name_country_folder,output_OD_PS))
write_rds(org_dest_car, file.path(name_country_folder,output_OD_car))





