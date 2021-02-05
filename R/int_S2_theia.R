#Theia native support, not implemented yet
# theia_token = function(username, password, server){
#     #token dies after two hours
# }
#
# theia_querry =function(theia_token,...){
# }

#' setup_theia
#' Internal function. Setup theia downloads
#'
#' @param username username
#' @param password password
#'
#' @keywords internal

setup_theia=function(username,password){

  zip_dest = file.path(tempdir(),"theia.zip")
  download.file("https://github.com/ealonsogzl/theia_download/archive/master.zip",
                destfile = zip_dest)
  unzip(zip_dest,
        exdir = tempdir(),
        overwrite = T)


  cfg_dest_sentinel = file.path(tempdir(),"theia_download-master","config_theia.cfg")
  cfg_theia = read.table(cfg_dest_sentinel,header=F)
  cfg_theia = as.matrix(cfg_theia)
  cfg_theia[cfg_theia[]=="LOGUIN_THEIA"] = username
  cfg_theia[cfg_theia=="PASSWD_THEIA"] = password
  write.table(cfg_theia,
              file.path(tempdir(),"theia_download-master","config_theia.cfg"),
              row.names=FALSE, col.names = FALSE, quote = FALSE)

  cfg_dest_landsat = file.path(tempdir(),"theia_download-master","config_landsat.cfg")
  cfg_theia = read.table(cfg_dest_landsat,header=F)
  cfg_theia = as.matrix(cfg_theia)
  cfg_theia[cfg_theia=="LOGUIN_THEIA"] = username
  cfg_theia[cfg_theia=="PASSWD_THEIA"] = password
  write.table(cfg_theia,
              file.path(tempdir(),"theia_download-master","config_landsat.cfg"),
              row.names=FALSE, col.names = FALSE, quote = FALSE)

  theia_downloader = file.path(tempdir(),"theia_download-master","theia_download.py")
  sentinel_cfg = file.path(tempdir(),"theia_download-master","config_theia.cfg")
  lansat_cfg = file.path(tempdir(),"theia_download-master","config_landsat.cfg")

  return(list(theia_downloader = theia_downloader,
         sentinel_cfg = sentinel_cfg))

  # return(list(theia_downloader = theia_downloader,
  #             sentinel_cfg = sentinel_cfg,
  #             lansat_cfg = lansat_cfg))
}

#' s2_theia_get_data
#' Internal function. Setup theia downloads
#'
#' @param study_area_boundaries username
#' @param time_window password
#' @param out_path username
#' @param max_cloud password
#' @param theia_instr username
#' @param buff password
#' @param tile password
#' @param avoid password
#' @param product
#' @param clean
#'
#' @keywords internal
#'

