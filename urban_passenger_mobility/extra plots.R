cleaned_data_folder       <- "cleaned_data"
link_to_country_osm_file  <- "https://download.geofabrik.de/europe/netherlands/zuid-holland-latest.osm.pbf"
name_country_osm_file     <- "data/zuid-holland-latest.osm.pbf"
name_FUA_osm_file         <- "thehague.osm.pbf"
urban_area_of_interest    <- "NL001L3"
path_to_shape_file        <- "data/URAU_RG_100K_2020_3857_FUA.shp/URAU_RG_100K_2020_3857_FUA.shp"
name_layer                <- "URAU_RG_100K_2020_3857_FUA"
path_to_gtfs_file         <- "data/gtfs-openov-nl.zip"
path_to_subset_gtfs_file  <- "subset-gtfs_the_hague.zip"
path_to_saved_elevation   <- "elevation_the_hague.tif"
start_date                <- "2022-05-16"
end_date                  <- "2022-05-22"
population_data_path      <- "data/nld_ppp_2020_UNadj_constrained.tif"
name_OTP_folder           <- "OTP_folder"
date_and_time             <- as.POSIXct(strptime("2022-05-17 08:30", "%Y-%m-%d %H:%M", tz ="Europe/Amsterdam"))
max_walking_distance      <- 1000
output_population_reached <- "results/population_reached_data.csv"
grid_size                 <- 0.005

path_to_gtfs_file         <- "data/gtfs-openov-nl.zip"
path_to_subset_gtfs_file  <- "subset-gtfs_the_hague.zip"


full_gtfs_file <- gtfs2gps::read_gtfs(path_to_gtfs_file)
subset_gtfs_file <- gtfs2gps::read_gtfs(file.path(cleaned_data_folder,path_to_subset_gtfs_file))


# load shapefile
FUA_shape_file <- read_sf(path_to_shape_file, layer= name_layer)



# select FUA
city_shape_file <- FUA_shape_file %>%
  filter(URAU_CODE  == urban_area_of_interest)

# reproject city shapefile to longlat
city_shape_file <- st_transform(city_shape_file, st_crs("+proj=longlat"))

full_shape <- full_gtfs_file$shapes
subset_shape <- subset_gtfs_file$shapes



full_shape_p1 <- ggplot(full_shape) +
  geom_sf(data = city_shape_file, fill = "red", alpha = .5) +
  geom_path(aes(shape_pt_lon, shape_pt_lat, group=shape_id), color="white", size=.2, alpha=.05) +
  #coord_equal() +
  theme_void() +
  theme(plot.background = element_rect(fill = "black", colour = "black"),
        title = element_text(hjust=1, colour="white", size = 8),
        axis.title.x = element_blank())



ggsave("full_shape_p1.png", full_shape_p1, width = 15, height = 10, dpi = 600)


subset_shape_p1 <- ggplot(subset_shape) +
  geom_sf(data = city_shape_file, fill = "red", alpha = .5) +
  geom_path(aes(shape_pt_lon, shape_pt_lat, group=shape_id), color="white", size=.2, alpha=.05) +
  #coord_equal() +
  theme_void() +
  theme(plot.background = element_rect(fill = "black", colour = "black"),
        title = element_text(hjust=1, colour="white", size = 8),
        axis.title.x = element_blank())

ggsave("subset_shape_p1.png", subset_shape_p1, width = 15, height = 10, dpi = 600)

# Filter only the stops that are in the actual FUA
current_UA_stops <- full_gtfs_file$stops%>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat"))%>%
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in)) %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2])


subset_stops_p1 <- ggplot(current_UA_stops) +
  geom_sf(data = city_shape_file, col = "red", alpha = .2, fill ="red") +
  geom_point(aes(lon, lat), color="white", fill = "white", size = 1, alpha=.2) +
  #coord_equal() +
  theme_void() +
  theme(plot.background = element_rect(fill = "black", colour = "black"),
        title = element_text(hjust=1, colour="white", size = 8),
        axis.title.x = element_blank())

