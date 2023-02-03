

OCCURRENCE_DATA_DIR="/mnt/research/plz-lab/DATA/neotropical_frugivores/andes_geodiv/occurrence_records"
SDM_SPECIES_LIST=$(for f in `ls $OCCURRENCE_DATA_DIR/*.csv`; do f=`basename $f`; echo "${f%.csv}" ; done)

for SDM_SPECIES in $SDM_SPECIES_LIST; do

  SDM_OUTPUT_PATH="/mnt/research/plz-lab/DATA/neotropical_frugivores/andes_geodiv/sdm_output/$SDM_SPECIES"
  
  
  sbatch --array=1-3 --job-name sdm_${SDM_SPECIES} --export=SDM_SPECIES,SDM_OUTPUT_PATH sdm_run_all_radii.sh 

done
