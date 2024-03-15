# Sea surface salinity interpolation 

By Julien Laliberté et Steve Vissault

## HTML Pages

- [Explore the sea surface salinity products derivated from Spectral remote-sensing reflectance ](https://steveviss.github.io/seaSurfaceSalinity-DFO/1-SSS-explo/)

## Development

### Requirements

Quarto (v1.4), see https://quarto.org/docs/get-started/

### Build this document

#### Using RStudio

1. Ensure that `/data/raster_salinity` exists and contains the `OC-SSS` outputs.
2. Open the file `*.qmd` in RStudio
3. To compile, follow this step: https://quarto.org/docs/get-started/hello/rstudio.html#rendering

#### Using the command line

1. Open a terminal
2. Run one of the following command line

```bash
# Preview the document in browser 
quarto preview . 

# Build the HTML document
quarto render 1-SSS-explo

# Build the PDF document
quarto install tinytex 
quarto render 1-SSS-explo --to pdf
```


