#' downloadS2_theiasnow
#'
#' Download and preprocess Theia snow cover products products. The outputs will be cloud masked binary snow cover stored in the provided directory. If the file exists it will not be overwritten.
#'
#' This interim version uses system calls to the [theia_download script](https://github.com/ealonsogzl/theia_download)
#'
#' @param study_area_boundaries "SpatialPolygonsDataFrame", "SpatVector", "SpatialPolygons". Boundaries of the study area
#' @param time_window "Date", "POSIXlt", "POSIXct". Two date vector storing the begining and end of the time window.
#' @param max_cloud "integrer", Maximun percentage of clouds allowed form 0 to 100 percentage.
#' @param username "character". Theia download username aunthetification
#' @param password "character". Theia download password aunthetification
#' @param out_path "character". Output directory, if out_path do not exist it will be created
#' @param buff "integrer". Number off cells included as buffer in the procesing
#' @param tile "character". Optional. Tile to download
#' @param avoid "integrer". Optional. Numeric vector with the months that should not be downlaoded.
#'
#' @examples
#' \dontrun{
#' # Load a shapefile
#' data("Pineta")
#'
#' #create temporal dir to store the data
#' out_path = tempdir()
#'
#' # Download Theia snow cover products (use your own credentials)
#' downloadS2_theiasnow(study_area_boundaries = Pineta,
#'               time_window = c(as.Date("2015-08-01"),Sys.Date()),
#'               max_cloud = 30,
#'               username = "user",
#'               password = "pass",
#'               out_path = out_path,
#'               avoid = c(7,8) #Avoid to download July and Agust
#'               )
#'
#' #List files in out_path
#' s2_files = list.files(out_path, full.names = T)
#' }
#'
#' @importFrom terra vect project crs
#'
#' @export

downloadS2_theiasnow=function(study_area_boundaries, time_window, max_cloud, username, password, out_path, buff = 10, tile = NULL, avoid = NULL){

  if (!class(study_area_boundaries) %in% c("SpatialPolygonsDataFrame", "SpatVector", "SpatialPolygons")) {
    stop("The study area should be a spatial object [SpatialPolygonsDataFrame, SpatVector, SpatialPolygons]")
  }
  if (!class(time_window) %in% c("Date", "POSIXlt", "POSIXct")) {
    stop("Date should be an object of class Date")
  }
  if (!is.numeric(max_cloud)){
    stop("max_cloud should be an numeric")
  }
  if (missing(username) || missing(password)) {
    stop("Username and password for earthdata are required")
  }
  if(!dir.exists(out_path)){
    dir.create(out_path)
  }
  if(class(study_area_boundaries)[1] != "SpatVector"){
    study_area_boundaries=terra::vect(study_area_boundaries)
  }

  #change boundaries proyection to longlat
  study_area_boundaries = terra::project(study_area_boundaries,"+proj=longlat +datum=WGS84 +no_defs")
  #Setup theia donwload
  theia_instr = setup_theia(username, password)
  #Downlaod
  s2_theia_get_data(study_area_boundaries, time_window, out_path, max_cloud, theia_instr, buff, tile, avoid)

}
