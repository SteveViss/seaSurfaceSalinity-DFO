#' Predict for Target Date
#'
#' The `predict_for_target_date` function generates predictions for a specified target date using a pre-trained Random Forest (RF) model.
#' It loads the necessary predictors from Feather files, computes sinusoidal features for the date, and integrates neighborhood data 
#' from raster files to perform the prediction.
#'
#' @param target_date Date. The target date for which predictions need to be generated. The function is currently set to use the fixed date 
#'   `2022-08-01` for this implementation.
#' @param rf_model randomForest. A pre-trained Random Forest model object used to generate predictions.
#' @param TB_approx_neighbors_dir character. The directory path where approximate neighbor raster files for the "TB" variable are located. 
#'   The default value is `"data/raster/TB_approx_neighbors"`.
#' @param feather_dir character. The directory where Feather files containing the predictors are stored. The default value is `"data/Feather"`.
#'
#' @return A data.frame containing the predictions made by the Random Forest model for the specified target date.
#'
#' @details This function follows a multi-step process:
#'   1. Loads predictor data from Feather files based on the target date.
#'   2. Adds sinusoidal date features to represent temporal patterns.
#'   3. Extracts neighborhood data from raster files for the "TB" variable.
#'   4. Uses the pre-trained Random Forest model to generate predictions.
#'
#' @examples
#' # Example usage:
#' target_date <- as.Date("2022-08-01")
#' rf_model <- readRDS(file.path("data", "randomForest", "50bins_5samples", "vars_importance.rds"))$OCTB$permutation 
#' predictions <- predict_for_target_date(target_date, rf_model)

predict_for_target_date <- function(
        target_date, 
        rf_model, 
        TB_approx_neighbors_dir = file.path("data", "raster", "TB_approx_neighbors"), 
        feather_dir = file.path("data", "Feather")
    ) {

    # Ensure that target_date is of Date type
    target_date <- as.Date(target_date)

    # Feather files
    files <- list.files(feather_dir, pattern = "*.feather", full.names = TRUE)
    files <- data.frame(
        path = files,
        timestamp = as.Date(stringr::str_extract(files, "[0-9]{4}-[0-9]{2}-[0-9]{2}"))
    )

    # Read the feather file corresponding to the target_date
    predictors <- feather::read_feather(files[which(files$timestamp == target_date), "path"])
    
    # Load tref from TDIML
    tref <- system.file(
        "extdata",
        "tref.rds",
        package = "TDIML"
    ) |> readRDS()

    # Add sinusoidal predictors based on date
    sins <- predictors$date |>
        as.POSIXct() |>
        TDIML::atime(tref)
    
    predictors <- predictors |>
        dplyr::mutate(
            year = lubridate::year(date),
            solSin = sins[, 1L],
            equiSin = sins[, 2L]
        ) |>
        dplyr::select(-is_origin, -IS) |>
        dplyr::filter(!is.na(TB))
    
    # Approximate neigbors
    approx_rasters_path <- list.files(
        TB_approx_neighbors_dir,
        pattern = glue::glue("TB_{target_date}.tif$"),
        full.names = TRUE,
        recursive = TRUE
    )
    
    # Add TB neigbors predictors
    rasters_names <- stringr::str_replace(
        dirname(approx_rasters_path),
        paste0(TB_approx_neighbors_dir, "/"), ""
    )

    approx_rasters <- terra::rast(approx_rasters_path) |> setNames(rasters_names)
    predictors <- cbind(predictors, terra::extract(approx_rasters, predictors[c("lon", "lat")]))
    
    # Make sure all predictors of the model are presents
    stopifnot(all(rf_model$forest$independent.variable.names %in% names(predictors)))
    
    # Perform the prediction
    pred <- predict(rf_model, predictors)$predictions

    return(data.frame(predictors, pred_OC = pred))
}
