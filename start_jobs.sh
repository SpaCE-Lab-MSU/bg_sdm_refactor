# start_jobs.sh
# run parts of SDM pipeline using shell scripts to launch jobs
#
# usage: 
# must be on HPC and have access to plz-lab lab group
# source start_jobs.sh
# run_one_species_sdm Alouatta_palliata
# run_all_species_sdm
# 

# set our standard paths as globals 
# TODO make this parameters in functions belows rather than globals
export SDM_BASE_PATH="/mnt/research/plz-lab/DATA/neotropical_frugivores/andes_geodiv/"
OCCURRENCE_DATA_DIR="$SDM_BASE_PATH/occurrence_records"

# run for just one species 
run_one_species_sdm () {
  export SDM_SPECIES=$1
  export SDM_OUTPUT_PATH="$SDM_BASE_PATH/sdm_output/$SDM_SPECIES"
  sbatch --array=1-3 --job-name sdm_${SDM_SPECIES} --export=SDM_SPECIES,SDM_OUTPUT_PATH sdm_run_all_radii.sh 
  
}

run_all_species_sdm() {
  SDM_SPECIES_LIST=$(for f in `ls $OCCURRENCE_DATA_DIR/*.csv`; do f=`basename $f`; echo "${f%.csv}" ; done)

  for SDM_SPECIES in $SDM_SPECIES_LIST; do
    run_one_species_sdm $SDM_SPECIES
  done
}

post_process_sdm() {
  source .Renviron
  module purge
  module load GCC/11.2.0  OpenMPI/4.1.1 GDAL R Automake UDUNITS
  export RVER="4.2.2-GCC-11.2.0"
  export R_LIBS_USER=$HOME/R/$RVER
  Rscript --no-save  --no-init-file --no-restore  sdm_average.R $SDM_BASE_PATH/$SDM_OUTPUT_PATH
  # Rscript 
  
}
