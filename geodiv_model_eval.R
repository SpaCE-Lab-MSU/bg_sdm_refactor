###### sdm_enviro_div.R
# calculating geodiversity on concentric radii for sdm

#Project: Using geodiversity to improve SDMs for data poor species

#Description: This code calculates geodiversity metrics. It calculates SD of CHELSA biodiversity variables at multiple radii (3, 9, 15, 21, 27, 33 km). It calculcates the SD of elevation over the same radii.

# Authors: Beth E. Gerstner, Pat Bills
# versions
# 3/21/22: original script https://github.com/bgerstner90/geodiv/blob/master/chapter_1/rcode/test_model_evaluation.R
# 1/21/19: nearly complete WIP.  adapted to use correct data folder, but wallace can't read occs

## uses the following environment variables - set these in your .Renviron file
# SDM_BASE_PATH path to where the data lives, with subfolders for species occs and rasters
# alternatively if SDM_BASE_PATH is not set, HPCC_BASE_PATH will be used
# SDM_ENVS_PATH sub path inside SDM_BASE_PATH where the env rasters are


# ensure libs are available 
require(terra)
require(ENMeval) 
require(wallace)
require(rJava)
require(dismo)

options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx8192m"))


TEST_SPECIES="Alouatta_palliata"
TEST_RADIUS=1

# get or set the global configuration for the base path so you don't have to send it to functions everytime
# side effect: sets env variable if a parameter is sent
sdmBasePath <- function(base_path = NULL){
    # 1. use argument if it's present, set os env
    if( ! (is.null(base_path) || base_path == "") ) {
        # trick to get this set in the OS env so we can use it as a 'global' var
        # update the global OS environment for the value sent to the function
        do.call(Sys.setenv, as.list(setNames(base_path, "BASE_PATH")))

        return(base_path )
    } else {
        # 2. no var sent, so read environment
        base_path <- Sys.getenv('SDM_BASE_PATH')
    }

    # 3 if this base path is not set, check if we are on the HPCC
    # this allows you to have a single .Renviron with a 'local' var and an HPCC path
    if(base_path == "") {
        if(Sys.getenv("HPCC_CLUSTER_FLAVOR") != "") {
            base_path = Sys.getenv('HPCC_BASE_PATH')
        } else {
            # if parameter null, no environment variable set, use current dir
            base_path = "."
        }

        # again, set this in the env as global variable since it's not set
        do.call(Sys.setenv, as.list(setNames(base_path, "BASE_PATH")))
    }
    return(base_path)
}


#' standardized way to construct path to data given radius
#' this will ALWAYS be <base_path>/SDM_ENVS_PATH/<radius>x>
#' 
envsDataPath <- function(radius = 1, suffix = "x", envsDir = NULL, basePath = sdmBasePath()){
  # current location 1/23 is  base path + /environmental_variables/33x/<tiffs>
  if(is.null(envsDir)) {
    # if no param sent, use value set in .Renviron or in OS environment
    envsDir = Sys.getenv('SDM_ENVS_PATH')
  } 
  
  
  dp <- file.path(basePath, envsDir, paste0(sprintf("%d", radius), suffix))
  return(dp)
}
  

#' read in ennvironment rasters for a given radius
#' envsDir path to rasters, or NULL if want to use standard path
#' to construct data path different from standard, 
#'  use envsDir =  envsDataPath(radius, suffix, envsDir, bathPath)

read_envs <- function(radius, envsDir = NULL){
    
    envsDir = envsDataPath(radius, envsDir = envsDir)
    
  
    if(!file.exists(envsDir)){
      warning(paste("path to envs not found, returning null:", envsDir))
      return(NULL)
    }
  
    
    # NOTE for reference, the current list is c('srtm_crop.tif', 'bio6_1981.2010_V.2.1.tif', 'bio5_1981.2010_V.2.1.tif', 'bio14_1981.2010_V.2.1.tif', 'bio13_1981.2010_V.2.1.tif',"cloud_crop.tif")
    # but here we get the list of file nanmes by reading the names from given folder, which makes it more flexible
    patternTifFile = ".+\\.tif[f]?"  # regular expression matches *.tif and *.tiff
    # get list of all the tiffs in the folder
    envs_raster_names <-  list.files(envsDir, patternTifFile )
    
    # make sure there are files there
    if(length(envs_raster_names) == 0){
      warning(paste("no tif files found in", envsDir, "returning NULL"))
      return(NULL)
    }

    envs <- wallace::envs_userEnvs(
        rasPath = file.path(envsDir, envs_raster_names),
        rasName = envs_raster_names,
        doBrick = FALSE)
    
    return(envs)
}


