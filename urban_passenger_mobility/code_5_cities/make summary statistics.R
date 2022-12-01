# create stats

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

accesibility_stats_path   <- "accesibility_stats.csv"
output_population_reached <- "population_reached_data.csv"
output_OD_car <- "output_OD_car.rds"
output_OD_PS  <-  "output_OD_PS.rds"


folders <- c("01_Austria", "02_Belgium", "03_Croatia","04_spain",  "05_Finland")


accesibility_stats<-data.table::rbindlist(lapply(folders,FUN = function(x) read_csv(file.path(x,accesibility_stats_path))), fill=TRUE)



df <- tribble(~country_folder ,~urban_area_of_interest, ~path_to_shape_file,~name_layer,~population_data_path,
              "01_Austria", "AT001C1","URAU_RG_100K_2020_3857_CITIES.shp/URAU_RG_100K_2020_3857_CITIES.shp", "URAU_RG_100K_2020_3857_CITIES","aut_ppp_2020_UNadj_constrained.tif",
              "02_Belgium" , "BE001K1","URAU_RG_100K_2020_3857_GREATER_CITIES.shp/URAU_RG_100K_2020_3857_GREATER_CITIES.shp", "URAU_RG_100K_2020_3857_GREATER_CITIES", "bel_ppp_2020_UNadj_constrained.tif",
              "03_Croatia","HR001C1", "URAU_RG_100K_2020_3857_CITIES.shp/URAU_RG_100K_2020_3857_CITIES.shp", "URAU_RG_100K_2020_3857_CITIES","hrv_ppp_2020_UNadj_constrained.tif",
              "04_spain", "ES001C1","URAU_RG_100K_2020_3857_CITIES.shp/URAU_RG_100K_2020_3857_CITIES.shp", "URAU_RG_100K_2020_3857_CITIES", "esp_ppp_2020_UNadj_constrained.tif",
              "05_Finland", "FI001C2", "URAU_RG_100K_2020_3857_CITIES.shp/URAU_RG_100K_2020_3857_CITIES.shp", "URAU_RG_100K_2020_3857_CITIES", "fin_ppp_2020_UNadj_constrained.tif")

pop_reached_summaries_list <- list()
org_dest_PS_car_formatted_stat_list <- list()

#folder <- "01_Austria"
for(folder in folders){
  sf::sf_use_s2(FALSE)
  
  df_cur <- df %>%
    filter(country_folder == folder)
  path_to_shape_file <- df_cur$path_to_shape_file
  name_layer  <- df_cur$name_layer
  urban_area_of_interest <-    df_cur$urban_area_of_interest
  name_country_folder <-  df_cur$country_folder
  population_data_path <- df_cur$population_data_path
  
  # load shapefile
  cities_shape_files <- read_sf(path_to_shape_file, layer= name_layer) 
  # select FUA
  city_shape_file <- cities_shape_files %>%
    filter(URAU_CODE  == urban_area_of_interest)
  
  # reproject city shapefile to longlat
  city_shape_file <- st_transform(city_shape_file, st_crs("+proj=longlat"))
  
  # extract bounding box of shapefile
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
  
  
  my_vor <- st_as_sf(terra::voronoi(terra::vect(grid))) %>% 
    st_intersection(city_shape_file)
  
  
  population_data      <- terra::rast(file.path(name_country_folder,population_data_path))
  population_data_city <- terra::crop(population_data, city_shape_file)
  population_data_city <- terra::mask(population_data_city,terra::vect(city_shape_file))
  population_data_city_brick <- raster::brick(population_data_city)
  
  population_data_city_brick <- raster::brick(population_data_city)
  my_vor$pop <- as.numeric(extract(population_data_city_brick,my_vor,fun=sum, na.rm =TRUE))
  
  population_reached_data <- read_csv( file.path(name_country_folder,output_population_reached))
  
  
  population_reached_data_pop <- population_reached_data %>% 
    left_join(my_vor %>% 
                select(id, pop) %>% 
                st_drop_geometry(),
              by = "id") 
  
  pop_reached_summaries <- population_reached_data_pop%>% 
    group_by(time  ) %>% 
    summarise(mean = mean(percent_population_reached),
              median = median(percent_population_reached),
              weighted_mean = weighted.mean(percent_population_reached, w = pop)) %>% 
    pivot_longer(cols = -c(time)) %>%
    mutate(country = folder)
  
  pop_reached_summaries_list[[folder]] <-pop_reached_summaries
  
  
  
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
  
  
  # compute voronos
  sf::sf_use_s2(FALSE)
  
  my_vor_2 <- st_as_sf(terra::voronoi(terra::vect(grid_2))) %>% 
    st_intersection(city_shape_file)
  
  my_vor_2$pop <- as.numeric(extract(population_data_city_brick,my_vor_2,fun=sum, na.rm =TRUE))
  
  org_dest_PS <- read_rds(file.path(name_country_folder,output_OD_PS))
  org_dest_car <- read_rds(file.path(name_country_folder,output_OD_car))
  
  
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
  org_dest_PS_car_formatted_stat <- org_dest_PS_car_formatted %>% 
    st_drop_geometry() %>% 
    filter(!is.na(end_id)) %>% 
    pivot_wider(names_from = mode, values_from = duration) %>% 
    mutate(ratio = `public transport`/car) %>% 
    summarise(mean_ratio = mean(ratio, na.rm = TRUE),
              weighted_mean_ratio = weighted.mean(ratio, na.rm = TRUE, w = pop))%>%
    mutate(country = folder)
  
  org_dest_PS_car_formatted_stat_list[[folder]] <-org_dest_PS_car_formatted_stat
  
}

