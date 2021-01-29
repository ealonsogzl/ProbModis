#' downloadS2
#'Not implemented yet
downloadS2=function(study_area_boundaries, time_window, username, password, max_cloud, out_path, do1C, tiles = c("ALL"), LTAorder= T, buff=10, parallel = F, rm_summer = T, clean = T ){
  if (!requireNamespace("sen2r", quietly = TRUE)) {
    warning("The sen2r package must be installed to use this functionality")
    return(NULL)
  }
  #Setup scihubAPI and find s2 images
  sen2r::write_scihub_login(username,password,check =T, append = F)
  #check format of study area
  if(!class(study_area_boundaries)[1] %in% c("sf", "sfc", "sfg")){
    study_area_boundaries=sf::st_as_sf(study_area_boundaries)
  }

  #look for the S2 scenes
  list_safe = sen2r::s2_list(spatial_extent = study_area_boundaries, time_interval = time_window, max_cloud = max_cloud)

  #remove summers
  if(rm_summer){
    ava_dates = sen2r::safe_getMetadata(list_safe, "nameinfo")
    ava_dates = lubridate::month(as.Date(ava_dates$sensing_datetime))
    list_safe = list_safe[!(ava_dates %in% c(7, 8, 9))]
  }

  if(tiles != "ALL"){
    ava_tiles = sen2r::safe_getMetadata(list_safe, "nameinfo")$id_tile
    list_safe = list_safe[(ava_tiles %in% tiles)]
  }
  #Check LTA files
  available = sen2r::safe_is_online(list_safe)

  if(LTAorder){
    #Order non available producs
    ordered_prods = s2_order(list_safe[!available])
  }

  #remove LTA scenes from the download request
  list_safe = list_safe[available]
  #retrieve metadata of available S2 scenes
  metadata = sen2r::safe_getMetadata(list_safe, "nameinfo")

  #Download s2 images and calculate the snow cover area
  store = sapply( 1:length(list_safe), s2_get_data,
            metadata, list_safe, study_area_boundaries, out_path, do1C, parallel, buff)


}

