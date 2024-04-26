#!/bin/bash
#SBATCH --account=paternabio-rw
#SBATCH --partition=paternabio-shared-rw
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --mail-user=
#SBATCH --mail-type=ALL


echo "Starting "$SUBDIR

module load deeplearning/2022.1

python /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/python/stardist_v2.py "$SUBDIR"

echo "Finished "$SUBDIR

module unload deeplearning/2022.1
