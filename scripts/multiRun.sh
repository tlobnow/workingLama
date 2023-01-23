#!/usr/bin/env bash

module load parallel

source ./01_source.inc

LIST=${LOC_LISTS}/${FOLDER}_inds

################################################################################################
################################################################################################
################################################################################################

### SET UP A LIST OF INDIVIDUALS IN LISTS FOLDER
# = if you cannot find the list for the folder specified above, then create a list with the basenames in that folder.
[ -f $LIST ] || for i in ${LOC_FASTA}/${FOLDER}/*.fasta; do echo $(basename -a -s .fasta $i); done > ${LOC_LISTS}/${FOLDER}_inds

### COPY THE TEMPLATE SCRIPT TO CREATE FOLDER PER INDIVIDUAL
# = read the list file - if you cannot find a folder that carries the same name as the line you are currently reading (list) -> create a folder with 
#   that name by copying the template folder. Once all folders are created, also copy the fasta files into the main fasta_files folder
#   (could also move, but I retain them in the original folder as a backup for reference)

while read -r LIST
do
	FOUND="$(find . -name "$LIST" -print -quit)"
	if [ "x$FOUND" != "x" ]
	then
		echo "Working on $LIST"
	else
		for i in ${LOC_FASTA}/${FOLDER}/*.fasta; do 
			cp -r ${LOC_SCRIPTS}/template ${LOC_SCRIPTS}/myRuns/$(basename -a -s .fasta $i); done
		cp ${LOC_FASTA}/${FOLDER}/*.fasta $LOC_FASTA
	fi
done <$LIST


################################################################################################
################################################################################################
################################################################################################
### ARE ALL FASTA FILES PREPARED AS FEATURE FILES?? --> CHECK!

echo "---------------------------------------------------"
for i in $LOC_FASTA/*.fasta; do
        if [ -f $LOC_FEATURES/$(basename -a -s .fasta $i)/features.pkl ]; then
                        echo " \(^o^)/  $(basename -a -s .fasta $i) READY!"
                        CONTINUE=TRUE
        else echo " ..... $(basename -a -s .fasta $i) FEATURES FILE MISSING -> STARTING MSA!"

                        ### copy the template folder in the feaGen directory and create a folder for each MSA output ###
                        cp -r $LOC_FEA_GEN/feaGen_template $LOC_FEA_GEN/$(basename -a -s .fasta $i)

                        ### enter the new file folder ###
                        cd $LOC_FEA_GEN/$(basename -a -s .fasta $i)

                        ### and save the file name in 00_user_parameters.inc ###
                        echo FILE=$(basename -a -s .fasta $i) > $LOC_FEA_GEN/$(basename -a -s .fasta $i)/00_user_parameters.inc

                        ### prepare an sbatch job and submit it ###
                        set -e
                        JOBID1=$(sbatch --parsable script1_msa.sh)
                        echo " ..... ${JOBID1} (MSA)"
                        CONTINUE=FALSE
        fi
done
echo "---------------------------------------------------"

################################################################################################
################################################################################################
################################################################################################

if [ $CONTINUE = "TRUE" ]; then
	echo "running parallel_multiRun.sh based on ${LOC_LISTS}/${FOLDER}_inds"
	parallel 'sh parallel_multiRun.sh {}' :::: ${LOC_LISTS}/${FOLDER}_inds
else echo " ---> NOT STARTING PIPELINE UNTIL ALL FEATURE FILES ARE GENERATED.. GIMME SOME TIME!" ; fi
