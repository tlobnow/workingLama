# workingLama
A pipeline designed to simultaneously process multiple samples from FASTA to multimeric models based on AlphaFold algorithms (AF Multimer) and AF2C scripts optimized for complex prediction. Scripts are written to work on the HPC RAVEN cluster (MPCDF) using SLURM as the workload manager.

### 1. Clone the git repository into your workplace (home directory)

```
git clone https://github.com/FreshAirTonight/af2complex
git clone https://github.com/tlobnow/workingLama.git
```

### 2. Prepare the environment

Update and activate the environment.

```
conda env update -n ~/workLama/loadLama --file
conda activate loadLama --file ~/workingLama/loadLama.yml

cd af2complex/src/
python -m pip install . -vv
```


--> For every new session from now on, you should run `conda activate loadLama`


### 3. Add your fasta files in *fasta_files* and prepare features

To work on individual files and more complex stoichiometric targets, please copy your fasta files *directly* into fasta_files, not in subfolders.

To run multiple samples, you should create a folder and drop all your files in there (inside the  fasta_files dir)

File names should end with EXAMPLE.fasta (see example in folder). Folders can be created with:

```
mkdir FOLDER_NAME
```

If you start with a combined fasta file (multiple sequences in one file), you can **split** your files using a neat little function called *splitfasta*. This will automatically create a folder named *EXAMPLE_split_files* and store the new files as *EXAMPLE_{1..X}.fasta*, so it will **not** extract the FASTA description ... (install via `pip install splitfasta`)

In order to prepare all files for complex prediction, run the following script:

```
~/workingLama/scripts/prepYourFeatures.sh
```

### 4. Adjust the base file

#### 4a) Work on targets for single files (homo-/heteromeric) --> 00_source.inc in *scripts*

1. Enter the **output name** you want to generate (e.g. MYD88_x6 for a homohexamer, or go wild..)
2. Adjust the **stoichiometry** (00_source.inc contains more info on stoichiometry setup)


#### 4b) Work on multiple files with simple stoichiometries (homomeric) --> 01_source.inc in *scripts*

1. Enter the name of the folder you want to work on (e.g. TEST)
2. Enter the stoichiometry (how many homomeric monomers do you want to run? (e.g. 6))



### 5. Start the pipeline

Enter the **scripts** directory to start the pipeline.

Once, the slurm queue finished MSA & prediction, run this script **AGAIN** to prepare the output files for analysis in R.


#### 5a) For single (simple/complex) targets, run:

```
./oneWayRun.sh
```

#### 5b) For multiple simple (homomeric) targets, run:

```
./multiRun.sh
```

You can check your slurm job status with `./squeue_check.sh` or manually via `squeue -u $USER`

I added `./check_squeue.sh` for convenience: Automatically displays current squeue and refreshes every 10 sec (runtime 30min, adjust to your needs).

Slurm jobs can be cancelled with: `scancel $JOBID`

ALL currently running jobs can be cancelled with: `scancel -u $USER`


### MAIN FOLDER STRUCTURE

  - *fasta_files*: where fasta files are stored
  - *feature_files*: output from the MSA lands here (msa folder + **.pkl** file)
  - *output_files*:  where modeling results are stored
  - *scripts*: everything you need to run the pipeline

#### Folder Structure **fasta_files**

  - yup. This is where the fasta files should go.
  - **Attention!** The pipeline is designed to prepare all feature files to ensure seamless downstream modeling (otherwise you will get errors because feature files are missing etc.)

#### Folder Structure **feature_files**

  - Multiple Sequence Alignment (MSA, performed with script1_msa.sh) produces:
    - features.pkl file - pickle file that functions as input for modeling
    - msa folder - contains some info from the MSA

#### Folder Structure **output_files**

  - Modeling Scripts (performed with script2_comp_model_{1..5}.sh) produce:
    - model_{1..5}_XXX.pdb
    - model_{1..5}_XXX.pkl
    - ranking_model_{1..5}_XXX.json
    
  - Relaxation Scripts (performed with script3_relaxation.sh) produces:
    - relaxed_model_{1..5}_XXX.pdb

  - PKL files take up tons of space and are removed, unless you specifically want to keep them

  - If you prepare results for R, you will rename the files for easier tracking (otherwise everything looks the same aside from 6-digit job numbers)
  - FOR **COMPLEX TARGETS**:
    - model_{1..5}_XXX.pdb --> "/UNRLXD/$OUT_NAME_model_{1-5}.pdb"
    - relaxed_model_{1-5}_XXX.pdb --> "$OUT_NAME_rlx_model_{1-5}.pdb"                  
    - slurm* --> moved to "${LOC_SCRIPTS}/myRuns/$OUT_NAME/temp"

  - FOR **SIMPLE TARGETS**:
    - model_{1..5}_XXX.pdb --> "/UNRLXD/${FILE}_model_${i}_x${N}.pdb"    
    - relaxed_model_{1-5}_XXX.pdb --> "${FILE}_rlx_model_${i}_x${N}.pdb"
    - slurm* --> moved to "${LOC_SCRIPTS}/myRuns/${FILE}/temp_x${N}"

  - The SLURM output files from the scripts folder are concatenated and the original files are moved to "temp", to separate old from new files
  - The concatenaed SLURM file is moved into the output folder


#### Folder Structure **scripts**

INPUT INFOS
  - 00_source.inc = contains all important parameter/variable paths for heteromeric targets
  - 01_source.inc = contains all important parameter/variable paths for simple (homomeric) targets
FOLDERS
  - feaGen = folder that contains scripts and subfolders used for generating the feature files
  - lists = folder that contains lists for multiple simple targets
  - template = folder containing all necessary scripts for each run
  - myRuns = folder with your run scripts (the template is copied into a file named like your output)
SCRIPTS
  - oneWayRun.sh = heteromeric pipeline coordinator script. Determines current progress and prompts next scripts
  - multiRun.sh = simple (homomeric) pipeline coordinator script. Determines current progress and prompts next scripts
  - prepYourFeatures.sh = script to manually start the feature file generation (subscripts are stored in /feaGen, output in feature_files)
  - prep4R.sh = script for R preparation 
        - arg1 = script folder name
        - arg2 = output folder name 
        - adjust name modifications as needed
  - squeue_check.sh = script to show currently running jobs = `squeue -u $USER`
  - quit_all_jobs.sh = script to cancel ALL currently running jobs = `scancel -u $USER`

##### Folder Structure **template**

This folder is copied for each file. The original slurm files will be stored here (concatenated slurm files are moved into the output folder for analysis)

  - 00_user_parameters.inc  = contains file name, created when pipeline starts
  - 01_user_parameters.inc  = specify variables for script1_msa.sh
  - 02_user_parameters.inc  = -.- script2_comp_model_{1..5}.sh
  - script1_msa.sh          = script for Multiple Sequence alignment
  - script2_comp_model_{1..5}.sh = script for structure prediction with multimer neural network 1-5
  - script3_relaxation.sh   = script for relaxation (getting rid of unphysical clashes) of all models
  - submit{1..3}_*.sh	    = scripts to directly submit specific pipeline scripts or the entire pipeline
	- big pipeline      = MSA + complex prediction + relaxation
	- small pipeline    = complex prediction + relaxation
  - target.lst              = contains modeling stoichiometry, created when pipeline starts
  - temp                    = folder with old (already processed) slurm files