s2_theia_get_data = function(study_area_boundaries, time_window, out_path, max_cloud,
                             theia_instr, buff, tile = NULL, avoid = NULL, product = "Snow", clean=T){
  `%m+%` <- lubridate::`%m+%`
  tmp_storage = file.path(tempdir(),"theia_tmp_sto")
  if(dir.exists(tmp_storage)){
    unlink(tmp_storage, recursive = T)
  }

  dir.create(tmp_storage, showWarnings = FALSE)

  if(is.null(tile)){
    lat_max = terra::ymax(study_area_boundaries)
    lat_min = terra::ymin(study_area_boundaries)
    long_max = terra::xmax(study_area_boundaries)
    long_min = terra::xmin(study_area_boundaries)
  }

  dates = seq.Date(time_window[1],time_window[2], "month")

  #Quitar meses no necesarios
  if(!is.null(avoid)){
    dates = dates[!(lubridate::month(dates) %in% avoid)]
  }
  # si solo se pide un mes, añadir el final
  if(length(dates) == 1){
    dates=c(dates,dates %m+% months(1))
  }



  for (id in 1:(length(dates)-1)){

    id_bgn = dates[id]
    id_end = dates[id]  %m+% months(1)

    if(id_end - id_bgn > 31){ #saltar si la diferencia es mas de 31 dias para no hacer los avoid
      next
    }

    print(paste0("Downloading  S2 dates:", id_bgn, "to", id_end))

    if(is.null(tile)){
      sys_command = paste("python",
                          theia_instr$theia_downloader,
                          "-w", tmp_storage,
                          "-m", max_cloud,
                          "--lonmin", long_min,
                          "--lonmax", long_max,
                          "--latmin", lat_min,
                          "--latmax", lat_max,
                          "-c", product,
                          "-a", theia_instr$sentinel_cfg,
                          "-d", as.character(id_bgn),
                          "-f", as.character(id_end))
    }else {
      sys_command = paste("python",
                          theia_instr$theia_downloader,
                          "-w", tmp_storage,
                          "-m", max_cloud,
                          "-t", tile,
                          "-c", product,
                          "-a", theia_instr$sentinel_cfg,
                          "-d", as.character(id_bgn),
                          "-f", as.character(id_end))
    }

    if(.Platform$OS.type == "unix") {
      sys_command = paste("cd ",  tempdir(), "&&", sys_command)
      system(sys_command)
    } else if(.Platform$OS.type == "windows") {
      sys_command = paste("pushd ",  tempdir(), "&&", sys_command)
      shell(sys_command)
    }else {
      print( paste(.Platform$OS.type, "sytem not implemented yet"))
    }

    new_zips = list.files(tmp_storage,full.names = T, pattern = "*zip")

    #check if theia comes from landsat
    if(length(grep("LANDSAT",new_zips))>0){ #Landsat not suported yet
      file.remove(new_zips[grep("LANDSAT",new_zips)])
      new_zips = new_zips[-grep("LANDSAT",new_zips)]
      #stop("borrar landsat")
    }
    #Skipp iteration if no scenes are available
    if(length(new_zips) == 0) {
      next
    }
    tidy_zipped_theiasnow(new_zips, study_area_boundaries, out_path, buff)

    if(clean){
     file.remove(new_zips)
     file.remove(list.files(tempdir(),pattern ="spat",full.names = T))
    }

  }

}


tidy_zipped_theiasnow=function(files, study_area_boundaries, out_path, buff){

  border =  terra::ext(c(terra::xmin(study_area_boundaries) -20* buff,
                         terra::xmax(study_area_boundaries) +20* buff,
                         terra::ymin(study_area_boundaries) -20* buff,
                         terra::ymax(study_area_boundaries) +20* buff))

  for (n in 1:length(files)) {
    #unzip files
    unzip(files[n],
          exdir = dirname(files[n]),
          overwrite = T)

    #list files of the unzip
    ziped_data = unzip(files[n], list = TRUE)

    #find theia snow raster
    snow_ras_name = file.path(dirname(files[n]), ziped_data[grep("SNW_R2.tif",ziped_data$Name),1])

    #read theia raster
    snow_ras = terra::rast(snow_ras_name)

    #change boundaries proyection
    study_area_boundaries = terra::project(study_area_boundaries,snow_ras)

    #create border
    border =  terra::ext(c(terra::xmin(study_area_boundaries) -20* buff,
                           terra::xmax(study_area_boundaries) +20* buff,
                           terra::ymin(study_area_boundaries) -20* buff,
                           terra::ymax(study_area_boundaries) +20* buff))

    #crop snow raster
    snow_ras = terra::crop(snow_ras,border)

    #reclassify raster
    snow_ras[snow_ras == 205] = NA #Clouds and shadows
    snow_ras[snow_ras == 254] = NA #Nodata
    snow_ras[snow_ras == 100] = 1  #snow data
    snow_ras[snow_ras == 255] = NA #out of the orbit? fill value? not documented

    #create name
    date = substr(names(snow_ras),12,19)
    tile = substr(names(snow_ras),41,46)
    name_out = file.path(out_path,paste0("THEIAsca_",date,"_",tile,".tif"))

    #Write raster
    terra::writeRaster(snow_ras, name_out, overwrite = T,format="GTIFF",
                       wopt=list(gdal=c("COMPRESS=LZW","PREDICTOR=2"))) #datatype=c("INT2S") to save a bit of space

    #Remove tmp dirs
    unlink(dirname(snow_ras_name),recursive = TRUE)

  }
}