occsDataPath <- function(species, occsPathTemplate = NULL, basePath = sdmBasePath() ) {
  
  # current location of data (1/23) is 
  # basePath + occurrence_records/Alouatta_palliata_thinned_full
  # basePath + occs dir + species dir
  
  if( is.null(occsPathTemplate)) {
    occsPathTemplate = Sys.getenv('SDM_OCCS_PATH_TEMPLATE')
  }
  
  if(stringr::str_detect(occsPathTemplate,'%')) {
    tryCatch(
      {occsFullPath<- file.path(basePath,sprintf(occsPathTemplate,species ))
      },
      error = function(e) {
        warning("invalid template param in occsPathTemplate , see docs for sprintf")
        return(NULL)
      }
      
    )
  } else {
    occsFullPath<- file.path(sdmBasePath,occsPathTemplate)
  }
  
  if(file.exists(occsFullPath)) {
    return(occsFullPath)
  } else { 
    warning(paste("occurence data folder not found, returning NULL ",occsFullPath))
    return(NULL)            
  }
  
  
  
}


#' construct file name for occurrences file given template 
#' 
#' wallace needs both the full path and the file name to open 
occsDataFilename<-function(species,occsFileNameTemplate  = NULL){
  
  if(is.null(occsFileNameTemplate )) 
  {  occsFileNameTemplate  = Sys.getenv('SDM_OCCS_FILE_TEMPLATE')}
  
  if(stringr::str_detect(occsFileNameTemplate,'%')) {
    occsFilePath <- sprintf(occsFileNameTemplate, species)
  } else {
    # not an sprintf() template so ... ?   just return the path assuming it's the full. path to the file 
    occsFilePath <- occsFileNameTemplate
  }
  
  return(occsFilePath )
  
}

read_occs <-function(species, occsPathTemplate=NULL, occsFileNameTemplate=NULL, basePath = NULL){
  #questionL for txt name why use the file name (a..p..thined ) vs just the species per Wallace documentation https://rdrr.io/cran/wallace/man/occs_userOccs.html
  #occs_path <- "/Volumes/BETH'S DRIV/zarnetske_lab/candidate_species_2022/thinned_data/Alouatta_palliata_thinned_full"
  #occs_path <- file.path(occs_path, "Alouatta_palliata_thinned_thin1.csv")
  
  # TODO - leave this to the other functions? 
  if(is.null(basePath)) { basePath = sdmBasePath() }
  
  # https://rdrr.io/cran/wallace/man/occs_userOccs.html
  userOccs_sp <- wallace::occs_userOccs(
    txtPath = file.path(occsDataPath(species, occsPathTemplate, basePath = basePath),occsDataFilename(species,occsFileNameTemplate)),
    txtName = occsDataFilename(species,occsFileNameTemplate),
    txtSep = ",",
    txtDec = ".")
  
  return(userOccs_sp[[species]]$cleaned)
}


#' read in pre-queries (and pre-thinned) occurrence records
process_occs <- function(occs, envs) {

    occs_xy <- occs[c('longitude', 'latitude')]
    occs_vals <- as.data.frame(raster::extract(envs, occs_xy, cellnumbers = TRUE))
    # remove occurrence records with NA environmental values
    occs_2<- occs[!(rowSums(is.na(occs_vals)) >= 1), ]
    # also remove variable value rows with NA environmental values
    occs_vals_2 <- na.omit(occs_vals)
    # add columns for env variable values for each occurrence record
    occs <- cbind(occs_2, occs_vals_2)

    return(occs)

}

#' remove points outside of species sampling polygon
#' sometimes for some data points are mislabeled, this removes them
#' for current project data is good, so this function is not used. 
filter_occs <-function(occs,areaPoly,polyID){
    #Remove occurrences outside of user drawn polygon
    occs_or_null <- wallace::poccs_selectOccs(
        occs = occs,
        polySelXY = areaPoly,
        polySelID = polyID
    )

    #NOTE if there are no values to remove, poccs_selectOccs() returns NULL!!!
    if(is.null(occs_or_null)){
        return(occs)
    } else {
        return(occs_or_null)
    }

}

