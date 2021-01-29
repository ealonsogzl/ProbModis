library(MODISSnow)
username="itsasois"
password="ifyoucanplayonth!"
time_window <- c(as.Date("2015-12-01"),Sys.Date())
data("Picos_de_Europa")
study_area_boundaries=Picos_de_Europa
max_cloud = 30
buff=10
tiles = c("30TUN")
out_path ="/home/esteban/Documentos/GIT/snowMODIS/borrar/out_sentinel"
downloadS2(study_area_boundaries, time_window,
           username, password,
           max_cloud, out_path,tiles = tiles,
           buff=10, LTAorder= T, do1C =T,
           parallel = T, clean = T )


############################################

library(MODISSnow)
username="itsasois"
password="ifyoucanplayonth!"
time_window <- c(as.Date("2015-12-01"),Sys.Date())
data("Picos_de_Europa")
study_area_boundaries=Picos_de_Europa
max_cloud = 30

#!!!!!!!instalar install_sen2cor()
