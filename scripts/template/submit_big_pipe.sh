#!/bin/bash

#SBATCH -J AF2-GNRL
#SBATCH --ntasks=1
#SBATCH --mail-type=NONE
#SBATCH --mail-user=$USER@mpiib-berlin.mpg.de
#SBATCH --time=06:00:00

set -e

JOBID1=$(sbatch --parsable script1_msa.sh)
JOBID2=$(sbatch --parsable --dependency=afterok:${JOBID1} --deadline=now+2weeks script2_comp_model_1.sh)
JOBID3=$(sbatch --parsable --dependency=afterok:${JOBID1} --deadline=now+2weeks script2_comp_model_2.sh)
JOBID4=$(sbatch --parsable --dependency=afterok:${JOBID1} --deadline=now+2weeks script2_comp_model_3.sh)
JOBID5=$(sbatch --parsable --dependency=afterok:${JOBID1} --deadline=now+2weeks script2_comp_model_4.sh)
JOBID6=$(sbatch --parsable --dependency=afterok:${JOBID1} --deadline=now+2weeks script2_comp_model_5.sh)
JOBID7=$(sbatch --parsable --dependency=afterok:${JOBID2}:${JOBID3}:${JOBID4}:${JOBID5}:${JOBID6} --deadline=now+2weeks script3_relaxation.sh)

echo "Submitted jobs"
echo "    ${JOBID1} (MSA)"
echo "    ${JOBID2} (PRED 1)"
echo "    ${JOBID3} (PRED 2)"
echo "    ${JOBID4} (PRED 3)"
echo "    ${JOBID5} (PRED 4)"
echo "    ${JOBID6} (PRED 5)"
echo "    ${JOBID7} (RLX ALL)"
