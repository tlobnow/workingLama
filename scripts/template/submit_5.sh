#!/bin/bash

#SBATCH -J AF2-GNRL
#SBATCH --ntasks=1
#SBATCH --mail-type=NONE
#SBATCH --mail-user=$USER@mpiib-berlin.mpg.de
#SBATCH --time=06:00:00

set -e

JOBID1=$(sbatch --parsable script2_comp_model_5.sh)

echo "Submitted jobs"
echo "    ${JOBID1} (PRED 5)"
