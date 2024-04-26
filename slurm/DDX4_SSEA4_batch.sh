#!/bin/bash
#SBATCH --account=paternabio-rw
#SBATCH --partition=paternabio-shared-rw
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --mem 512G
#SBATCH --time=06:00:00
#SBATCH --mail-user=
#SBATCH --mail-type=ALL

#Path to input folder. This folder cannot have any other files in it except the files for analysis. The files cannot be in a subfolder.
INIMG=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/images/test_stardist
#Path to output folder. This folder needs to be unique to each run otherwise files will get over written or combined.
OUTXL=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/output/test_stardist
#Path to output folder. This folder needs to be unique to each run otherwise files will get over written or combined.
CPPIPE=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/v7_DDX4_SSEA4/DDX4_SSEA4_v7_slurm.cppipe
NTASKS=$SLURM_CPUS_ON_NODE

FOLDERSIZE=$(($(find $INIMG/* -maxdepth 0 -type f | wc -l)/$NTASKS+1))
echo $FOLDERSIZE" FOLDERSIZE"

for FOLDER in `seq 1 $NTASKS`;
do
    mkdir -p "$INIMG/$FOLDER";
    find $INIMG/* -maxdepth 0 -type f | head -n $FOLDERSIZE | xargs -i mv "{}" "$INIMG/$FOLDER"
done

for FOLDER in `seq 1 $NTASKS`; do
    (
        IMGDIR="$INIMG/$FOLDER"
        srun -n 1 -c 1 --mem-per-cpu=4gb --export=ALL,SUBDIR=$IMGDIR /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/slurm/parallel_stardist.sh
    )  &
done

wait
echo "Finished Segmentation"

find $INIMG/* -maxdepth 1 -type f | xargs -i mv "{}" $INIMG

LENGTH=($(find $INIMG/* -maxdepth 0 -type f | wc -l))
echo $LENGTH" LENGTH"

SETS=$(($LENGTH/4))
TASKSIZE=$(($SETS/$NTASKS+1))
echo $TASKSIZE" TASKSIZE"
MYARRAY=($(awk -v SETS="$SETS" -v SIZE="$TASKSIZE" 'BEGIN{e=SIZE-1;m=SETS;for(i=1;i<=m;i+=SIZE){k=m-i;if(k<SIZE){e=k};print i, i+e}}'))
echo "${MYARRAY[1]}"" START_ARRAY"
echo "${MYARRAY[-1]}"" END_ARRAY"

module load cellprofiler

if [ ! -d "$OUTXL" ]; then
  mkdir "$OUTXL"
fi

for ((ODD=1; ODD<${#MYARRAY[@]}; ODD+=2)); do
    (
        OUTPUT="${OUTXL}/$ODD"
        mkdir "$OUTPUT"
        cellprofiler -c -r -p "$CPPIPE" -i "$INIMG" -o "$OUTPUT" -f "${MYARRAY[$ODD-1]}" -l "${MYARRAY[$ODD]}"
    )  &
done
 
wait

module unload cellprofiler

echo "Finished CellProfiler"

OUTDIR="${OUTXL}/counts"

if [ ! -d "$OUTDIR" ]; then
  mkdir "$OUTDIR"
fi

echo "$OUTDIR"

module load R

Rscript /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/R/format_data_DDX4_SSEA4.R --args "$OUTXL"

echo "Finished Analysis"
