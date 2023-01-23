source 00_user_parameters.inc

FILE=$FILE

# Comma-separated list of protein data, passed to alphafold via --fasta_paths
FASTA_PATHS=~/lazyLama/fasta_files/$FILE.fasta

# Output directory to write the results to, passed via --output
OUTPUT_DIR=~/lazyLama/feature_files/

# Preset for alphafold, passed via --db_preset
PRESET="full_dbs"