ggsave("subset_stops_p1.png", subset_stops_p1, width = 15, height = 10, dpi = 600)

subset_shape_p2 <- ggplot(subset_shape) +
  geom_sf(data = city_shape_file, fill = "red", alpha = .5) +
  coord_sf(xlim = c(4.1, 4.6), ylim = c(51.9, 52.2))+
  geom_path(aes(shape_pt_lon, shape_pt_lat, group=shape_id), color="white", size=.7, alpha=.1) +
  geom_point(data = current_UA_stops, aes(lon, lat), color="white", fill = "white", size = 1, alpha=.2) +
  #coord_equal() +
  theme_void() +
  theme(plot.background = element_rect(fill = "black", colour = "black"),
        title = element_text(hjust=1, colour="white", size = 8),
        axis.title.x = element_blank())


ggsave("subset_shape_p2.png", subset_shape_p2, width = 15, height = 10, dpi = 600)


options(openrouteservice.url = "http://localhost:8080/ors")
options(openrouteservice.paths = list(directions = "v2/directions",
                                      isochrones = "v2/isochrones",
                                      matrix = "v2/matrix",
                                      geocode = "geocode",
                                      pois = "pois",
                                      elevation = "elevation",
                                      optimization = "optimization"))


res <- ors_isochrones(all_stops_simple %>%
                        slice(2000) %>%
                        select(-stop_id),
                      range = 2000, interval = 500,
                      range_type = "distance",
                      smoothing = 0,
                      attributes= c("total_pop","area"),
                      area_units = "m",
                      units = "m",
                      id = "myid",
                      output = "sf")
dat_2 <- all_stops %>%
  slice(2000)
mapview::mapview(res, alpha.regions = 0.2) +
  mapview::mapview(dat_2)


all_stops2 <- subset_gtfs_file$stops%>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat"))%>%
  mutate(point_in = as.numeric(st_intersects(., city_shape_file))) %>%
  filter(!is.na(point_in)) %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2])
all_stops2 %>% saveRDS("large_file_storage/all_stops.rds")
population_data_city_brick %>% saveRDS("large_file_storage/population_data_city_brick.rds")
mapview::mapview(all_stops2)
path_to_subset_gtfs_file  <- "subset-gtfs_the_hague.zip"

cleaned_data_folder       <- "cleaned_data"

subset_gtfs_file <- gtfs2gps::read_gtfs(file.path(cleaned_data_folder,path_to_subset_gtfs_file))
all_stops <- subset_gtfs_file$stops %>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat"))
my_stop_id <- unique(all_stops$stop_id)


trips_for_stop <- subset_gtfs_file$stop_times %>%
  filter(stop_id %in% c(my_stop_id))

all_trips <- subset_gtfs_file$trips %>%
  filter(trip_id %in% unique(trips_for_stop$trip_id ))


calendar_dates <- subset_gtfs_file$calendar_dates %>%
  filter(service_id %in% unique(all_trips$service_id)) %>%
  as_tibble()


stop_times_stats_per_stop <- trips_for_stop %>%
  select(stop_id, trip_id ,  departure_time) %>%
  left_join(
    all_trips %>%
      select(service_id, trip_id) %>%
      distinct() %>%
      left_join(calendar_dates, by = "service_id"),
    by = "trip_id"
  ) %>%
  as_tibble() %>%
  mutate(date = ymd(date)) %>%
  # there are some depart in a time after 24h, these need to be moved to the next day
  mutate(dep_after_midnight = substr(departure_time, 1, 2) %>%  as.numeric() - 23 > 0) %>%
  mutate(departure_time  = as.character(departure_time )) %>%
  mutate(
    departure_time = if_else(dep_after_midnight,
                             paste0(
                               str_pad(
                                 as.numeric(substr(departure_time, 1, 2)) - 24,
                                 width = 2,
                                 side = "left",
                                 pad = "0"
                               ),
                               substr(departure_time, 3, 1000)
                             ),
                             departure_time),
    date =  if_else(dep_after_midnight, date + days(1), date)
  ) %>%
  mutate(departure_date = lubridate::ymd_hms(str_glue("{as.character(date)} {departure_time}"))) %>%
  mutate(departure_date_rounded = round_date(departure_date,
                                             unit = "30 minutes")) %>%
  mutate(week_day = weekdays(departure_date_rounded)) %>%
  filter(date >= lubridate::ymd(start_date),
         date <= lubridate::ymd(end_date)) %>%
  mutate(departure_time_rounded = substr(as.character(departure_date_rounded), 12, 1000))





