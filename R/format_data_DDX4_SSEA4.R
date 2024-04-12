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
image.data <- df
#Get time to use as unique file name
time <- as.character(Sys.time())
#Remove spaces and special characters from time
time <- gsub(" ", "_", time)
time <- gsub(":", "-", time)
#Save data frame with raw values from each file.
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_SSEA4_all_images.csv"), row.names = FALSE)

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
Per_RelationshipsView <- df
#Get time to use as unique file name
time <- as.character(Sys.time())
#Remove spaces and special characters from time
time <- gsub(" ", "_", time)
time <- gsub(":", "-", time)
#Save data frame with raw values from each file.
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_SSEA4_object_relationships.csv"), row.names = FALSE)

#Get file names for all files in the folder (including subfolders) indicated by "path" that are the file type indicated by "pattern".
#This pattern gets the files with object relationships.
filenames <- list.files(path=file_path, pattern = "*_Filterednuclei.csv", full.names=TRUE, recursive = TRUE)
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
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_SSEA4_nuclei.csv"), row.names = FALSE)

#Get file names for all files in the folder (including subfolders) indicated by "path" that are the file type indicated by "pattern".
#This pattern gets the files with object relationships.
filenames <- list.files(path=file_path, pattern = "*_Cytoplasm.csv", full.names=TRUE, recursive = TRUE)
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
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_SSEA4_cytoplasm.csv"), row.names = FALSE)

#Get file names for all files in the folder (including subfolders) indicated by "path" that are the file type indicated by "pattern".
#This pattern gets the files with object relationships.
filenames <- list.files(path=file_path, pattern = "*_IdentifySecondaryObjects.csv", full.names=TRUE, recursive = TRUE)
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
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_SSEA4_secondaryobjects.csv"), row.names = FALSE)

#Load packages
library(openxlsx)
#Subset relevant columns
somatic <- image.data[c("Metadata_Plate","Metadata_Well","Count_Filterednuclei")]
cyto <- image.data[c("Metadata_Plate","Metadata_Well","Count_cytoDDX4")]
double <- image.data[c("Metadata_Plate","Metadata_Well","Count_cytoDDX4_SSEA4")]  
#Reorder data (just in case)
#Order by well
somatic <- somatic[order(somatic[,"Metadata_Well"]),]
cyto <- cyto[order(cyto[,"Metadata_Well"]),]
double <- double[order(double[,"Metadata_Well"]),]
#Order by plate
somatic <- somatic[order(somatic[,"Metadata_Plate"]),]
cyto <- cyto[order(cyto[,"Metadata_Plate"]),]
double <- double[order(double[,"Metadata_Plate"]),]
#Calculate somatic cell number
somatic[,4] <- somatic[,3]-cyto[,3]
#Save per image data
df <- cbind(somatic[c(1,2,4)],cyto[,3],double[,3],(double[,3]/cyto[,3]*100))
colnames(df) <- c("Plate", "Well","Somatic","cytoDDX4","DDX4/SSEA4","Percent_Double")
df[is.na(df["Percent_Double"]),"Percent_Double"] <- 0
#Subset out plates
u.Plate <- as.data.frame(unique(df["Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df["Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]
#Save data sets
for (i in 1:length(per_plate)){
  if (!file.exists(paste0(file_path, "/counts/", u.Plate[i,1]))){
    dir.create(paste0(file_path, "/counts/", u.Plate[i,1]))
  }
  file <- paste0(file_path,"/counts/", u.Plate[i,1],"/",u.Plate[i,1],"_per_image_DDX4SSEA4v7_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx(save,file)
}
#Create functions
#Function for summing image counts per well
sum_well <- function(a="df", b = "Metadata_Well", c = "Count_TotalCells"){
  u.Well <- unique(a[b])
  per_well <- as.data.frame(c(1))
  if (length(u.Well[,1]) > 1){
    for (i in 1:length(u.Well[,1])){
      per_well[i,1] <- sum(a[a[b]==u.Well[i,1],c])  
    } } else {
      per_well[1,1] <- sum(a[a[b]==u.Well[1,1],c])
    }
  return(per_well)
}
#Apply function by plate in a data set
apply_plate <- function(a="df", b="Metadata_Plate",d="Function", c="Well", e="Column Names", f="column"){
  u.Plate <- as.data.frame((unique(a[b])))
  temp <- as.data.frame(cbind(0,0,0))
  colnames(temp) <- e
  per_plate <- 0
  if (length(u.Plate[,1]>1)){
    for (i in 1:length(u.Plate[,1])){
      per_plate <- a[a[b]==u.Plate[i,1],]
      per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate, c=f))
      colnames(per_plate) <- e
      temp <- rbind(temp, per_plate)
    }
  } else{
    per_plate <- a[a[b]==u.Plate[1,1],]
    per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate,c=f))
    colnames(per_plate) <- e
    temp <- rbind(temp, per_plate)
  }
  temp <- temp[2:length(temp[,1]),]
  return(temp)
}
#Sum somatic cells per well per plate
somatic <- apply_plate(a=somatic,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_TotalCells"), f = "Count_Filterednuclei")
#Sum cytoDD4+ cells per well per plate
cyto <- apply_plate(a=cyto,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_cyto"), f = "Count_cytoDDX4")
#Sum double positive cells per well per plate
double <- apply_plate(a=double,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_double"), f = "Count_cytoDDX4_SSEA4")  
#Calculate somatic cells per well
somatic["Somatic_Count"] <- somatic$Count_TotalCells - cyto$Count_cytoDDX4
#Combine data sets and resolve NaN
df <- cbind(somatic[c(1,2,4)], cyto[,3],double[,3],(double[,3]/cyto[,3]*100))
colnames(df) <- c("Plate", "Well","Somatic","cytoDDX4","DDX4/SSEA4","Percent_Double")
df[is.na(df["Percent_Double"]),"Percent_Double"] <- 0
#Subset out plates
u.Plate <- as.data.frame(unique(df["Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df["Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]
counts_df <- df
counts_per_plate <- per_plate
#Save data sets
for (i in 1:length(per_plate)){
  if (!file.exists(paste0(file_path, "/counts/", u.Plate[i,1]))){
    dir.create(paste0(file_path, "/counts/", u.Plate[i,1]))
  }
  file <- paste0(file_path,"/counts/",u.Plate[i,1], "/",u.Plate[i,1],"_per_well_DDX4SSEA4v7_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx(save,file)
}