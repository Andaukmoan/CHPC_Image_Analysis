## This folder contains the functional scripts for our image analysis pipeline

## DDX4_EdU_batch.sh 

This is the functional script.

It can be modified to analyze new images types by changing CPPIPE to the location of the new pipeline. A new R script for formatting the data will also need to be generated replacing "format_data_2.R"

## DDX4_EdU_batch_full_annotation.sh 

This is an indepth annotation of the DDX4_EdU_batch.sh to help new users become familiar with the script.
	
This script will hopefully help in troubleshooting errors in the script and adapting the script to new image analysis pipelines.

## parallel_stardist.sh 

This script sets up the python environment for and then runs stardist_v2.py. 
	
This allows us to run stardist in parallel. Python by default has a Global Interpreter Lock that prevents multiple threads of python from executing at the same time. This allows us to get around that by creating a unique environment for each instance of python that we run in parallel. DDX4_EdU_batch.sh creates a parallel process that will run this script. This script is not fully functional on its own. If stardist needs to be updated (such as if the nuclear stain is in a different channel), this script (or a copy of it) will need to be updated with the path to the new stardist script (and any other changes to the environment).