#' background sampling calculations
#' Sampling of 10000 background points and corresponding environmental data using a “point buffers” method with a 1 degree buffer.
#'
#' value: list with several data outputs bgExt, bgMask, bgSample, bgEnvsVals)
#'
bg_sampling <- function(occs, envs, species){

    # Generate background extent
    bgExt <- wallace::penvs_bgExtent(
        occs = occs,
        bgSel = "point buffers",
        bgBuf = 1)
    # Mask environmental data to provided extent
    bgMask <- wallace::penvs_bgMask(
        occs = occs,
        envs = envs,
        bgExt = bgExt)
    # Sample background points from the provided area
    bgSample <- wallace::penvs_bgSample(
        occs = occs,
        bgMask =  bgMask,
        bgPtsNum = 10000)


    # Extract values of environmental layers for each background point
    bgEnvsVals <- as.data.frame(raster::extract(bgMask,  bgSample))

    # Add extracted values to background points table
    bgEnvsVals <- cbind(scientific_name = paste0("bg_", species), bgSample,
                        occID = NA, year = NA, institution_code = NA, country = NA,
                        state_province = NA, locality = NA, elevation = NA,
                        record_type = NA, bgEnvsVals)

    bgDataList <- list("bgExt" = bgExt,
                    "bgMask" = bgMask,
                    "bgSample" = bgSample,
                    "bgEnvsVals" = bgEnvsVals)

    return(bgDataList)
}

#' gather params, create bg sample and create ENM Evaluation
run_model <- function(occs, envs, species,nCores=NULL){

   # save number of occurrences for setting params
   n_occs <- nrow(occs)
  
   # previously, feature classes based on n occurrence records 
   # LQH >= 15; LQ between 10 -14; L < 10
   ## feature class as string of letters
   #featureClass <- "L"
   #if(n_occs > 10 ){ featureClass <- paste0(featureClass, "Q") }
   #if(n_occs >=15 ){ featureClass <- paste0(featureClass, "H") }
  

   # Now just using static feature class for all data, but saving the code above  
   # in case we change our minds again

   featureClass <- "LQ"

   # 
   # Conditional settings for cross validation
   # Jackknife for <= 25
   # Random K-fold > 25
  
  
    partitioning_cutoff <- 25 
  
    if (n_occs <= partitioning_cutoff) {  
        partitioning_alg <- 'jackknife'   } 
    else {                  
        partitioning_alg <- 'randomkfold' }
  

    bgData <- bg_sampling(occs, envs, species)
    #generate full prediction extent for input into 'envs'
    envs_cropped <- raster::crop(envs, bgData$bgExt)
    #subset occs_ap to longitude and latitude
    occs_ll <- occs[,c("longitude","latitude")]

    ##RUN 1
    #Need to use Maxent.jar because of the ability to see perm importance
    #will have to store maxent jar file on HPC? Maxent uses this file to run.

    print(paste("running ENMevaluate n=", n_occs, "feature class", featureClass, " partitions", partitioning_alg))
    
    # if(is.null(nCores) || nCores == "" || is.na(nCores)){
    e.mx <- ENMeval::ENMevaluate(occs = occs_ll, envs = envs_cropped, bg = bgData$bgSample,
                                   algorithm = 'maxent.jar', partitions = partitioning_alg,
                                   tune.args = list(fc = featureClass, rm = 1),
                                   numCores = nCores)      
    # } else {
    #    e.mx <- ENMeval::ENMevaluate(occs = occs_ll, envs = envs_cropped, bg = bgData$bgSample,
    #                       algorithm = 'maxent.jar', partitions = partitioning_alg,
    #                       tune.args = list(fc = featureClass, rm = 1))
    # }
    return(e.mx)
}