pop_reached_summaries_list
library(plotly)

data_ggp1 <- data.table::rbindlist(pop_reached_summaries_list) %>% 
  as_tibble() %>% 
  mutate( city = case_when(country == "01_Austria" ~ "Vienna (Austria)",
                              country == "02_Belgium" ~ "Brussels (Belgium)",
                              country == "03_Croatia" ~ "Zagreb (Croatia)",
                              country == "04_spain" ~ "Madrid (Spain)",
                              country == "05_Finland" ~ "Helsinki (Finland)"))



write_rds(data_ggp1, "data_ggp1.rds")

ggp1 <- data_ggp1%>%
  mutate(minutes = time/60,
         percent =  round(value*100, 1)) %>% 
  ggplot(aes(x = minutes, y = value, color = city,tooltip = percent)) +
  geom_line( size = 1) +
  facet_wrap(~name) +
  theme_minimal()+
  scale_y_continuous(labels = scales::percent)+
  ggthemes::scale_color_colorblind() 
  

p1 <- plotly::ggplotly(ggp1, tooltip = "percent")

p1 %>% layout(hovermode = "x unified") %>% config(displayModeBar = FALSE)




data_ggp2 <- accesibility_stats %>%
  mutate(wheelchair_accessible = ifelse(city == "Helsinki",wheelchair_accessible/100, wheelchair_accessible)) %>% 
  pivot_longer(cols = -c(total_pop,country,city)) %>% 
mutate( city = case_when(city == "Vienna" ~ "Vienna (Austria)",
                         city == "Brussels" ~ "Brussels (Belgium)",
                         city == "Zagreb" ~ "Zagreb (Croatia)",
                         city == "Madrid" ~ "Madrid (Spain)",
                         city == "Helsinki" ~ "Helsinki (Finland)"))%>% 
  mutate(name =  case_when(name == "percent_500m" ~ "% of people living within a 500m radius of a public transport stop",
                             name == "percent_walk" ~ "% of people living within 500m walking distance of a public transport stop",
                             name == "percent_walk_morning" ~ "% of people living within 500m walking distance of a public transport stop that is served atleast twice on weekday mornings" ,
                             name == "wheelchair_accessible" ~ "% of people living within 500m walking distance of a public wheelchair accessible transport stop")) %>% 
  mutate(name = fct_rev(str_wrap(name, 18))) 

write_rds(data_ggp2, "data_ggp2.rds")


data_ggp2 %>% 
  ggplot(aes(y = value,x = name, fill = city))+
  geom_col(position = "dodge") +
  coord_flip() +
  theme_minimal()+
  labs(x = NULL, y = "percent")+
  scale_y_continuous(labels = scales::percent)+
  ggthemes::scale_fill_colorblind( guide = guide_legend(reverse = TRUE) ) 
  

reverse_legend_labels <- function(plotly_plot) {
  n_labels <- length(plotly_plot$x$data)
  plotly_plot$x$data[1:n_labels] <- plotly_plot$x$data[n_labels:1]
  plotly_plot
}
p2 <- plotly::ggplotly(ggp2, legend_traceorder="reversed")

p2%>% config(displayModeBar = FALSE) %>%
  reverse_legend_labels()


data_ggp3 <- data.table::rbindlist(org_dest_PS_car_formatted_stat_list)%>%
  pivot_longer(cols = -c(country)) %>% 
  mutate( city = case_when(country == "01_Austria" ~ "Vienna (Austria)",
                           country == "02_Belgium" ~ "Brussels (Belgium)",
                           country == "03_Croatia" ~ "Zagreb (Croatia)",
                           country == "04_spain" ~ "Madrid (Spain)",
                           country == "05_Finland" ~ "Helsinki (Finland)")) %>% 
  mutate(name =  case_when(name == "mean_ratio" ~ "mean of ratio of travel times between origin-destination matrix public transport to car travel",
                           name == "weighted_mean_ratio" ~ "weighted mean of ratio (using population at origin) of travel times between origin-destination matrix public transport to car travel")) %>%
  mutate(name = fct_rev(str_wrap(name, 18))) 

write_rds(data_ggp3, "data_ggp3.rds")

data_ggp3 %>% 
  ggplot(aes(y = value,x = name, fill = city))+
  geom_col(position = "dodge") +
  coord_flip() +
  theme_minimal()+
  labs(x = NULL, y = "ratio")+
  ggthemes::scale_fill_colorblind( guide = guide_legend(reverse = TRUE) ) 


p3 <- plotly::ggplotly(ggp3, legend_traceorder="reversed")

p3%>% config(displayModeBar = FALSE) %>%
  reverse_legend_labels()
