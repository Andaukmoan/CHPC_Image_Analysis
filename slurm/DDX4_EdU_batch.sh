#!/bin/bash
#SBATCH --account=paternabio-rw
#SBATCH --partition=paternabio-shared-rw
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --mem 384G
#SBATCH --time=24:00:00
#SBATCH --mail-user=
#SBATCH --mail-type=ALL

#Path to input folder. This folder cannot have any other files in it except the files for analysis. The files cannot be in a subfolder.
INIMG=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/images/practice
#Path to output folder. This folder needs to be unique to each run otherwise files will get over written or combined.
OUTXL=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/output/practice
#Path CellProfiler Pipeline File.
CPPIPE=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/v7_DDX4_EdU/DDX4_EdU_v8.4.cppipe
NTASKS=$SLURM_CPUS_ON_NODE
CDIR=$PWD

#Split images into folders that can each be analyzed separately based on the number of available tasks.
FOLDERARRAY=($INIMG/*.TIF)
FOLDERSIZE=${#FOLDERARRAY[@]}
SUBDIRSIZE=$(($FOLDERSIZE/$NTASKS+1))
echo $SUBDIRSIZE" SUBDIRSIZE"

NUCLEIARRAY=($INIMG/*_R_*d0.TIF)
NUMNUCLEI=${#NUCLEIARRAY[@]}
echo $NUMNUCLEI" NUMNUCLEI"

for ((SUBDIR=1; SUBDIR<=$NTASKS; SUBDIR+=1));
do
    mkdir -p "$INIMG/$SUBDIR";
    FOLDER=($INIMG/*.TIF)
    SIZE=${#FOLDER[@]}
    if [$SIZE < $SUBDIRSIZE]; then
       $SUBDIRSIZE=$SIZE
    fi
    for ((image=0; image<$SUBDIRSIZE; image+=1));
    do
        mv "${FOLDER[$image]}" "$INIMG/$SUBDIR"
    done
done

#Create an independent run for each subfolder and process with stardist to get around python's global interpreter lock.
for FOLDER in `seq 1 $NTASKS`; do
    (
        SUBDIR="$INIMG/$FOLDER"
        srun -n 1 -c 1 --mem-per-cpu=4gb --export=ALL,SUBDIR=$SUBDIR /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/slurm/parallel_stardist.sh
    )  &
done

wait
echo "Finished Segmentation"

#Move all images from subfolders into main folder. CellProfiler sometimes gets tripped up by subfolders.

for ((SUBDIR=1; SUBDIR<=$NTASKS; SUBDIR+=1));
do
    DIR="$INIMG/$SUBDIR";
    FOLDER=($DIR/*)
    SIZE=${#FOLDER[@]}
    for ((image=0; image<$SIZE; image+=1));
    do
        mv "${FOLDER[$image]}" "$INIMG"
    done
done

STARARRAY=($INIMG/*labels.tif)
NUMSTAR=${#STARARRAY[@]}
echo $NUMSTAR" NUMSTAR"

#Check if there is a segmented image for each nuclei image before continuing to cellprofiler, so you don't find out after cellprofiler has run for hours.
if [ $NUMSTAR != $NUMNUCLEI ]; then
  echo "Error: Incomplete Segmentation. Check for missing labels and the presence of merged/display files"
  exit
fi

#Get the number of images sets ($SETS).
ARRAY=($INIMG/*) 
LENGTH=$((${#ARRAY[@]} - $(find $INIMG/* -type d | wc -l) ))
echo $LENGTH" LENGTH"
SETS=$NUMNUCLEI

#Split the number of image sets into groups based on the number of tasks available. $MYARRAY will contain the start and stop position for images in each group.
TASKSIZE=$(($SETS/$NTASKS+1))
echo $TASKSIZE" TASKSIZE"
MYARRAY=($(awk -v SETS="$SETS" -v SIZE="$TASKSIZE" 'BEGIN{e=SIZE-1;m=SETS;for(i=1;i<=m;i+=SIZE){k=m-i;if(k<SIZE){e=k};print i, i+e}}'))
echo "${MYARRAY[1]}"" START_ARRAY"
echo "${MYARRAY[-1]}"" END_ARRAY"

module load cellprofiler

if [ ! -d "$OUTXL" ]; then
  mkdir "$OUTXL"
fi

#Create a separate task of cellprofiler for each image group. This allows us to run up to 64 instances of cellprofiler in parrallel.

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


#Create directory to store formatted counts
OUTDIR="${OUTXL}/counts"

if [ ! -d "$OUTDIR" ]; then
  mkdir "$OUTDIR"
fi

echo "$OUTDIR"

module load R

#Run an r script to format the data by plate and create subfolders for each experiment that can be directly uploaded to google drive and shared with everyone.

Rscript /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/R/format_data_5.R --args "$OUTXL"

module unload R

echo "Finished R script"

#Move all the annotated output images to a single folder. This makes handling them easier.

OUTIMAGE="${OUTXL}/images"

if [ ! -d "$OUTIMAGE" ]; then
  mkdir "$OUTIMAGE"
fi

LIMIT=$(($NTASKS*2))
for ((SUBDIR=1; SUBDIR<=$LIMIT; SUBDIR+=2));
do
    DIR="$OUTXL/$SUBDIR";
    FOLDER=($DIR/*.jpeg)
    SIZE=${#FOLDER[@]}
    for ((image=0; image<$SIZE; image+=1));
    do
        mv "${FOLDER[$image]}" "$OUTIMAGE"
    done
done


#Split up the annotated images by plate. This will go through each unique plate in the data set and move the associated images to the folder that has the formatted output for that plate. This allows for the folder to be directly uploaded to google drive with all the relevant files for the given plate. 

#Get list of folders in counts folder

cd $OUTDIR
shopt -s nullglob
array=(*)
shopt -u nullglob
cd $CDIR

#Move images to folder with matching name

for ((FOLDER=0; FOLDER<="${#array[@]}"; FOLDER+=1));
do
    OUTFOLDER="$OUTDIR/${array[$FOLDER]}"
    echo $OUTFOLDER" FOLDER "$FOLDER  
    IMAGES=($OUTIMAGE/${array[$FOLDER]}*)
    SIZE=${#IMAGES[@]}
    for ((image=0; image<$SIZE; image+=1));
    do
        mv "${IMAGES[$image]}" "$OUTFOLDER"
    done
done

echo "Finished Analysis"
