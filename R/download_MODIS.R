#' downloadMODIS
#'
#' Download and preprocess Snow Cover Daily MODIS products. The outputs will be cloud masked NDSI products and stored in the provided directory. If the file exists it will not be overwritten.
#'
#' Highly modified from the 'MODISSnow' package
#'
#' @param study_area_boundaries "SpatialPolygonsDataFrame", "SpatVector", "SpatialPolygons". Boundaries of the study area
#' @param date "Date", "POSIXlt", "POSIXct". Date to download
#' @param satellite "character". Satellite to download. One of:
#'                               \itemize{
#'                               \item "MYD10A1" - Download Aqua
#'                               \item"MOD10A1" - Doownload Terra
#'                               \item"Combined" - Combination of Terra and Aqua products. Terra missing values are filled with Aqua
#'                               }
#' @param username "character". MODIS download username aunthetification
#' @param password "character". MODIS download password aunthetification
#' @param out_path "character". Output directory, if out_path do not exist it will be created
#' @param buff "integrer". Number off cells included as buffer in the procesing
#'
#'
#'
#' @examples
#' \dontrun{
#' # Load a shapefile
#' data("Pineta")
#'
#' #create temporal dir to store the data
#' out_path = tempdir()
#'
#' # Download MODIS NDSI product (use your own credentials)
#' downloadMODIS(study_area_boundaries = Pineta,
#'               date = as.Date("2015-06-01"),
#'               satellite  = "Combined",
#'               username = "user",
#'               password = "pass",
#'               out_path = out_path)
#'
#' #List files in out_path
#' mod_files = list.files(out_path,full.names = T)
#' }
#'
#' @importFrom terra vect project crs crop ext xmin xmax ymin ymax merge
#'
#' @export

downloadMODIS=function(study_area_boundaries, date, satellite, username, password, out_path, buff=3 ){

  if (!class(study_area_boundaries) %in% c("SpatialPolygonsDataFrame", "SpatVector", "SpatialPolygons")) {
    stop("The study area should be a spatial object [SpatialPolygonsDataFrame, SpatVector, SpatialPolygons]")
  }
  if (!class(date) %in% c("Date", "POSIXlt", "POSIXct")) {
    stop("Date should be an object of class Date")
  }

  if (!dir.exists(out_path)) {
    print(paste("Creating:", out_path))
    dir.create(out_path)
  }
  if (!satellite %in% c("MYD10A1", "MOD10A1","Combined")) {
    stop("Satellite not implemented")
  }

  if (missing(username) || missing(password)) {
    stop("Username and password for earthdata are required")
  }

  if(date < lubridate::ymd("2002-07-05") & satellite == "Combined"){
    print("Combination not posible. Using MOD10A1 instead")
    satellite = "MOD10A1"
  }

  #Name of the output
  name_out= file.path(out_path,paste0("MODISsca_",gsub("-","",date),".tif" ))

  #check if the files allready exists

  if(!file.exists(name_out)){

    print(paste("Downloading:", as.character(date)))

    #Find objetive tiles
    data("MODIS_tiles")

    MODIS_tiles = terra::vect(MODIS_tiles)
    if(class(study_area_boundaries)[1] != "SpatVector"){
      study_area_boundaries = terra::vect(study_area_boundaries)
    }

    #Extract intersected h and v info
    study_area_boundaries = terra::project(study_area_boundaries,terra::crs(MODIS_tiles))
    MODIS_crop = terra::crop(MODIS_tiles,study_area_boundaries)

    h = as.character(MODIS_crop$h)
    v = as.character(MODIS_crop$v)


    #Buffer to the study area
    border =  terra::ext(c(terra::xmin(study_area_boundaries) -500* buff,
                           terra::xmax(study_area_boundaries) +500* buff,
                           terra::ymin(study_area_boundaries) -500* buff,
                           terra::ymax(study_area_boundaries) +500* buff))

    if(satellite == "Combined"){
      modis_tile_MYD=mapply(modissnow_get_data, date, h=as.numeric(h), v=as.numeric(v),
                            user = username, passwd = password, sat = "MYD10A1")
      modis_tile_MOD=mapply(modissnow_get_data, date, h=as.numeric(h), v=as.numeric(v),
                            user = username, passwd = password, sat = "MOD10A1")

      if(length(modis_tile_MYD)>1){
        modis_tile_MYD = do.call(terra::merge, modis_tile_MYD)
        modis_tile_MOD = do.call(terra::merge, modis_tile_MOD)

      }else{
        modis_tile_MYD = modis_tile_MYD[[1]]
        modis_tile_MOD = modis_tile_MOD[[1]]
      }


      modis_tile_MYD = try(terra::crop(modis_tile_MYD[[1]], border),silent = T)
      modis_tile_MOD = try(terra::crop(modis_tile_MOD[[1]], border),silent = T)

      #Check downloads
      if(class(modis_tile_MOD) != "try-error" & class(modis_tile_MYD) != "try-error"){

        print("Combinin scenes")
        modis_tile_MOD[is.na(modis_tile_MOD)] = 200
        modis_tile_MOD[is.na(modis_tile_MYD)] = 200

        #Combine both images, priority for MOD10A1
        modis_tile_MYD.arr=terra::values(modis_tile_MYD)
        modis_tile_MOD.arr=terra::values(modis_tile_MOD)
        modis_tile_MOD.arr[modis_tile_MOD.arr > 100] = modis_tile_MYD.arr[modis_tile_MOD.arr > 100]
        terra::values(modis_tile_MOD) = modis_tile_MOD.arr

        modis_tile = modis_tile_MOD
        tidy_modis(modis_tile, name_out)

      }else if(class(modis_tile_MYD) != "try-error" & class(modis_tile_MOD) == "try-error"){
        warning("modis_tile_MOD missed")
        modis_tile_MOD[is.na(modis_tile_MYD)] = 200
        modis_tile = modis_tile_MYD
        tidy_modis(modis_tile, name_out)
      }else if(class(modis_tile_MYD) == "try-error" & class(modis_tile_MOD) != "try-error"){
        warning("modis_tile_MYD missed")
        modis_tile_MOD[is.na(modis_tile_MOD)] = 200
        modis_tile = modis_tile_MOD
        tidy_modis(modis_tile, name_out)
      }else{
        return(NULL)
      }

    }else{

      modis_tile=mapply(modissnow_get_data,date,h=as.numeric(h),v=as.numeric(v),
                        user = username, passwd = password, sat = satellite)

      if(length(modis_tile)>1){
        modis_tile = do.call(terra::merge, modis_tile)
      }else{
        modis_tile = modis_tile[[1]]
      }


      modis_tile = terra::crop(modis_tile[[1]], border)
      tidy_modis(modis_tile, name_out)
    }
  }
}

