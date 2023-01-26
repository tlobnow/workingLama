#!/usr/bin/env bash

# SCRIPTS FOLDER NAME = $1
# OUTPUT FILE NAME    = $2

source ./00_source.inc

### ENTER SCRIPTS FOLDER AND MERGE SLURM FILES INTO 'SLURM.OUT'
cd ${LOC_SCRIPTS}/myRuns/${1}
cat slurm* > ~/workingLama/output_files/${2}/slurm.out
mkdir -p ${LOC_SCRIPTS}/${1}/temp/
mv slurm* ${LOC_SCRIPTS}/${1}/temp/


LOC_OUT=~/workingLama/output_files/$2

# ENTER THE OUTPUT FOLDER
cd $LOC_OUT

mkdir -p $LOC_OUT/JSON
mkdir -p $LOC_OUT/UNRLXD

for i in {1..5}; do
  mv model_${i}_*_*_*_*_*.pdb $LOC_OUT/UNRLXD/${2}_model_${i}_x${N}.pdb
  [ -f model_${i}_*_*_*_*_*.pkl ] && rm model_${i}_*_*_*_*_*.pkl
  mv relaxed_model_${i}_*   ${2}_rlx_model_${i}_x${N}.pdb
  mv ranking_model_${i}_*   $LOC_OUT/JSON/${2}_ranking_model_${i}.json
done

[ -f checkpoint ] && rm -r checkpoint
