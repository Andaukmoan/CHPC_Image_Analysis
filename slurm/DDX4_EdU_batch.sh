#!/bin/bash
#SBATCH --account=paternabio-rw
#SBATCH --partition=paternabio-shared-rw
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --mem 256G
#SBATCH --time=04:00:00
#SBATCH --mail-user=zach.olsen@paternabio.com
#SBATCH --mail-type=ALL

CPPIPE=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/v7_DDX4_EdU/DDX4_EdU_v7.3.cppipe
INIMG=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/Images/test_stardist
OUTXL=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/SLURM/output/test_stardist
NTASKS=64

module load deeplearning/2022.1

python /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/stardist/stardist_v2.py "$INIMG"

module unload deeplearning/2022.1

module load cellprofiler

LENGTH=($(ls -1 $INIMG | wc -l))

SETS=$(($LENGTH/4))

TASKSIZE=$(($SETS/$NTASKS+1))

if [[$BATCHSIZE -lt 2]]; then
    MYARRAY=($(awk -v SETS="$SETS" 'BEGIN{e=1;m=SETS;for(i=1;i<=m;i+=2){k=m-i;if(k<2){e=k};print i, i+e}}'))
else
    MYARRAY=($(awk -v SETS="$SETS" -v SIZE="$TASKSIZE" 'BEGIN{e=SIZE-1;m=SETS;for(i=1;i<=m;i+=SIZE){k=m-i;if(k<SIZE){e=k};print i, i+e}}'))
fi

if [ ! -d "$OUTXL" ]; then
  mkdir "$OUTXL"
fi

for ODD in $( eval echo {1..${#MYARRAY[@]}..2}); do
    (
        OUTPUT="${OUTXL}/$ODD"
        mkdir "$OUTPUT"
        cellprofiler -c -r -p "$CPPIPE" -i "$INIMG" -o "$OUTPUT" -f "${MYARRAY[$ODD-1]}" -l "${MYARRAY[$ODD]}"
    )  &
    if [[ $(jobs -r -p | wc -l) -ge $NTASKS ]]; then
        wait -n
    fi

done
 
wait

module unload cellprofiler

module load R

Rscript /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/ZachO/R/combine_csv.R --args "$OUTXL"

echo "all done"
