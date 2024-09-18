#' Set focal matrix
#'
#' This function helps to declare a focal, matrix filled with 0 and 1: 0 meaning the neighbors cell is not include within the focal and 1 the opposite
#' The matrix could also be filled with float values representative of the weight of cell.  
#'
#' @param pixels Integer corresponding of the nrow and ncol of the focal matrix.
#' @param exclude_centroid Boolean, does the centroid should be excluded from the focal?
#' @returns A matrix representative of the neighbors cells included in the focal
#'
set_space_focal <- function(n_neighbors = 3, exclude_centroid = TRUE){
    # Set space window aka focal footprint
    focalSpace <- matrix(rep(1, (n_neighbors * 2 + 1)), nrow = (n_neighbors * 2 + 1), ncol = (n_neighbors * 2 + 1))

    # Exclude centroid of the focal footprint
    if(exclude_centroid) focalSpace[round((n_neighbors * 2 + 1) / 2), round((n_neighbors * 2 + 1) / 2)] <- 0

    return(focalSpace)
}

#' For NA pixels, set values based on neigbors in space and time
#'
#' This function average in space and time
#'
#' @param pixels Integer corresponding of the nrow and ncol of the focal matrix.
#' @param exclude_centroid Boolean, does the centroid should be excluded from the focal?
#' @returns 
#' 
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

# Apply approximation by neighbors
# Wrapper function
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

OC_rs_path <- list.files("data/raster/OC", pattern = "*.tif", full.names = TRUE) 
TB_rs_path <- list.files("data/raster/TB", pattern = "*.tif", full.names = TRUE)

OC_files <- data.frame(
    OC_path = OC_rs_path,
    timestamp = as.Date(stringr::str_extract(OC_rs_path, "[0-9]{4}-[0-9]{2}-[0-9]{2}"))
)

TB_files <- data.frame(
    TB_path = TB_rs_path,
    timestamp = as.Date(stringr::str_extract(TB_rs_path, "[0-9]{4}-[0-9]{2}-[0-9]{2}"))
)

# Apply the approximation function on TB stack
TB_rasters <- terra::rast(TB_files$TB_path)
terra::time(TB_rasters) <- TB_files$timestamp

# Run for 5 pixels in space and 5 days in time
apply_st_neighbors_on_stack(
    stack = TB_rasters,
    timestamps = TB_files$timestamp, 
    target_folder = "/home/steve/Documents/outputs_DFO", 
    n_cores = 8, 
    n_neighbors = 5, 
    temp_window = 5, 
    agg_fun = mean
)

# Run for 3 pixels in space and 3 days in time
apply_st_neighbors_on_stack(
    stack = TB_rasters,
    timestamps = TB_files$timestamp, 
    target_folder = "/home/steve/Documents/outputs_DFO", 
    n_cores = 8, 
    n_neighbors = 3, 
    temp_window = 3, 
    agg_fun = mean
)

# Run for 1 pixels in space and 1 days in time
apply_st_neighbors_on_stack(
    stack = TB_rasters,
    timestamps = TB_files$timestamp, 
    target_folder = "/home/steve/Documents/outputs_DFO", 
    n_cores = 8, 
    n_neighbors = 1, 
    temp_window = 1, 
    agg_fun = mean
)

