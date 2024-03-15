# Interpolation Sea surface salinity

By Julien Laliberté et Steve Vissault

## Requirements

- Quarto (1.4), see https://quarto.org/docs/get-started/

## Build this document

### Using RStudio

1. Ensure that `/data/raster_salinity` exists and contains the `OC-SSS` outputs.
2. Open the file `rasters-SSS-explo.qmd` in RStudio
3. To compile, follow this step: https://quarto.org/docs/get-started/hello/rstudio.html#rendering

### Using the command line

1. Open a terminal
2. Run one of the following commandline

```bash
# Preview the document in browser 
quarto preview . 

# Build the HTML document
quarto render .

# Build the PDF document
quarto install tinytex 
quarto render rasters-SSS-explo.qmd --to pdf
```


