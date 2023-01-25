#!/bin/bash

#SBATCH --time=03:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=80gb
#SBARCH --constraint="amd20\|intel18"
#SBATCH --output=myjob.sb.o%j
#SBATCH --error=myjob.sb.e%j

# rely on .Renviron in this folder for now, but these should be set
# export SDM_BASE_PATH="/mnt/scratch/billspat/neotropical_frugivores/andes_geodiv"
# export SDM_OCCS_PATH="occurrence_records"
# export SDM_ENVS_PATH="environmental_variables"
# export SDM_OCCS_PATH_TEMPLATE='occurrence_records/%s_thinned_full'
# export SDM_OCCS_FILE_TEMPLATE='%s_thinned_wallace.csv'
# export SDM_SPECIES
# export SDM_RUN_NUMBER
# export SDM_OUTPUT_PATH


RADII=( 1 3 9 15 21 27 33 )
# RUNS=( 1 2 3 4 5 )

# time: 7 radii * 5 runs; 5 minutes per run; => time =~ 3 hrs
# memory: 4gb per process X 20 process = 80gb

# use env variables, but use defaults if they are not set
SPECIES="${SDM_SPECIES:-Alouatta_palliata}"
RUN_NUMBER="${SDM_RUN_NUMBER:-1}"
OUTPUT_PATH="${SDM_OUTPUT_PATH:-$HOME/sdm_model_runs}"
for RADIUS in "${RADII[@]}";do
  Rscript --no-save  --no-init-file --no-restore  sdm_run.R $SPECIES $RADIUS $RUN_NUMBER /tmp/billspat/test_output_Alouatta_palliata $SLURM_JOB_CPUS_PER_NODE
done  