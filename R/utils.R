#' Function argument names
#' @noRd
function_args <- function(f, include_dots = FALSE){
  if(include_dots){
    return(names(formals(f)))
  }
  setdiff(names(formals(f)),"...")
}

#' check package installed
#' @noRd
#' @importFrom purrr walk
check_packages_installed <- function(x, stop_if_not = TRUE){
  if(is.null(x)){
    return()
  }
  stopifnot(is.character(x))

  check_one <- function(y){
    its_here <- TRUE
    if (!requireNamespace(y, quietly = TRUE)) {
      nope <- sprintf("%s needed for this function to work. Please install it including dependencies",
                      y,y)
      if(stop_if_not) stop(nope, call. = FALSE) else message(nope)
      if(!stop_if_not) its_here <- FALSE
    }
    return(its_here)
  }

  walk(x, check_one)
}


#' assign new value if not null and check passes
#' @noRd
assign_new <- function(new, old, check_f = is.function){
  if(!is.null(new)){
    assert_that(check_f(new))
    return(new)
  }
  old
}
