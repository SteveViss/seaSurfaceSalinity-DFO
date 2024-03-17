# Sea surface salinity interpolation 

By Julien Laliberté et Steve Vissault

[Access the main documentation](https://steveviss.github.io/seaSurfaceSalinity-DFO/)

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
