library(MODISSnow)
library(terra)
username="e.alonso@ipe.csic.es"
password="Rumania77"
time_window <- c(as.Date("2015-08-01"),Sys.Date())
data("Pineta")
study_area_boundaries=Pineta
max_cloud = 30
tile = NULL
out_path ="/home/esteban/Documentos/GIT/snowMODIS/borrar/out_sentinel"
avoid = c(7,8,9)



downloadS2_theiasnow(out_path, study_area_boundaries, time_window, max_cloud, username, password, avoid = avoid)

theai_sca = list.files(out_path, full.names = T, pattern = "*.tif")

metadata = get_file_info(theai_sca)

sapply(metadata$date, downloadMODIS,
        study_area_boundaries=study_area_boundaries, satellite = "Combined",
        username = "ealonso", password = "Rumania77",
        out_path ="/home/esteban/Documentos/GIT/snowMODIS/borrar/out_modis")



modis_ndsi = list.files( "/home/esteban/Documentos/GIT/snowMODIS/borrar/out_modis", full.names = T, pattern = "*.tif")
metada_mod = get_file_info(modis_ndsi)

if(length(metadata$date) != length(metada_mod$date)){
  stop("differetn number of tles, not implemented yet")
}

MOD_stack = terra::rast(modis_ndsi)
MOD_stack = mod_fSCA(MOD_stack)
S2_stack = terra::rast(theai_sca)




sen_prob=s2_probability(MOD_stack, S2_stack)

############ZOOM prubea


