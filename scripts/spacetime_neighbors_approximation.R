#' Set Spatial Focal Window (Footprint)
#'
#' This function creates a matrix representing a spatial window or focal footprint 
#' to be used in spatial filtering or other neighborhood-based operations. The 
#' footprint defines the neighborhood around each cell, with an option to exclude 
#' the centroid.
#'
#' @param n_neighbors Integer. The number of neighboring cells in each direction 
#' from the focal point (i.e., the radius of the neighborhood). The total size 
#' of the focal window will be \code{(2 * n_neighbors + 1) x (2 * n_neighbors + 1)}. 
#' Default is 3.
#' @param exclude_centroid Logical. If \code{TRUE}, the central element of the 
#' focal window (representing the focal cell itself) will be set to 0, excluding 
#' it from calculations. If \code{FALSE}, the centroid will be included in the 
#' window. Default is \code{TRUE}.
#'
#' @return A matrix of size \code{(2 * n_neighbors + 1) x (2 * n_neighbors + 1)} 
#' representing the spatial footprint. The matrix consists of 1s, with the option 
#' to exclude the central (focal) element by setting it to 0.
#'
#' @examples
#' # Create a 3x3 focal window with the centroid excluded
#' set_space_focal(n_neighbors = 1, exclude_centroid = TRUE)
#'
#' # Create a 5x5 focal window, including the centroid
#' set_space_focal(n_neighbors = 2, exclude_centroid = FALSE)
#'
#' @export
set_space_focal <- function(n_neighbors = 3, exclude_centroid = TRUE){
    # Set space window aka focal footprint
    focalSpace <- matrix(rep(1, (n_neighbors * 2 + 1)), nrow = (n_neighbors * 2 + 1), ncol = (n_neighbors * 2 + 1))

    # Exclude centroid of the focal footprint
    if(exclude_centroid) focalSpace[round((n_neighbors * 2 + 1) / 2), round((n_neighbors * 2 + 1) / 2)] <- 0

    return(focalSpace)
}

#' Approximate variable by Spatio-Temporal Neighbors
#'
#' This function approximates spatio-temporal neighbors by selecting a subset of 
#' layers from a time series raster stack, applying a focal operation over a specified 
#' spatial window for each time step, and then aggregating the results over the 
#' specified time window.
#'
#' @param stack A \code{SpatRaster} object. The input raster stack with a time dimension.
#' @param target_time A \code{character} or \code{Date}. The target time around which 
#' to extract layers, specified as "YYYY-MM-DD". Default is "2015-04-04".
#' @param time_window A numeric vector of length 2. The time window (in days) around 
#' the \code{target_time} within which layers are selected. The first element defines 
#' the lower bound (e.g., \code{-1} means one day before), and the second element 
#' defines the upper bound (e.g., \code{1} means one day after). Default is \code{c(-1, 1)}.
#' @param space_focal A matrix. The spatial window (focal footprint) applied to each 
#' layer in the time window. By default, it uses \code{set_space_focal()} to create a 
#' spatial focal window.
#' @param fun A function. The aggregation function applied over the spatial and temporal 
#' dimensions. The default is \code{mean}.
#' @param verbose Logical. If \code{TRUE}, the function prints progress and messages. 
#' Default is \code{FALSE}.
#'
#' @return A \code{SpatRaster} object representing the aggregated result of applying the 
#' focal operation over the selected time window and averaging the results over both 
#' space and time.
#'
#' @examples
#' # Example usage with a SpatRaster stack
#' # Assuming 'stack' is a SpatRaster object with time metadata
#' approximate_st_neighbors(stack, target_time = "2015-04-04", time_window = c(-2, 2), 
#'                          space_focal = set_space_focal(2), fun = mean, verbose = TRUE)
#'
#' @seealso \code{\link[terra]{focal}}, \code{\link[terra]{time}}, \code{\link[terra]{app}}
#' 
#' @importFrom terra time nlyr subset rast app focal
#' @export
approximate_st_neighbors <- function(stack, target_time = "2015-04-04", time_window = c(-1, 1), space_focal = set_space_focal(), fun = mean, verbose = FALSE) {

    stopifnot(any(!is.na(terra::time(stack))))

    # Select layers in target time window
    selected_layers <- terra::subset(stack, 
        terra::time(stack) >= (as.Date(target_time) + time_window[1]) & 
        terra::time(stack) <= (as.Date(target_time) + time_window[2])
    )
    
    # Declare empty list to store timestep 
    res <- list()

    # Loop over time
    for(t in 1:terra::nlyr(selected_layers)){
        res[[t]] <- terra::focal(selected_layers[[t]], w = space_focal, fun = fun, na.rm = TRUE)
    }

    # Average on spacetime
    aggregated_layer <- terra::rast(res) |> terra::app(fun = fun, na.rm = TRUE)

    return(aggregated_layer)
}

# This function perform the neighbors approximation along the raster stack for each timestamp
apply_st_neighbors_on_stack <- function(stack, timestamps, target_folder, n_cores, n_neighbors, temp_window, agg_fun){

    outputs_folder <- file.path(target_folder, glue::glue("TB_{n_neighbors}pixels_{temp_window}days"))
    dir.create(outputs_folder)

    # Declare plan
    future::plan(future::multicore, workers = n_cores)

    furrr::future_walk(timestamps, \(t){
        rs <- approximate_st_neighbors(stack, target_time = t, time_window = c(-temp_window, temp_window), space_focal = set_space_focal(n_neighbors), fun = agg_fun, verbose = TRUE)
        terra::writeRaster(rs, filename = file.path(outputs_folder, glue::glue("TB_{t}.tif")), overwrite = TRUE)
    }, .progress = TRUE)

    ### Close cluster
    future::plan("sequential") 
}


