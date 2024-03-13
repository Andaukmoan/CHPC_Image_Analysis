#!/bin/bash
#SBATCH --account=paternabio-rw
#SBATCH --partition=paternabio-shared-rw
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem 16G
#SBATCH --time=24:00:00
#SBATCH --mail-user=zach.olsen@paternabio.com
#SBATCH --mail-type=ALL

CPPIPE=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/v7_DDX4_EdU/DDX4_EdU_v7.3.cppipe
INIMG=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/test_stardist
OUTXL=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/SLURM/output

module load deeplearning/2022.1

python /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/stardist/stardist_v2.py "$INIMG"

module unload deeplearning/2022.1

module load cellprofiler

cellprofiler -c -r -p "$CPPIPE" -i "$INIMG" -o "$OUTXL"