#' write components of ENMevaluation to disk
#' e.mx output from ENMevaluate
#' species Genus_species used for file naming
#' radiusKm integer used for file naming
#' runNumber used for file naming
#' outputPath full or relative path to cwd (not to base path)
save_model <- function(e.mx, species, radiusKm, runNumber, outputPath){

    print(paste("saving model output to ", outputPath))

    if(! file.exists(outputPath)){ dir.create(outputPath, recursive=TRUE) }
  
    e.mx.results <- e.mx@results
    # "a_palliata_ENMeval_1x_results.1.run1.csv"
    results.Filename = paste0(species, "_ENMeval_1x_results.",radiusKm,"_run",runNumber,".csv")
    write.csv(e.mx.results, file=file.path(outputPath, results.Filename))

    # minimize AICc
    # evaluated the AICc within 2 delta units
    minAIC <- e.mx.results[which(e.mx.results$delta.AICc <= 2),] #Make sure the column is delta.AICc
    minAIC.Filename <- paste0(species, "_min_AIC_em.x.", radiusKm, "_run",runNumber,".csv")
    # NOTE this file name is changed from original model_evaluation script to accommodate radius and run number
    write.csv(minAIC,file=file.path(outputPath, minAIC.Filename))


    #Generate table of performance stats
    e.mx.stats <- e.mx.results[c("auc.train","cbi.train")]
    stats.Filename <- paste0(species, "_stats_e.mx.",radiusKm, "_run", runNumber,".csv")
    # "a_palliata_stats_e.mx.1_run1.csv"
    write.csv(e.mx.stats, file.path(outputPath, stats.Filename))


    # TODO : FIX 
    
    # previous code didn't work because there is not a list item with this name
    # e.mx.var.imp <-e.mx@variable.importance$fc.LQHP_rm.1 --> #"a_palliata_permutation_imp_e.mx.1.run1.csv"
    # variable importance table, names are fc.Q_rm.1, fc.H_rm.1, etc.  there is no fc.LQHP_rm.1
    # loop through the fc names and save each as a CSV
    for(fcName in names(e.mx@variable.importance)) {
      varimp.Filename <- paste0(species, "_imp_e.mx_", fcName, "_",radiusKm, "_run", runNumber,".csv")  
      write.csv(e.mx@variable.importance[[fcName]], file = file.path(outputPath, varimp.Filename))
    }
    

    

    #write prediction to file
    # filename="e.mx.1.pred.run1.tif"
  
    # loop through the fc names of the layers and save each as a raster
    for(layerName in names(e.mx@predictions)) {
      prediction.Filename = paste0(species, "_pred_",layerName, "_", radiusKm, "_run", runNumber,".csv")  
      writeRaster(e.mx@predictions[[layerName]], filename=file.path(outputPath, prediction.Filename), format="GTiff", overwrite=T)
    }  
    
  
    
}

# sdm_read_and_run <- function(species, areaPoly, radiusKm = 1, runNumber = 1, envsDir = NULL,outputPath = NULL){
#   message(paste("running model for ", species, "radius=", radiusKm, " run number=", runNumber ))
#   
#   # read environmental rasters
#   envs <- read_envs(radius = radiusKm, envsDir = envsDir)
# 
# 
#   # read and process occurrences
#   occs <- read_occs(species)
#   occs <- process_occs(occs, envs)
#     
#   # run model
#   e.mx <- run_model(occs, envs, species, partitioning_alg = 'randomkfold')
#   
#   # save if a folder was provided
#   if(! is.null(outputPath)) {
#     save_model(e.mx, species, radiusKm, runNumber, outputPath )
#   }
#   
#   # return the model for the next step if any
#   return(e.mx)
# 
# }

sdm_read_and_run <- function(species, radiusKm = 1, runNumber = 1, basePath = NULL, envsDir = NULL, occsPathTemplate = NULL, occsFileNameTemplate = NULL, outputPath = NULL){
  message(paste("running model for ", species, "radius=", radiusKm, " run number=", runNumber ))
  
  basePath = sdmBasePath(basePath)
  # read environmental rasters
  envs <- read_envs(radius = radiusKm, envsDir = envsDir)
  
  # read and process occurrences
  occs <- read_occs(species, 
                       occsPathTemplate, 
                       occsFileNameTemplate,
                       basePath)
  occs <- process_occs(occs, envs)
  
  # run model
  e.mx <- run_model(occs, envs, species)
  
  # save if a folder was provided
  if(! is.null(outputPath)) {
    save_model(e.mx, species, radiusKm, runNumber, outputPath )
  }
  
  # return the model for the next step if any
  return(e.mx)
  
}
