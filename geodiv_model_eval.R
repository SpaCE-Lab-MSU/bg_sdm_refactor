###### sdm_enviro_div.R
# calculating geodiversity on concentric radii for sdm

#Project: Using geodiversity to improve SDMs for data poor species

#Description: This code calculates geodiversity metrics. It calculates SD of CHELSA biodiversity variables at multiple radii (3, 9, 15, 21, 27, 33 km). It calculcates the SD of elevation over the same radii.

# Authors: Beth E. Gerstner, Pat Bills
# versions
# 3/21/22: original script https://github.com/bgerstner90/geodiv/blob/master/chapter_1/rcode/test_model_evaluation.R
# 1/21/23

#Load in libraries - TODO change these to 'require()'
library(spocc) # https://github.com/ropensci/spocc
library(spThin) # https://cran.r-project.org/web/packages/spThin/index.html
# library(dismo)
# library(rgeos)
library(ENMeval)
library(wallace)

# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx8192m"))
# library(xlsx)
# versions

# global default configuration.  Override these if you don't want to set vars when you run the program
# move these to Renviron
HPCC_BASE_PATH="/mnt/research/plz-lab/DATA/bg_geodiversity"
DATA_BASE_PATH="/Volumes/plz-lab/DATA/bg_geodiversity"
# candidate_species_2022/thinned_data  CHELSA_4_only
EXAMPLE_SPECIES="Alouatta_palliata"
RADII = c(1,3,9,15,21,27,33)


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
        base_path <- Sys.getenv('BASE_PATH')
    }

    # 3
    if(base_path == "") {
        if(Sys.getenv("HPCC_CLUSTER_FLAVOR") != "") {
            base_path = HPCC_BASE_PATH
        } else {
            base_path = "."
        }

        # again, set this in the env as global variable since it's not set
        do.call(Sys.setenv, as.list(setNames(base_path, "BASE_PATH")))
    }
    return(base_path)
}


# thinned data example

# /Volumes/plz-lab/DATA/bg_geodiversity/candidate_species_2022/thinned_data/Alouatta_palliata_thinned_full
# Alouatta_palliata_thinned_thin1.csv
# Alouatta_palliata_thinned_thin2.csv
# Alouatta_palliata_thinned_thin3.csv
# Alouatta_palliata_thinned_thin4.csv
# Alouatta_palliata_thinned_thin5.csv

# Point Values run (CHELSA + remote sensing)
occsDataPath <- function(species,base_path = sdmBasePath() ) {
    full_data_path = paste0(species,"_thinned_full")
    return(file.path(base_path, "candidate_species_2022","thinned_data", full_data_path))
}

# standardized data file naming - simply prepend species name to filename
occsDataFilename <- function(species, suffix = "_thinned_thin1.csv"){
    return(paste0(species, suffix))
}

#' create polygon for the region used by this study, named for the id
#'
#' rather than store the ID of the polygon in a different data structure, set the R 'name'
#' value: 2 X n matrix representing pairs of decimal coordinates  (lat, long),
#' named for the ID of the poly
region_polygon <- function(){
     p<- matrix(c(-86.444047, -80.905157, -73.915607, -74.39916, -78.839064, -83.85044, -88.334303, -87.76283, -86.444047, 14.76522, 14.254698, 11.254812, 4.117319, -6.150488, -4.487817, 8.962027, 13.657628, 14.76522), ncol = 2, byrow = FALSE)
     names(p)<- 5373
     return(p)
}

#' get standard path for CHELSA data
set_envs_dir <- function(base_path = sdmBasePath()) {
    p <- Sys.getenv("CHELSA_PATH")
    if( p == "" ) { p <-  "CHELSA_4_only"}
    p <- file.path(base_path, p)
    return(p)
}

read_envs <- function(envs_dir = set_envs_dir()){

    # NOTE for reference, the current list is c('srtm_crop.tif', 'bio6_1981.2010_V.2.1.tif', 'bio5_1981.2010_V.2.1.tif', 'bio14_1981.2010_V.2.1.tif', 'bio13_1981.2010_V.2.1.tif',"cloud_crop.tif")
    # but here we get the list of file nanmes by reading the names from given folder, which makes it more flexible
    envs_raster_names <-  list.files(envs_dir)

    envs <- wallace::envs_userEnvs(
        rasPath = file.path(envs_dir, envs_raster_names),
        rasName = envs_raster_names,
        doBrick = FALSE)

}


