paths <- list.files("/home/steve/Documents/DFO", pattern = "*.feather", recursive = TRUE, full.names = TRUE)

purrr::walk(paths, \(p){
    fs::file_move(p, file.path(".","data","Feather-v2", basename(p)))
})