my_df <- stop_times_stats_per_stop %>%
  group_by(week_day, departure_time_rounded) %>%
  summarise(n = n(),
            n_dist = n_distinct(stop_id)) %>%
  ungroup() %>%
  mutate(weekday_num = case_when(week_day == "Monday" ~ 7,
                                 week_day == "Tuesday" ~ 6,
                                 week_day == "Wednesday" ~ 5,
                                 week_day == "Thursday" ~ 4,
                                 week_day == "Friday" ~ 3,
                                 week_day == "Saturday" ~ 2,
                                 week_day == "Sunday" ~ 1)) %>%
  mutate(departure_time_rounded = as.factor(substr(departure_time_rounded,1 ,5)))


n_white_gaps <- 0

label_data <- my_df %>%
  select(departure_time_rounded) %>%
  distinct() %>%
  mutate(angle = 90 - 360 * (as.numeric(departure_time_rounded)-0.5) / (n() + n_white_gaps)) %>%
  mutate(hjust = ifelse(angle < -90, 1, 0)) %>%
  mutate(angle = ifelse(angle < -90, angle+180, angle))


my_colour_scale <- colorRampPalette(c("grey10", "red", "yellow", "lightyellow"))


p3 <- my_df%>%
  ggplot(aes(y = weekday_num,
             x = departure_time_rounded,
             fill = n ))+
  geom_tile(col = 'lightgrey') +
  scale_fill_gradientn(colours = my_colour_scale(256))+
  labs(y = "time",
       x = "day of week") +
  theme_void() +
  scale_y_continuous(limits = c(-4, 8)) +
  coord_polar(start = 0, clip = "off") +
  geom_text(
    data = tibble(
      y = 1:7,
      x = 0.5,
      labels =  rev(c("Mon",
                      "Tues",
                      "Wed",
                      "Thurs" ,
                      "Fri",
                      "Sat",
                      "Sun"))
    ),
    aes(x = x ,
        y = y,
        label = labels),
    hjust = 1,
    col = "white",
    fontface =  "bold",
    inherit.aes = F
  ) +
  geom_text(
    data = label_data,
    aes(
      x = departure_time_rounded,
      y = 7.5,
      label = departure_time_rounded,
      hjust = hjust
    ),
    color = "black",
    fontface =  "bold",
    angle = label_data$angle,
    inherit.aes = FALSE
  ) +
  labs(fill = "number of stops")
p3
ggsave("plots/p3.pdf", p3, width  = 10, height = 9)



bounding_box <- st_bbox(city_shape_file)

grid <- expand.grid(seq(bounding_box[1], bounding_box[3], by = grid_size),
                    seq(bounding_box[2], bounding_box[4], by = grid_size)) %>%
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




subset_shape_p3 <- ggplot()+
  geom_sf(data = city_shape_file, fill = "red", alpha = .5) +
  geom_sf(data = grid, fill = "white", col = "white", size = .2, alpha = .5)+
  theme_void() +
  theme(plot.background = element_rect(fill = "black", colour = "black"),
        title = element_text(hjust=1, colour="white", size = 8),
        axis.title.x = element_blank())

ggsave("subset_shape_p3.png", subset_shape_p3, width = 15, height = 10, dpi = 600)


i <- 10
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
  #mode = c("CAR"),
  maxWalkDistance = max_walking_distance,
  date_time = date_and_time,
  cutoffSec = seq(5, 120, 5) * 60
)
