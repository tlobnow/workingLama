## Set user parameters for alphafold, common to MSA and prediction jobs

### source general path variables from main scripts folder
source ~/workingLama/scripts/00_source_inc

### source file name for this MSA
source 00_user_parameters.inc
FILE=$FILE

# Comma-separated list of protein data, passed to alphafold via --fasta_paths
FASTA_PATHS=$LOC_FASTA/$FILE.fasta

# Output directory to write the results to, passed via --output
OUTPUT_DIR=$LOC_FEATURES

# Preset for alphafold, passed via --db_preset
PRESET="full_dbs"

