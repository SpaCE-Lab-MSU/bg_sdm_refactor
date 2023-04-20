#!/usr/bin/env Rscript

## sdm_run.R
# this does one run of a species, for a specific radius an d uses run number to name outputs

# requires the following to set in the environment
# you can set these in Linux using the 'export' command for each, 
# or for any platform create an .Renviron file in this directory. 
# see https://cran.r-project.org/web/packages/startup/vignettes/startup-intro.html

# SDM_BASE_PATH
# SDM_OCCS_PATH sub dir od base path
# SDM_ENVS_PATH= sub dir of base path
# sprintf patterns to name these files
# SDM_OCCS_PATH_TEMPLATE='occurrence_records/%s_thinned_full'
# SDM_OCCS_FILE_TEMPLATE='%s_thinned_wallace.csv'

source('sdm_model_eval.R')

# TODO convert these all to command line params
# main program
# runs only when script is run by itself e.g from Rscript
# uses the 
if (sys.nframe() == 0){
  usage <- "Rscript --vanilla sdm_run.R <Genus_species> <radiuskm[default 1]> output_path full path to output <optional number of runs[default 3]> )"
  help <- "set OS env variables SDM_BASE_PATH to main folder with data and SDM_ENVS_PATH to sub folder where rasters are"               
  
  args = commandArgs(trailingOnly= TRUE)
  
  print(args)
  
  # TODO use argparse for named arguments rather than positional
  # for more flex and to reduce errors
  
  # test if there are enough arguments: if not, return an error
  if (length(args) < 3) {
    stop(usage, call.=FALSE)
  } else { 
    species   <- args[1] # valid species of form Genus_species to match file names
    radiusKm  <- as.integer(args[2]) # integer matching envs dirs 
    outputPath<- args[3] # full path of where to save files
  }
  
  # send number of runs that were done and to be processed as optional 4 arg
  # default is 3
  numRuns <- 3
  if (length(args)== 4) 
    numRuns <- as.integer(args[4]) # integer

  # TODO validate all of these args.  for now just assume they are correct
  # TODO don't just rely on env variables for other paths/templates.  allow additional args
  mergedOutputs <- aggregateModelOutputs(outputPath,writeCSVs=TRUE)
  
  # the function below has the occurence data read built-in, based on standardized file naming and env variables. 
  # it may be better to re-factor the image processing functioning to accept occs as a parameter so you can 
  # test diffenet data types and methods
  listOfImageFiles <- imagePostProcessingAllRadii(outputPath, species, numRuns)
  
}
