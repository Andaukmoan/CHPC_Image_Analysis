
#Shebang that sets type of file this (bash) and how to process it. For shell (.sh) scripts, this will always be bash. (probably)
#!/bin/bash 

#"SBATCH"" option that sets what account to use for this file
#SBATCH --account=paternabio-rw

#"SBATCH"" option that sets what partition to use for this file. "paternabio-shared-rw" lets multiple jobs run at the same time.
#SBATCH --partition=paternabio-shared-rw

#"SBATCH"" option that sets how many nodes to use. "paternabio-shared-rw" only has 1 node.
#SBATCH --nodes=1

#"SBATCH"" option that sets how many tasks (or subprocesses) to allocate to this job. The max on our node is 64.
#Jobs that benefit from parallel processing should be run on more tasks (such as cellprofiler).
#SBATCH --ntasks=64

#"SBATCH"" option that sets how much memory (RAM) to assign to the job. Our node has 1,020G available.
#Jobs that benefit from more memory should be given more (such as gene alignment). 
#Cellprofiler does not require huge quantities of memory, but you will need a minimum of 4G per task.
#SBATCH --mem 512G

#"SBATCH"" option that sets maximum run time for the job. This prevents jobs stuck in a loop from continuing for ever.
#CHPC has an external limit of ~72 so we can't run jobs longer than that. We usually set it to 24 hrs. If a job runs properly, we should never hit that limit.
#SBATCH --time=06:00:00

#"SBATCH"" option that sets user to email job status.
#SBATCH --mail-user=zach.olsen@paternabio.com

#"SBATCH"" option that sets what type of mail to receive. Default is an email when the job starts, an email when the job finishes, and an email if there is an error.
#SBATCH --mail-type=ALL

#Path to input folder. This folder cannot have any other files in it except the files for analysis. The files cannot be in a subfolder.
INIMG=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/images/test_stardist
#Path to output folder. This folder needs to be unique to each run otherwise files will get over written or combined.
OUTXL=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/output/test_stardist
#Path to cellprofiler pipeline. This works best with a ".cppipe" file, so that we can set the images to be analyzed to our input directory.
CPPIPE=/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/v7_DDX4_EdU/DDX4_EdU_v7.4.cppipe
#This gets the number of tasks available for this job. This is the value set by "#SBATCH --ntasks="
NTASKS=$SLURM_CPUS_ON_NODE

