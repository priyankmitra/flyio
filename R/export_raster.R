#' Write raster
#' @param x variable name
#' @param file path of the file to be written to
#' @param FUN the function using which the file is to write
#' @param data_source the name of the data source, if not set globally. s3, gcs or local
#' @param bucket the name of the bucket, if not set globally
#' @param ... other parameters for the FUN function defined above
#' @export "export_raster"
#' @return No output
#'
#' @examples
#' \dontrun{
#' flyio_set_datasource("gcs")
#' flyio_set_bucket("socialcops-test")
#' export_raster(t, "tests/testras.tif", writeRaster, format = "GTiff")
#' }

export_raster <- function(x, file, FUN = raster::writeRaster, data_source = flyio_get_datasource(),
                           bucket = flyio_get_bucket(data_source), ...){
  # checking if the file is valid
  assert_that(tools::file_ext(file) %in% c("tif", "hdf"), msg = "Please input a valid path")
  if(data_source == "local"){
    t = FUN(x, file, ...)
    return(invisible(t))
  }
  # a tempfile with the required extension
  temp <- tempfile(fileext = paste0(".",tools::file_ext(file)))
  on.exit(unlink(temp))
  # loading the file to the memory using user defined function
  file = gsub("\\/+","/",file)
  FUN(x, temp, ...)
  # downloading the file
  export_file(localfile = temp, bucketpath = file, data_source = data_source, bucket = bucket)
}

