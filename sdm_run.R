#!/usr/bin/env Rscript

## sdm_run.R

# main program
# runs only when script is run by itself e.g from Rscript
# uses the 
if (sys.nframe() == 0){
  
  thisScript <- basename(sys.frame(1)$ofile)
  usage <- paste(thisScript,"<Genus_species> <radiuskm[default 1]> <number of runs[default 1>]")
  help <- "set OS env variables SDM_BASE_PATH to main folder with data and SDM_ENVS_PATH to sub folder where rasters are"               
  
  args = commandArgs(trailingOnly= FALSE)
  # test if there are enough arguments: if not, return an error
  if (length(args) < 3) {
    stop(usage, call.=FALSE)
  } else { 
    species  = args[1]
    radius   = args[2]
    run_number = args[3]
  }

  # TODO
  # optional arg 4 == base path
  if(length(args > 3)) {
    baseBath = sdmBasePath(args[4])
  } # else check for env variable here to make sure it 's set
  # optional arg 5 == env path
  if(length(args > 4)) {
    baseBath = sdmBasePath(args[4])
  } # else check for env variable here to make sure it 's set
  
  
  # read environmental rasters
  envs <- read_envs(radius, envsDir)
  # read occurrences 
  ## TODO 
  occs <- read_occs(species,occsDataFilePath(species))
  occs <- process_occs(occs, envs)
  
  # run model
  e.mx <- run_model(occs, envs, species, partitioning_alg = 'randomkfold')
  
  # save if a folder was provided
  if(! is.null(outputPath)) {
    save_model(e.mx, species, radiusKm, runNumber, outputPath )
  }
  test.e.mx <- run_species_radius(species=TEST_SPECIES, radiusKm = TEST_RADIUS, runNumber = 1, outputPath = NULL)
  

}