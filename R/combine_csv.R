#!/usr/bin/env Rscript

#Pass variable from bash to R
args <- commandArgs(trailingOnly =TRUE)
#Get file path (args[1]="--args")
file_path <- args[2]
#Get file names for all files in the folder (including subfolders) indicated by "path" that are the file type indicated by "pattern". This pattern 
#gets the files with per image counts.
filenames <- list.files(path=file_path, pattern = "*_Image.csv", full.names=TRUE, recursive = TRUE)
#Load all files as data frames in the list of data frames "ldf".
ldf <- lapply(filenames, read.csv)
#Create data frame to store all results in.
df <- ldf[[1]]
#Loop through each data frame in the list of data frames and add them to the end of the empty data frame.
for (i in 2:length(ldf)){
  df <- rbind(df, ldf[[i]])
}
#Reorder df by image number
df <- df[order(df[,"ImageNumber"]),]
#Get time to use as unique file name
time <- as.character(Sys.time())
#Remove spaces and special characters from time
time <- gsub(" ", "_", time)
time <- gsub(":", "-", time)
#Save data frame with raw values from each file.
write.csv(df, file=paste0(file_path,"/",time,"_DDX4_EdU_all_images.csv"), row.names = FALSE)

#Get file names for all files in the folder (including subfolders) indicated by "path" that are the file type indicated by "pattern".
#This pattern gets the files with object relationships.
filenames <- list.files(path=file_path, pattern = "*_relationship.csv", full.names=TRUE, recursive = TRUE)
#Load all files as data frames in the list of data frames "ldf".
ldf <- lapply(filenames, read.csv)
#Create data frame to store all results in.
df <- ldf[[1]]
#Loop through each data frame in the list of data frames and add them to the end of the empty data frame.
for (i in 2:length(ldf)){
  df <- rbind(df, ldf[[i]])  
}
#Get time to use as unique file name
time <- as.character(Sys.time())
#Remove spaces and special characters from time
time <- gsub(" ", "_", time)
time <- gsub(":", "-", time)
#Save data frame with raw values from each file.
write.csv(df, file=paste0(file_path,"/",time,"_DDX4_EdU_object_relationships.csv"), row.names = FALSE)

