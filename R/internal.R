#' get_file_info
#'
#'
#' @export

get_file_info = function(names){
  #remove dir and extension
  names = basename(names)
  names = substr(names, 1, nchar(names)-4)

  #split by "_"
  name_info =  strsplit(names,split='_', fixed=FALSE)
  name_info = data.frame(matrix(unlist(name_info), nrow=length(names), byrow=T),stringsAsFactors = F)

  #Add colnames
  if(dim(name_info)[2]==2){
    colnames(name_info) = c("Product","date")
  }else if(dim(name_info)[2]==3){
    colnames(name_info) = c("Product","date", "tile")
  }else if(dim(name_info)[2]==4){
    colnames(name_info) = c("Product","date", "tile", "merged")
  }else{
    stop("identification from name error")
  }

  #convert strings to dates
  name_info$date = as.Date.character(name_info$date,format = "%Y%m%d")

  return(name_info)
}

#' mod_fSCA
#'
#'
#' @export

mod_fSCA = function(x, slp = 1.21 , intrcp = 6){
  fsca = x*slp + intrcp
  fsca[fsca>100] = 100
  fsca[fsca<0] = 0
  return(fsca)
}

#' s2_probability
#'
#' @importFrom terra nlyr resample app
#' @export

s2_probability = function(MOD_stack, S2_stack){

  if(class(MOD_stack)[1] != "SpatRaster" | class(S2_stack)[1] != "SpatRaster") {
    stop("Provide a multiband SpatRaster")
  }

  if(terra::nlyr(MOD_stack) != terra::nlyr(S2_stack)){
    stop("Different number of lyrs")
  }

  MOD_stack_20_dir = paste0(tempfile(),".tiff")
  MOD_stack_20 = terra::resample(MOD_stack,S2_stack, method ="near",
                                 MOD_stack_20_dir)

  all_stack_20 = c(MOD_stack_20,S2_stack)
  sen_prob_dir = paste0(tempfile(),".tif")
  sen_prob=terra::app(all_stack_20, fun=calc_prob,filename = sen_prob_dir)

  return(sen_prob)
}

calc_prob = function(x){ # x es el vector MODIS20 + sentinel,
  #implement it in c++ cppFunction?

  MODIS_temp = x[1:(length(x)/2)]
  sentinel_temp = x[((length(x)/2) + 1):length(x)]

  id = which(MODIS_temp > 10 & MODIS_temp < 90 & !is.nan(sentinel_temp))

  if(length(id) < 1){
    #print("pixel malo")
    resultado = sentinel_temp[id]

  }else{
    resultado = sum(sentinel_temp[id])/length(id)

  }
  if(length(resultado) == 0){
    resultado =NA
  }
  return(c(s2_prob = resultado, n_cases =length(id)))
}
