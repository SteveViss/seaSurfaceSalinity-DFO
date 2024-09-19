# Sea surface salinity interpolation 

By Julien Laliberté et Steve Vissault

## Content

- `interpolation/0-neighbors-approximation.qmd`: Neighbor-based method to fill missing values (NAs) in salinity data by applying spatial and temporal windows. Loads rasters and applies the approximation function defined in an external script (`scripts/spacetime_neighbors_approximation.R`).
  
- `interpolation/1-training-set.qmd`: Details the creation of a training set for Random Forest interpolation by sampling salinity data into bins (50 intervals, 5 samples per bin). 

- `interpolation/2-random-forest.qmd`: Covers Random Forest model training with hyperparameter tuning using the ranger package.

- `interpolation/3-validation.qmd`: Focuses on validating the model by computing RMSE using in situ data.

- `interpolation/4-figures.qmd`: Generates figures for model results, setting parameters and directories for saving outputs.
Loads reference data and prepares the visualization.

## Development

### Build the documentation

#### Using RStudio

1. Ensure that `/data/raster_salinity` and `/data/raster_salinity_mask` exist and contains the `OC-SSS` outputs.
2. Open the file `*.qmd` in RStudio
3. To compile, follow this step: https://quarto.org/docs/get-started/hello/rstudio.html#rendering

#### Using the command line

**Requirements:** Quarto (v1.4), see https://quarto.org/docs/get-started/

1. Open a terminal
2. Run one of the following command line

```bash
# Preview the document in browser 
quarto preview 

# Build the HTML document
quarto render 
```

### Publish on Github pages

```bash
quarto publish gh-pages --no-browser
```
