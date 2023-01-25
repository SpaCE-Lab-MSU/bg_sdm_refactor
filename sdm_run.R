#!/usr/bin/env Rscript

## sdm_run.R
# this does one run of a species, for a specific radius an d uses run number to name outputs

# requires the following to bet set in the environment

# SDM_BASE_PATH
# SDM_OCCS_PATH sub dir od base path
# SDM_ENVS_PATH= sub dir of base path
# sprintf patterns to name these files
# SDM_OCCS_PATH_TEMPLATE='occurrence_records/%s_thinned_full'
# SDM_OCCS_FILE_TEMPLATE='%s_thinned_wallace.csv'

# TODO convert these all to command line params
# main program
# runs only when script is run by itself e.g from Rscript
# uses the 
if (sys.nframe() == 0){
  source('geodiv_model_eval.R')
  usage <- "Rscript --vanilla sdm_run.R <Genus_species> <radiuskm[default 1]> <number of runs[default 1]> output_path full path to output)"
  help <- "set OS env variables SDM_BASE_PATH to main folder with data and SDM_ENVS_PATH to sub folder where rasters are"               
  
  args = commandArgs(trailingOnly= TRUE)
  
  print(args)
  
  # test if there are enough arguments: if not, return an error
  if (length(args) < 4) {
    stop(usage, call.=FALSE)
  } else { 
    species  = args[1] # valid species of form Genus_species to match file names
    radiusKm   = as.integer(args[2]) # integer matching envs dirs 
    runNumber = args[3] # integer
    outputPath = args[4] # full path of where to save files
  }

  
  # TODO validate all of these args.  for now just assume they are correct
  
  
  # TODO don't just rely on env variables for other paths/templates.  allow additional args
  # for example
  # if(length(args > 5)) {
  #   baseBath = sdmBasePath(args[5])
  # } # else check for env variable here to make sure it 's set
  # 
  
  
  # don't save just yet
  e.mx <- sdm_read_and_run(species=species, radiusKm = radiusKm, runNumber = runNumber, outputPath = NULL)
  
  # TODO check for validity in e.mx
  
  # save to the outputPath, which also creates the folder if necessary
  if(! is.null(outputPath)) {
    save_model(e.mx, species, radiusKm, runNumber, outputPath )
  }


}