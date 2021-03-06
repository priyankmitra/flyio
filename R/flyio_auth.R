#' Authenticate flyio
#' @description Authenticate any of the cloud storage platforms to perform any I/O
#' @param auth_list path to the json file or the system environment name in case of gcs. For s3 a vector for access_key, secret_access_key, region (optional; default us-east-1) and session_id (optional); this could also be a single comma-separated string.
#' @param data_source default to local. Possible options : gcs, s3, local. Case insensitive
#' @param scope the scope of the auth if gcs. Default: https://www.googleapis.com/auth/devstorage.full_control
#' @export "flyio_auth"
#' @import "googleCloudStorageR" "stringr" "aws.s3" "assertthat" "utils" "tools"
#' @examples
#' flyio_set_datasource("local")
#' flyio_auth()
#'


flyio_auth <- function(auth_list = "", data_source = flyio_get_datasource(),
                   scope = "https://www.googleapis.com/auth/devstorage.full_control"){

  # checking if data_source input is valid
  invisible(assertthat::assert_that(stringr::str_to_lower(data_source) %in% c("local", "gcs", "s3"),
                                    msg = "data_source should be either local, gcs or s3"))

  # if data source is local return
  if(str_to_lower(data_source) == "local"){
    cat("data_source is set to Local. No authetication required.\n")
    return(invisible(TRUE))
  }

  # check the input for auth_list - split if comma present.
  if(length(auth_list) == 1){
    auth_list = stringr::str_trim(unlist(strsplit(auth_list, ",")))
  } else{
    invisible(assertthat::assert_that(!is.list(auth_list), msg = "Please input a vector in auth_list"))
  }

  # check if the inputs are system environments
  if(sum(auth_list %in% names(Sys.getenv())) == length(auth_list)){
    auth_list = Sys.getenv(auth_list)
  }

  # running authentication for set data source
  if(str_to_lower(data_source) == "gcs"){
    auth_response = .gcsAuth(auth_list[1], scope)
  } else if(str_to_lower(data_source) == "s3"){
    auth_response = .s3Auth(auth_list)
  }
  auth_response = assertthat::assert_that(isTRUE(auth_response), msg = "Authentication Failed!")
}

# helper functions to authentical a cloud storage source
.gcsAuth <- function(auth_list, scope){
  tryCatch({
    tryCatch({
      googleCloudStorageR::gcs_auth(auth_list)
      cat("GCS Authenticated!\n")
      return(TRUE)
    }, error = function(err){
      options(googleAuthR.scopes.selected = scope)
      Sys.setenv("GCS_AUTH_FILE" =auth_list)
      googleCloudStorageR::gcs_auth()
      cat("GCS Authenticated!\n")
      return(TRUE)
    })}, error = function(err){
      return(FALSE)
    })

}
.s3Auth <- function(auth_list){
  invisible(assertthat::assert_that(length(auth_list)>=2, msg = "Input access key and secret key for S3"))
  auth_list <- switch (as.character(length(auth_list)),
                       "2" = c(auth_list, "us-east-1", ""),
                       "3" = c(auth_list, "")
  )
  Sys.setenv("AWS_ACCESS_KEY_ID" = auth_list[1],
             "AWS_SECRET_ACCESS_KEY" = auth_list[2],
             "AWS_DEFAULT_REGION" = auth_list[3],
             "AWS_SESSION_TOKEN" = auth_list[4])
  tryCatch({invisible(capture.output(t1 <- bucketlist()))
    cat("AWS S3 Authenticated!\n"); return(TRUE)}, error = function(err){})

}
