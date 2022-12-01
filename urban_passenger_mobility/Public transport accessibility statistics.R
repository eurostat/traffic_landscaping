# Using a radius: 

# load stops
all_stops <- subset_gtfs_file$stops %>%
  st_as_sf(coords = c("stop_lon", "stop_lat")) %>%
  st_set_crs(st_crs("+proj=longlat"))

# draw a 500 meter buffer around the sops and combine the radiuses
# into a single polygon
subset_stops_buffer <- st_union(st_buffer(all_stops,dist = 500))
subset_stops_buffer <- st_cast(subset_stops_buffer, "MULTIPOLYGON") %>%
  st_as_sf()

# calculate the percentage of the population that lives within this
# polygon 
round(sum(raster::extract(population_data_city_brick,
                          subset_stops_buffer,fun=sum, na.rm =TRUE)) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE) *100, 2)



# 500m distance:

# set up a datafram with just the lng/lat over every stop
all_stops_simple <- all_stops %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2])  %>%
  st_drop_geometry() %>% 
  select(stop_id , lon, lat)

# create empty tible for results
results <- tibble()

for(i in 1:nrow(all_stops_simple)){
  tryCatch({ # include a tryCatch to continue if there is an error
    res <- ors_isochrones(all_stops_simple %>%
                            slice(i) %>% 
                            select(-stop_id),
                          range = 500, 
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

# combine all the results
walking_dist_500_m <- st_union(results) %>% 
  st_as_sf()


round(sum(raster::extract(population_data_city_brick,
                          walking_dist_500_m,fun=sum, na.rm = TRUE)) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE) *100, 1)




# Restrictions:

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


# Filter for stops that are serviced at least twice on workdays between 7 am and 9 am 
selected_stop_ids <- stop_times_stats_per_stop %>% 
  filter(!week_day %in% c("Saturday", "Sunday")) %>% 
  select(stop_id, departure_date) %>% 
  mutate(departure_date_standardized =ymd_hms(paste0("2022-01-01 ", substr(as.character(departure_date), 12, 20)))) %>% 
  filter(departure_date_standardized < ymd_hms(paste0("2022-01-01 09:00:00")),
         departure_date_standardized > ymd_hms(paste0("2022-01-01 07:00:00"))) %>% 
  count(stop_id) %>% 
  filter(n >= 5 *2) %>%  # filter only stops that occur at least twice (on average for the 5 days in this week)
  pull(stop_id)

# Use the same code to compute the combined isodistance 
# shapefiles for just the filtered stops
filtered_results_mornings <- results %>% 
  filter(stop_id %in%selected_stop_ids) 

filtered_walking_dist_500_m_morings <- st_union(filtered_results_mornings) %>% st_as_sf()

round(sum(raster::extract(population_data_city_brick,
                          filtered_walking_dist_500_m_morings,fun=sum, na.rm =TRUE)) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE) *100, 1)




# Wheelchair accessible stops:

# filter for only stops that are wheelchair accessible
selected_stop_ids_wheelchair <- all_stops %>% 
  filter(wheelchair_boarding == 1) %>% 
  pull(stop_id )

filtered_results_wheel_chair <- results %>% 
  filter(stop_id %in%selected_stop_ids_wheelchair) 


filtered_walking_dist_500_m_wheelchair <- st_union(filtered_results_wheel_chair) %>% st_as_sf()

round(sum(raster::extract(population_data_city_brick,filtered_walking_dist_500_m_wheelchair,fun=sum, na.rm =TRUE)) /
  sum(as.matrix(population_data_city_brick), na.rm = TRUE) *100, 1)
