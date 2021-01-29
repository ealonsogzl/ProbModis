s2_get_data = function(n, metadata, list_safe, study_area_boundaries, out_path, do1C, parallel, buff, clean = T){

  #create output name
  date_request = metadata$sensing_datetime[[n]]
  hour = substr(date_request,12,19)
  hour = unlist(strsplit(hour, ":"))
  hour = as.numeric(hour) %*% c(3600, 60, 1)
  date_request = substr(date_request,1,10)
  date_request = gsub("-","",date_request)
  tile  = metadata$id_tile[n]
  level= metadata$level[n]
  name_out= file.path(out_path,paste0("S2sca_",date_request,"_",tile,".tif" ))

  if(!file.exists(name_out)){
    #cat(name_out)
    if(do1C & level == "1C"){ #descargar si es LC1
      check_donwload = try(sen2r::s2_download(list_safe[n], outdir = tempdir(),  order_lta = T))

      if(class(check_donwload)[1] == "try-error"){
        return(NULL)
      }
      #cat("running sen2cor, tomate un cafe)
      err_catch=try(sen2cor(
        names(check_donwload),
        l1c_dir = tempdir(),
        outdir = tempdir(),
        use_dem = TRUE,
        parallel = parallel,
        timeout = 2700,
        kill_errored = TRUE,
        overwrite = TRUE
      ))

      if(class(err_catch)[1] == "try-error"){
        #cat("error in sen2cor, probably killed by R")
        if(clean){
          unlink(s2_tmp_loc, recursive = T)
        }
        return(NULL)
      }

      s2_tmp_loc = err_catch
      err_catch_tdy_LC1 =try(tidy_s2(s2_tmp_loc, name_out, study_area_boundaries, level, buff)) # this is a bit tricky, catch if sen2cor outputs are wrong.

      if(class(err_catch)[1] == "try-error"){
        #cat("tidy_s2 fail, probably sens2cor did not the work properlly, tray reinstaling it with sen2r::install_sen2cor(force = T,version = "2.8.0")")
        if(clean){
          unlink(s2_tmp_loc, recursive = T)
        }
        return(NULL)
      }

    }else if(!do1C & level == "1C"){ #NO descargar si es LC1
      #cat("S"_C1 found skipp")
      if(clean){
        unlink(s2_tmp_loc, recursive = T)
      }
      return(NULL)

    }else{ #Descargar si es LC2

      check_donwload = try(sen2r::s2_download(list_safe[n], outdir = tempdir(),  order_lta = T))

      if(is.null(check_donwload)){
        #cat("long term archive")
        if(clean){
          unlink(s2_tmp_loc, recursive = T)
        }
        return(NULL)
      }else if(class(check_donwload)[1] == "try-error"){
        #cat("download error")
        if(clean){
          unlink(s2_tmp_loc, recursive = T)
        }
        return(NULL)
      }

      s2_tmp_loc=file.path(tempdir(),names(list_safe[n]))
      tidy_s2(s2_tmp_loc, name_out, study_area_boundaries, level, buff)
    }

    if(clean){
      unlink(s2_tmp_loc, recursive = T)
    }
  }else{
    #cat("existe outfile ")
  }

}

tidy_s2 = function(s2_tmp_loc, name_out, study_area_boundaries, level, buff){

  #Locate bands and cloud mask
  dirs_tmp = list.dirs(path = s2_tmp_loc)
  dirs_tmp = dirs_tmp[grep("R20m", dirs_tmp)]

  scl = terra::rast(list.files(dirs_tmp,"SCL",full.names = T))

  #Define study area border
  study_area_boundaries= terra::vect(study_area_boundaries)
  study_area_boundaries = terra::project(study_area_boundaries,scl)

  border =  terra::ext(c(terra::xmin(study_area_boundaries) -20* buff,
                         terra::xmax(study_area_boundaries) +20* buff,
                         terra::ymin(study_area_boundaries) -20* buff,
                         terra::ymax(study_area_boundaries) +20* buff))
  #crop to study area
  scl=terra::crop(scl,border)

  #create cloud mask
  clouds=scl
  clouds[]=NA
  clouds[scl == 3] = 1 # cloud shadow
  #  clouds[scl == 7] = 1 # Clouds, low probability
  clouds[scl == 8] = 1 # Clouds, medium probability
  clouds[scl == 9] = 1 # Clouds, high probability
  #  clouds[scl == 10] = 1 #Cirrus

  band_files = list.files(dirs_tmp, full.names = T, recursive = T)

  #read S2 bands and crop to study borders
  swir = terra::rast(band_files[grep("B12",band_files)])
  swir = terra::crop(swir,border)
  green = terra::rast(band_files[grep("B03",band_files)])
  green = terra::crop(green,border)
  red = terra::rast(band_files[grep("B04",band_files)])
  red = terra::crop(red,border)

  #Calculate ndsi
  ndsi = (green-swir)/(green+swir)
  ndsi[ndsi > 1] = 1; ndsi[ndsi < (-1)] = -1

  #Use red band and NDSI to correct snowcover
  SCA = ndsi
  SCA[ndsi>0.4 & red > 0.1] = 1
  SCA[SCA != 1] = 0

  #Mask with clouds
  SCA[clouds == 1] = NA

  terra::writeRaster(SCA, name_out,gdal=c("COMPRESS=LZW"), overwrite = T)

}