read_occs <-function(species){
    # questionL for txt name why use the file name (a..p..thined ) vs just the species per Wallace documentation https://rdrr.io/cran/wallace/man/occs_userOccs.html
    #occs_path <- "/Volumes/BETH'S DRIV/zarnetske_lab/candidate_species_2022/thinned_data/Alouatta_palliata_thinned_full"
    #occs_path <- file.path(occs_path, "Alouatta_palliata_thinned_thin1.csv")

    # https://rdrr.io/cran/wallace/man/occs_userOccs.html
    userOccs_sp <- wallace::occs_userOccs(
        txtPath = file.path(occsDataPath(species), occsDataFilename(species)),
        txtName = occsDataFilename(species),
        txtSep = ",",
        txtDec = ".")

    return(userOccs_sp[[species]]$cleaned)
}

# Query selected database for occurrence records. These have been pre-thinned by 10km.
process_occs <- function(occs, envs, poly_matrix) {

    if(!is.null(names(poly_matrix))){
        poly_id = names(poly_matrix)[1]
    } else {
        warning("polygon parameter does not have an id. use names() to set the id")
        return(NULL)
    }


    occs_xy <- occs[c('longitude', 'latitude')]
    occs_vals <- as.data.frame(raster::extract(envs, occs_xy, cellnumbers = TRUE))
    # remove occurrence records with NA environmental values
    occs_2<- occs[!(rowSums(is.na(occs_vals)) >= 1), ]
    # also remove variable value rows with NA environmental values
    occs_vals_2 <- na.omit(occs_vals)
    # add columns for env variable values for each occurrence record
    occs <- cbind(occs_2, occs_vals_2)


    #Remove occurrences outside of user drawn polygon
    #NOTE if there are no values to remove, poccs_selectOccs() returns NULL!!!
    occs_or_null <- wallace::poccs_selectOccs(
        occs = occs,
        polySelXY = poly_matrix,
        polySelID = poly_id
    )

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
run_model <- function(occs, envs, species, partitioning_alg = 'randomkfold'){


    # check param is compatible with ENMeval
    if( ! (partitioning_alg %in% c("randomkfold", "jackknife", "block", "checkerboard1", "checkerboard2", "testing", "none"))) {
        warning(paste("partioning_alg param value", partitioning_alg, "is not an option for ENMevaluate, exiting"))
        return()
    }

    bgData <- bg_sampling(occs, envs, species)
    #generate full prediction extent for input into 'envs'
    envs_cropped <- crop(envs, bgData$bgExt)
    #subset occs_ap to longitude and latitude
    occs_ll <- occs[,c("longitude","latitude")]

    ##RUN 1
    #Need to use Maxent.jar because of the ability to see perm importance
    #will have to store maxent jar file on HPC? Maxent uses this file to run.
    e.mx <- ENMeval::ENMevaluate(occs = occs_ll, envs = envs_cropped, bg = bgData$bgSample,
                          algorithm = 'maxent.jar', partitions = partitioning_alg,
                          tune.args = list(fc = c("LQHP"), rm = 1))

    return(e.mx)
}

#' write components of ENMevaluation to disk
save_model <- function(e.mx, species, radiusKm, run_number, outputPath){

    e.mx.results <- e.mx@results
    # "a_palliata_ENMeval_1x_results.1.run1.csv"
    results.Filename = paste0(species, "_ENMeval_1x_results.",radiusKm,".run.",run_number,".csv")
    write.csv(e.mx.results, file=file.path(outputPath, results.Filename))

    # minimize AICc
    # evaluated the AICc within 2 delta units
    minAIC <- e.mx.results[which(e.mx.results$delta.AICc <= 2),] #Make sure the column is delta.AICc
    minAIC.Filename <- paste0(species, "_min_AIC_em.x.", radiusKm, "_run",run_number,".csv")
    # NOTE this file name is changed from original model_evaluation script to accommodate radius and run number
    write.csv(minAIC,file=file.path(outputPath, minAIC.Filename))


    #Generate table of performance stats
    e.mx.stats <- e.mx.results[c("auc.train","cbi.train")]
    stats.Filename <- paste0(species, "_stats_e.mx.",radiusKm, "_run", run_number,".csv")
    # "a_palliata_stats_e.mx.1_run1.csv"
    write.csv(e.mx.stats, file.path(outputPath, stats.Filename))


    # variable importance table
    e.mx.var.imp <-e.mx@variable.importance$fc.LQHP_rm.1
    #"a_palliata_permutation_imp_e.mx.1.run1.csv"
    varimp.Filename <- paste0(species, "_imp_e.mx.",radiusKm, "_run", run_number,".csv")

    write.csv(e.mx.var.imp, file = file.path(outputPath, varimp.Filename))

    #write prediction to file
    # filename="e.mx.1.pred.run1.tif"
    prediction.Filename = paste0(species, "_pred_e.mx.",radiusKm, "_run", run_number,".csv")
    writeRaster(e.mx@predictions$fc.LQHP_rm.1, filename=file.path(outputPath, prediction.Filename), format="GTiff", overwrite=T)

}
