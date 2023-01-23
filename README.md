# workingLama
A pipeline designed to simultaneously process multiple samples from FASTA to multimeric models based on AlphaFold algorithms (AF Multimer) and AF2C scripts optimized for complex prediction. Scripts are written to work on the HPC RAVEN cluster (MPCDF) using SLURM as the workload manager.

### 1. Clone the git repository into your workplace (In your home directory)

```
git clone https://github.com/FreshAirTonight/af2complex
git clone https://github.com/tlobnow/workingLama.git
```

### 2. Prepare the environment

#### 2.1. Miniconda
Do you have Miniconda installed? If not or you're not sure, please copy and execute the following:
We will move the miniconda setup script into your home directory and will install it there.
Download the script from "https://docs.conda.io/en/latest/miniconda.html" and upload it in your home directory.
Execute the script in your home directory with "./Miniconda_vX_XXX_XXX.sh"
This may take a little while.. (once installed, you can move/remove the script as you like)

#### 2.2. Let's set up the environment for AF2Complex

```
pip uninstall -y tensorflow
cd af2complex && pip -u install -r requirements.txt
pip install -u --upgrade jax==0.2.14 jaxlib==0.1.69+cuda111 -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
```

### 3. Add your fasta files in *fasta_files*

To run multiple samples, you should create a folder and drop all your files in there (inside the  fasta_files dir)
File names should end with EXAMPLE.fasta (see example in folder). Folders can be created with:

```
mkdir FOLDER_NAME
```

If you start with a combined fasta file (multiple sequences in one file), you can **split** your files using a neat little function called *splitfasta*. This will automatically create a folder named *EXAMPLE_split_files* and store the new files as *EXAMPLE_{1..X}.fasta*, so it will **not** extract the FASTA description ...

  Can be installed with:

  ```
  pip install splitfasta
  ```
  
  Usage:

  ```
  splitfasta EXAMPLE.fasta
  ```

To work from a folder, you don't have to do anything else. Leave them in there.
To work on individual files and more complex stoichiometric targets, please copy your fasta files *directly* into fasta_files, not in subfolders.


### 4. Adjust the base file

#### 4a) Work on complex targets for individual files (heteromeric) --> 00_source.inc in *scripts*

1. Enter the output name you want to generate (e.g. MYD88_x6 for a homohexamer, go wild if you want)
2. Adjust the stoichiometry (00_source.inc contains a lot of info on stoichiometry setup)

#### 4b) Work on multiple files with simple stoichiometries (homomeric) --> 01_source.inc in *scripts*

1. Enter the name of the folder you want to work on (e.g. TEST)
2. Enter the stoichiometry (how many homomeric monomers do you want to run? (e.g. 6))


### 5. Start the pipeline

Enter the **scripts** directory to start the pipeline.

If you run this script **ONCE**, you will run MSA and model prediction, unless RAVEN crosses your plans, the relaxation should also finish. Run again, if you're unsure. The pipeline will automatically determine the current progress status and start the necessary scripts.
Run this script **AGAIN** to ensure that all processes have finished and to prepare the output files for analysis in R.

#### 5a) For complex heteromeric targets, run:

```
./oneWayRun.sh
```

#### 5b) For multiple homomeric targets, run:

```
./multiRun.sh
```

You can check your slurm job status with `./squeue_check.sh` or manually via `squeue -u $USER`

Slurm jobs can be cancelled with: `scancel $JOBID`
ALL currently running jobs can be cancelled with: `scancel -u $USER`

### Folder Structure Main

  - *fasta_files*: where fasta files are stored
  - *feature_files*: output from the MSA lands here (msa folder + **.pkl** file)
  - *output_files*:  where modeling results are stored
  - *scripts*: everything you need to run the pipeline

#### Folder Structure fasta_files

  - yup. This is where the fasta files should go.
  - **Attention!** The pipeline is designed to prepare all feature files to ensure seamless downstream modeling (otherwise you will get errors because feature files are missing etc.)

#### Folder Structure feature_files

  - Multiple Sequence Alignment (MSA, performed with script1_msa.sh) produces:
    - features.pkl file - pickle file that functions as input for modeling
    - msa folder - contains some info from the MSA

#### Folder Structure output_files

  - Modeling Scripts (performed with script2_comp_model_{1..5}.sh) produce:
    - model_{1..5}_XXX.pdb
    - model_{1..5}_XXX.pkl
    - ranking_model_{1..5}_XXX.json
    
  - Relaxation Scripts (performed with script3_relaxation.sh) produces:
    - relaxed_model_{1..5}_XXX.pdb

  - If you prepare results for R, you will rename the files for easier tracking (otherwise everything looks the same aside from 6-digit job numbers)
    - model_{1..5}_XXX.pdb --> /UNRLXD/$OUT_NAME_model_{1-5}.pdb *OR for simple* /UNRLXD/${FILE}_model_${i}_x${N}.pdb
    - relaxed_model_{1-5}_XXX.pdb --> $OUT_NAME_rlx_model_{1-5}.pdb *OR for simple* ${FILE}_rlx_model_${i}_x${N}.pdb
    - pkl files take up tons of space and are removed, unless you specifically want to keep them
    - slurm* --> ${LOC_SCRIPTS}/myRuns/$OUT_NAME/temp *OR for simple* ${LOC_SCRIPTS}/myRuns/${FILE}/temp_x${N}
      - The SLURM output files from the scripts folder are concatenated and the original files are moved to "temp", to separate old from new files
      - The concatenaed SLURM file is moved into the output folder

#### Folder Structure scripts

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
  - prepYourFeatures.sh = script to manually start the feature file generation
  - squeue_check.sh = script to show currently running jobs


##### Folder Structure template

This folder is copied for each file. The original slurm files will be stored here (concatenated slurm files are moved into the output folder for analysis)

  - 00_user_parameters.inc  = contains file name, created when pipeline starts
  - 01_user_parameters.inc  = specify variables for script1_msa.sh
  - 02_user_parameters.inc  = -..- script2_comp_model_{1..5}.sh
  - script1_msa.sh          = script for Multiple Sequence alignment
  - script2_comp_model_{1..5}.sh = script for structure prediction with multimer neural network 1-5
  - script3_relaxation.sh   = script for relaxation (getting rid of unphysical clashes) of all models
  - target.lst              = contains modeling stoichiometry, created when pipeline starts
  - temp                    = folder with old (already processed) slurm files
