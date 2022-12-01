# Creating grid and run OTP:

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
                           substr(as.character(format(round(lon, 7), nsmall = 7)),1 ,9))) %>% 
  rename(end_id = id)


# Expected travel time:

# create empty lists to store results
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
      mutate(start_id = id)%>%
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



# Number of people served by each point of the grid:

# compute voronos
my_vor_2 <- st_as_sf(terra::voronoi(terra::vect(grid_2))) %>% 
  st_intersection(city_shape_file)

my_vor_2$pop <- as.numeric(extract(population_data_city_brick,my_vor_2,fun=sum, na.rm =TRUE))


# Format the data into a format that is more manageable 
org_dest_car_formatted <-  org_dest_car %>% 
  select(start_id, end_id, duration) %>% 
  left_join(my_vor_2 %>% st_drop_geometry() %>% select(id, pop),
            by = c("start_id" = "id"))

org_dest_PS_formatted <- org_dest_PS %>% 
  select(start_id, end_id, duration) %>% 
  left_join(my_vor_2 %>% st_drop_geometry() %>% select(id, pop),
            by = c("start_id" = "id"))

# combine the car and public transport data
org_dest_PS_car_formatted <- bind_rows("car" = org_dest_car_formatted,
                                       "public transport" = org_dest_PS_formatted,
                                       .id = "mode")

# compute ratio travel time public transport and car
org_dest_PS_car_formatted %>% 
  st_drop_geometry() %>% 
  pivot_wider(names_from = mode, values_from = duration) %>% 
  mutate(ratio = `public transport`/car) %>% 
  summarise(mean_ratio = mean(ratio, na.rm = TRUE),
            weighted_mean_ratio = weighted.mean(ratio, na.rm = TRUE, w = pop))  %>% 
  kableExtra::kable() %>% 
  kableExtra::kable_styling(bootstrap_options = c("striped", "hover"))



# For each starting point (order from most to least densely populated) the distribution of travel time to all the other points:

library(ggridges)


dens_plot <- org_dest_PS_car_formatted %>%
  mutate(label = as.numeric(as.factor(start_id))) %>%
  mutate(label = glue("{label} ({format_bignum(round(pop))})")) %>%
  ggplot(aes(
    x = duration,
    y =  fct_reorder(label, pop),
    alpha = pop,
    fill = mode,
    col = mode
  )) +
  geom_density_ridges(
    jittered_points = TRUE,
    scale = 2,
    rel_min_height = 0.01,
    point_shape = "|",
    point_size = 3,
    size = 0.25,
    position = position_points_jitter(height = 0)
  ) +
  scale_x_continuous(labels = seconds_to_period, 
                     breaks = seq(0, 8000, 1800)) +
  scale_fill_manual(
    values = c("#D55E0050", "#0072B250"),
    labels = c("car", "public transport")
  ) +
  scale_color_manual(values = c("#D55E00", "#0072B2"), guide = "none") +
  scale_discrete_manual("point_color",
                        values = c("#D55E00", "#0072B2"),
                        guide = "none") +
  coord_cartesian(clip = "off", expand = FALSE) +
  guides(fill = guide_legend(override.aes = list(
    fill = c("#D55E00A0", "#0072B2A0"),
    color = NA,
    point_color = NA,
    title = "transport mode"
  )),
  alpha =  guide_legend(title = "population around start point")) +
  scale_alpha_continuous(range = c(0.1, 0.95), breaks = seq(0, 31000, 5000)) +
  theme_ridges(center = TRUE) +
  theme(legend.position = "bottom") +
  labs(x = "travel time in minutes from origin point to destination points",
       y = "ID of origin point (total population served between brackets)")


dens_plot