#FOLDERSIZE is the number of images to put into each subfolder so that we can run an independent subprocess on each folder. 
#"find $INIMG/*" says to get files of any(*) name in that location. "-maxdepth 0" says not to get files in a subfolder. "-type f" says to just get files and not folders.
# "|" is a vertical bar or pipe that passes the output from the left side to the argument on the right side.
#"wc -l" gets the number of lines in the input which in this case is the number of files in our input directory.
#"$()" sets the output of this command as a temporary variable that can be passed into another command.
#We are dividing the number of files by the number of tasks ($NTASKS) to get how many images we can give each task to analyze. 
#"$(())" sets this as a math equation (otherwise it would be treated as a character string).
#The default behavior for equations in linux is to return an integer (rounded down). To prevent this from resulting in some images not being analyzed, "+1" is added to the result.
FOLDERSIZE=$(($(find $INIMG/* -maxdepth 0 -type f | wc -l)/$NTASKS+1))
#echo will print the output to the output file to check that this variable was properly set.
echo $FOLDERSIZE" FOLDERSIZE"


#This "for loop" will go from 1 to the number of tasks to split the input files into "NTASKS" number of subfolders.
for FOLDER in `seq 1 $NTASKS`;
do
    #Make a new folder at the location of "$INIMG/$FOLDER". The -p flag prevents errors if this folder already exists or parent folders do not yet exist.
    mkdir -p "$INIMG/$FOLDER";
    #"find $INIMG/* -maxdepth 0 -type f |" gets a list of all the files in our input directory (but not subdirectories) and passes that on to the next argument.
    #"head -n $FOLDERSIZE |" gets the first "$FOLDERSIZE" number of files in our directory and passes that on to the next argument.
    #"xargs -i" takes the input and passes it to the command "mv" while keeping file names with spaces as a single string.
    #'"{}"' lets the command mv handle multiple inputs and filenames with spaces.
    #"mv" will move the input files to the specified directory ("$INIMG/$FOLDER"). This will allow us to run indenpendent subprocesses on each folder.
    find $INIMG/* -maxdepth 0 -type f | head -n $FOLDERSIZE | xargs -i mv "{}" "$INIMG/$FOLDER"
done

#This "for loop" will go from 1 to the number of tasks and create a subprocess to analyze each subfolder created in the previous step.
for FOLDER in `seq 1 $NTASKS`; do
    (
        #Sets path to subfolder with files.
        IMGDIR="$INIMG/$FOLDER"
        #Creates a subprocess with 1 node (-n 1), 1 cpu (-c1 ), and 4G memory (--mem-per-cpu=4gb).
        #"--export=ALL" passes environmental variables (such as JOBID and output path) to subprocess.
        #"--export=SUBDIR=$IMGDIR" passes the variable "$IMGDIR" to the subprocess as a variable named "SUBDIR".
        #Path to script to run. This is a script that sets up a python environment and runs "stardist_v2.py" on each file in the given subdirectory.
        #You will need to install stardist to your user directory before running this pipeline. (see CHPC_Image_Analysis readme)
        srun -n 1 -c 1 --mem-per-cpu=4gb --export=ALL,SUBDIR=$IMGDIR /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/slurm/parallel_stardist.sh
    #"&" says to create a subprocess to run in parallel (in this case, each iteration of the for loop). This does not check how many tasks are available. 
    #If you create more subprocesses than tasks available, everything will slow down (throttle) signficantly. 
    #Setting the maximum iteration of the for loop to the number of available tasks (which is how this for loop is setup) should prevent more subprocesses being created than available tasks.
    )  &
done

#"wait" waits until all previous tasks are reported as finished.
wait
#Check that segmentation was successful.
echo "Finished Segmentation"

#This gets all files in the given directory and 1 level of subfolders (-maxdepth 1) and moves them to the $INIMG folder. 
#Cellprofiler sometimes has errors in handling images in subfolders, and this prevents that issue from occuring.
find $INIMG/* -maxdepth 1 -type f | xargs -i mv "{}" $INIMG

#This finds the number of files in input directory.
LENGTH=($(find $INIMG/* -maxdepth 0 -type f | wc -l))
#Check number of files in input directory.
echo $LENGTH" LENGTH"

#There are four images (Hoechst, EdU, DDX4, stardist segmentation) in each image set in the cellprofiler pipeline.
#This finds how many image sets are in the input directory.
SETS=$(($LENGTH/4))
#This finds how many image sets can be assigned to each available task. (+1 because default behavior is to round down)
TASKSIZE=$(($SETS/$NTASKS+1))
#Check task size
echo $TASKSIZE" TASKSIZE"
#This creates an array of the start and stop image set number to be assigned to each task.
#"($())" returns the output of the internal command. 
#"awk" is its own processing language thats good with data and stuff that can be called using the command "awk"
#"-v SETS="$SETS"" passes the named variable to awk. There needs to be a new "-v" for each variable that is being passed to awk.
#"BEGIN" might not be necassary. I don't want to test it, but it tells to do these arguments first before other arguments. Common to use with awk.
#'{}' incloses the command to be run with awk.
#"e=SIzE-1" sets the interval between the start and stop image set number for each task.
#"m=SETS" sets the maximum value for the array. The array will end at the total number of image sets.
#"for(i=1;i<=m;i+=SIZE)" sets up the conditions for each iteration of the for loop. 
#"i=1" sets the starting point of the first iteration of the for loop at 1.
#"i<=m" says to keep iterating through the for loop so long as "i" is less than or equal to "m" (the total number of image sets).
#"i+=SIZE" says to increase "i" by SIZE after every iteration of the for loop. This allows for each point in the array to be spaced according to how many image sets to assign each task.
#"{k=m-i;if(k<SIZE){e=k}}" checks if the difference between the start of the iteration (i) and the total number of image sets (m) is less than the interval (number of image sets for each tasks).
#If the difference is less than the interval, the stop of the iteration is set to the total number of image sets. This prevents the array from going beyond the number of available image sets.
#This will prevent cellprofiler from throwing an error for trying to analyze image sets that do not exist.
#"print i, i+e" will add the values i (the starting image set for a given task) and i+e (the ending image set for a given task) to the array.
MYARRAY=($(awk -v SETS="$SETS" -v SIZE="$TASKSIZE" 'BEGIN{e=SIZE-1;m=SETS;for(i=1;i<=m;i+=SIZE){k=m-i;if(k<SIZE){e=k};print i, i+e}}'))
#This will return the second element of the array (should be equal to TASKSIZE).
#"[1]" indicates to get the second element of the array. Linux is zero indexed, so zero is the first element of an index.
#"{}" is need around the name of the array to indicate it is an array
echo "${MYARRAY[1]}"" START_ARRAY"
#This will return the very last element of the array (should always be equal to SETS)
echo "${MYARRAY[-1]}"" END_ARRAY"

#Load module that has everything for running cellprofiler
module load cellprofiler

#If output directory doesn't exist, create output directory.
#"-d" checks if a directory exist. "!" says to return true if input is false
if [ ! -d "$OUTXL" ]; then
  mkdir "$OUTXL"
fi


#This for loop will go through every odd element of MYARRAY
#"ODD=1" sets the start value for the for loop
#"ODD<${#MYARRAY[@]}" says to keep iterating through the for loop as long as "ODD" is less than or equal to the last element of MYARRAY. 
#"${#MYARRAY[@]" will return length of the array (versus "${MyARRAY[@]}" which will return all the elements)
#"ODD+=2" increases "ODD" by 2 every iteration of the for loop.
for ((ODD=1; ODD<${#MYARRAY[@]}; ODD+=2 )); do
    (
        #This creates a unique output folder.
        OUTPUT="${OUTXL}/$ODD"
        mkdir "$OUTPUT"
        #Run cellprofiler
        #"-c" flag that tells cellprofiler to run headlessly (otherwise it will try to open the cellprofiler grapical user interface).
        #"-r" flag that tells cellprofiler to run in batch mode using the supplied pipeline.
        #"-p "$CPPIPE"" gives the path to the pipeline that cellprofiler will use.
        #"-i "$INIMG"" sets the path to the input images
        #"-o "$OUTPUT"" sets the path for the output (each parallel process of cellprofiler will have a unique output folder to prevent output from getting overwritten).
        #"-f "${MYARRAY[$ODD-1]}"" gives the first image set to be used by this instance of cellprofiler (this is zero indexed, so 0 is the very first image).
        #"-l "${MYARRAY[$ODD]}"" give the last image set to be used by this instance of cellprofiler.
        cellprofiler -c -r -p "$CPPIPE" -i "$INIMG" -o "$OUTPUT" -f "${MYARRAY[$ODD-1]}" -l "${MYARRAY[$ODD]}"
    #"&" to create a subprocess for each iteration of the for loop that are running in parallel.
    #Thankfully, cellprofiler is set up to handle python's GIL without additional effort on our part.
    #MYARRAY was set up based on the number of available tasks so this should not generate more parallel processes than available tasks. 
    #There is not another check on this, so it is possible there a situation I missed where this can generate more processes than available tasks which will overwhelm the system (just a note in case there are issues with extremely long run times). 
    )  &
done

#wait until all the cellprofiler processes are finished running. 
wait

#Unload cellprofiler module (not strictly necessary)
module unload cellprofiler

#Check that cellprofiler has finished running
echo "Finished CellProfiler"

#Create output folder for merged counts (this will be counts for all the images across all instances of cellprofiler that was run).
OUTDIR="${OUTXL}/counts"
if [ ! -d "$OUTDIR" ]; then
  mkdir "$OUTDIR"
fi

#Check path to output directory (this is the output that will actually be uploaded to google drive).
echo "$OUTDIR"

#Load module for R. (The base R module has all of the packages that are necessary for this pipeline)
module load R

#Run R script.
#This script will take the output from all the instances of cellprofiler (potentially as many as 64) and merge them into a single output (saved as a cvs).
#This script will then take the merged output and format the data by plate. It will save four excel files for each unique plate name in the data set.
#"Rscript" lets the machine know that it is being given a file that should be run in R (this could also be done with a shebang).
#"--args "$OUTXL"" passes the output directory variable to the R environment.
Rscript /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/R/format_data_2.R --args "$OUTXL"

#Check that the pipeline has finished
echo "Finished Analysis"
