#' modissnow_get_data
#' Internal function. download MODIS scene
#'
#' @param date date to request
#' @param sat satellite
#' @param h h coordinate
#' @param v v cordinate
#' @param user username
#' @param passwd user password
#' @param clean Clean the temp filesystem
#'
#' @importFrom httr authenticate GET write_disk
#' @importFrom xml2 read_html
#' @importFrom rvest html_table
#'
#' @keywords internal
modissnow_get_data = function(date, sat, h, v, user, passwd, clean = T) {

  folder_date = base::format(date, "%Y.%m.%d")
  url = if(sat == 'MYD10A1') {
    paste0('https://n5eil01u.ecs.nsidc.org/MOSA/', sat, '.006/', folder_date, '/')
  } else {
    paste0('https://n5eil01u.ecs.nsidc.org/MOST/', sat, '.006/', folder_date, '/')
  }

  # Download available files
  auth = httr::authenticate(user, passwd)
  req = httr::GET(url, auth)
  req = xml2::read_html(req)
  fls = rvest::html_table(req)[[1]]$Name
  fls = fls[grepl("hdf$", fls)]
  tile = fls[grepl(
    paste0(sat, ".A", lubridate::year(date), "[0-9]{3}.h", formatC(h, width = 2, flag = 0), "v", formatC(v, width = 2, flag = 0)),
    fls)]

  if (length(tile) != 1) {
    print("Requested tile not found")
    return(NULL)
  }

  out_file = file.path(tempdir(), tile)

  httr::GET(paste(url, tile, sep = "/"), auth,
            httr::write_disk(out_file, overwrite = TRUE))

  sds = terra::rast(out_file)

  if(clean){
    unlink(out_file, recursive = T)
  }

  return(sds)
}

#' tidy_modis
#' Internal function. Clean modis scenes
#'
#' @param modis_tile raster modis file
#' @param name_out name of the file
#'
#' @keywords internal
#'
#' @importFrom terra rast writeRaster


tidy_modis=function(modis_tile, name_out){
  modis_tile[modis_tile == 250] =NA
  modis_tile[modis_tile > 100] =NA
  #Note: if there are no values, NA not recogninced when read
  terra::writeRaster(modis_tile, name_out,gdal=c("COMPRESS=LZW"))
}
