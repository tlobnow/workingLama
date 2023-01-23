#!/usr/bin/env bash
source 00_source.inc

#################################################################
### ARE ALL FASTA FILES PREPARED AS FEATURE FILES?? --> CHECK!

for i in $LOC_FASTA/*; do
	if [ -f $LOC_FEATURES/$(basename -a -s .fasta $i)/features.pkl ]; then
                        echo " (─ ‿ ─)  $(basename -a -s .fasta $i) READY!"
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

if [ $CONTINUE = "TRUE" ]; then
	#################################################################
	### COPY THE TEMPLATE FOLDER TO CREATE A DIRECTORY FOR THIS RUN
	
	[ -f ${LOC_SCRIPTS}/myRuns/$OUT_NAME ] || cp -r ${LOC_SCRIPTS}/template ${LOC_SCRIPTS}/myRuns/$OUT_NAME
	
	#################################################################
	### GO INTO THE FOLDER
	
	cd ${LOC_SCRIPTS}/myRuns/$OUT_NAME
	
	### SET FILE NAME IN USER PARAMETERS
	echo FILE=$OUT_NAME  > 00_user_parameters.inc
	
	### SET TARGET STOICHIOMETRY
	echo $STOICHIOMETRY > target.lst
	
	### START SLURM SUBMISSION DEPENDING ON CURRENT PROGRESS STATUS
	if [ -f $LOC_OUT/$OUT_NAME_rlx_model_1.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_2.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_3.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_4.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_5.pdb ]
		then
		[ -f $LOC_OUT/model_*_*_*_*_*_*.pkl ] && rm $LOC_OUT/model_*_*_*_*_*_*.pkl
		echo "(2) PREDICTION OF $OUT_NAME FINISHED SUCCESSFULLY."
		echo "(3) RELAXATION OF $OUT_NAME FINISHED SUCCESSFULLY."
		echo "(4) R PREPARATION OF $OUT_NAME FINISHED SUCCESSFULLY."
	        echo "(5) PIPELINE FINISHED SUCCESSFULLY. FILES:"
		cd $LOC_OUT
		mkdir -p $LOC_OUT/JSON
		mkdir -p $LOC_OUT/UNRLXD
		for i in {1..5}; do
		  [ -f $OUT_NAME_model_${i}.pdb ] && mv $OUT_NAME_model_${i}.pdb $LOC_OUT/UNRLXD/$OUT_NAME_model_${i}.pdb
		  [ -f model_${i}_*_*_*_*_*.pkl ] && rm model_${i}_*_*_*_*_*.pkl
		  [ -f $OUT_NAME_ranking_model_${i}.json ] && mv $OUT_NAME_ranking_model_${i}.json $LOC_OUT/JSON/$OUT_NAME_ranking_model_${i}.json
		done
		ls $LOC_OUT
		echo "---------------------------------------------------"

	elif [ -f $LOC_OUT/ranking_model_1_*_*_*_*_*.json -a $LOC_OUT/ranking_model_2_*_*_*_*_*.json -a $LOC_OUT/ranking_model_3_*_*_*_*_*.json -a $LOC_OUT/ranking_model_4_*_*_*_*_*.json -a $LOC_OUT/ranking_model_5_*_*_*_*_*.json ]
		then
		[ -f $LOC_OUT/model_1_*_*_*_*_*.pkl ] && rm *.pkl
		echo "(2) PREDICTION OF $OUT_NAME FINISHED SUCCESSFULLY."
		if [ -f $LOC_OUT/relaxed_model_1_*_*_*_*_*.pdb -a $LOC_OUT/relaxed_model_2_*_*_*_*_*.pdb -a $LOC_OUT/relaxed_model_3_*_*_*_*_*.pdb  -a $LOC_OUT/relaxed_model_4_*_*_*_*_*.pdb -a $LOC_OUT/relaxed_model_5_*_*_*_*_*.pdb ]
			then
			echo "(3) RELAXATION OF $OUT_NAME FINISHED SUCCESSFULLY."
			if [ -f $LOC_OUT/$OUT_NAME_rlx_model_1.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_2.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_3.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_4.pdb -a $LOC_OUT/$OUT_NAME_rlx_model_5.pdb ]
				then
				echo "(5) PIPELINE FINISHED SUCCESSFULLY. SEE $LOC_OUT"
			else
				echo "(4) PREPARING $OUT_NAME FOR ANALYSIS IN R." 
				# this is an integrated 02_R_PREP.sh script

				cd ${LOC_SCRIPTS}/myRuns/$OUT_NAME/
				cat slurm* > ${LOC_OUT}/slurm.out
				mkdir -p ${LOC_SCRIPTS}/myRuns/$OUT_NAME/temp
				mv slurm* ${LOC_SCRIPTS}/myRuns/$OUT_NAME/temp
	
				cd $LOC_OUT
				mkdir -p $LOC_OUT/JSON
				mkdir -p $LOC_OUT/UNRLXD
				for i in {1..5}; do
				  mv model_${i}_*_*_*_*_*.pdb $LOC_OUT/UNRLXD/$OUT_NAME_model_${i}.pdb
				  [ -f model_${i}_*_*_*_*_*.pkl ] && rm model_${i}_*_*_*_*_*.pkl
				  mv relaxed_model_${i}_*   $OUT_NAME_rlx_model_${i}.pdb
				  mv ranking_model_${i}_*   $LOC_OUT/JSON/$OUT_NAME_ranking_model_${i}.json
				done
				[ -f checkpoint ] && rm -r checkpoint
			fi
		else
			cd $LOC_OUT
			[ -f relaxed_* ] && rm relaxed_*
			cd ${LOC_SCRIPTS}/myRuns/$OUT_NAME
        	        #bash ${LOC_SCRIPTS}/myRuns/$OUT_NAME/submit_rlx.sh
			JOBID1=$(sbatch --parsable script3_relaxation.sh)
			echo " ---> ${JOBID1} (RLX ALL)"
		fi

	elif [ -f $LOC_OUT/relaxed_model_1_* ]
		then
		for i in {1..5}; do
			if [ -f $LOC_OUT/model_${i}_*_*_*_*_*.pdb ]
				then
				echo " ---> PREDICTION ${i} DONE."
			else
				[ -f $LOC_OUT/model_${i}_*_*_*_*_*.pkl ] && rm $LOC_OUT/model_${i}_*_*_*_*_*.pkl
        	                #bash ${LOC_SCRIPTS}/myRuns/$OUT_NAME/submit_${i}.sh
				JOBID1=$(sbatch --parsable script2_comp_model_${i}.sh)
				echo " ---> ${JOBID1} (PRED 1)"
        	        fi
        	done

	else echo " ---> NO PREDICTION YET. STARTING SMALL PIPELINE FOR $OUT_NAME"
		#bash ${LOC_SCRIPTS}/myRuns/$OUT_NAME/submit_small_pipe.sh		
		JOBID1=$(sbatch --parsable script2_comp_model_1.sh)
		JOBID2=$(sbatch --parsable script2_comp_model_2.sh)
		JOBID3=$(sbatch --parsable script2_comp_model_3.sh)
		JOBID4=$(sbatch --parsable script2_comp_model_4.sh)
		JOBID5=$(sbatch --parsable script2_comp_model_5.sh)
		JOBID6=$(sbatch --parsable --dependency=afterok:${JOBID1}:${JOBID2}:${JOBID3}:${JOBID4}:${JOBID5} --deadline=now+2weeks script3_relaxation.sh)
		echo " ---> ${JOBID1} (PRED 1)"
		echo " ---> ${JOBID2} (PRED 2)"
		echo " ---> ${JOBID3} (PRED 3)"
		echo " ---> ${JOBID4} (PRED 4)"
		echo " ---> ${JOBID5} (PRED 5)"
		echo " ---> ${JOBID6} (RLX ALL)"
	fi
else echo " ---> NOT STARTING PIPELINE UNTIL ALL FEATURE FILES ARE GENERATED.. GIMME SOME TIME!" ; fi
