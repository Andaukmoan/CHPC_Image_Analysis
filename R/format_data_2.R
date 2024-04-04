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
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_EdU_all_images.csv"), row.names = FALSE)

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
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_EdU_object_relationships.csv"), row.names = FALSE)

#Get file names for all files in the folder (including subfolders) indicated by "path" that are the file type indicated by "pattern".
#This pattern gets the files with object relationships.
filenames <- list.files(path=file_path, pattern = "*_Filtered_nuclei.csv", full.names=TRUE, recursive = TRUE)
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
write.csv(df, file=paste0(file_path,"/counts/",time,"_DDX4_EdU_per_object.csv"), row.names = FALSE)


#Load packages
library(openxlsx)
#Subset relevant columns
somatic <- image.data[c("Metadata_Plate","Metadata_Well","Count_Filtered_nuclei")]
txrd <- image.data[c("Metadata_Plate","Metadata_Well","Count_Combined_DDX4")]
somatic_edu <- image.data[c("Metadata_Plate","Metadata_Well","Count_Filtered_somatics")]
cyto <- image.data[c("Metadata_Plate","Metadata_Well","Count_CombinedObjects")]
double <- image.data[c("Metadata_Plate","Metadata_Well","Count_cytoDDX4_EdU")]  
#Reorder data (just in case)
#Order by well
somatic <- somatic[order(somatic[,"Metadata_Well"]),]
txrd <- txrd[order(txrd[,"Metadata_Well"]),]
somatic_edu <- somatic_edu[order(somatic_edu[,"Metadata_Well"]),]
cyto <- cyto[order(cyto[,"Metadata_Well"]),]
double <- double[order(double[,"Metadata_Well"]),]
#Order by plate
somatic <- somatic[order(somatic[,"Metadata_Plate"]),]
txrd <- txrd[order(txrd[,"Metadata_Plate"]),]
somatic_edu <- somatic_edu[order(somatic_edu[,"Metadata_Plate"]),]
cyto <- cyto[order(cyto[,"Metadata_Plate"]),]
double <- double[order(double[,"Metadata_Plate"]),]
#Calculate somatic cell number
somatic[,4] <- somatic[,3]-txrd[,3]
somatic[,4] <- somatic[,4]-somatic_edu[,3]
#Calculate dead DDX4 per well
txrd["Dead_DDX4"] <- txrd[,3] - cyto[,3]
#Save per image data
df <- cbind(somatic[c(1,2,4)],somatic_edu[,3], (txrd[,3]-cyto[,3]),cyto[,3],double[,3],(double[,3]/cyto[,3]*100))
colnames(df) <- c("Plate", "Well","Somatic", "Somatic/EdU","Dead_DDX4","cytoDDX4","DDX4/EdU","Percent_Double")
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
  file <- paste0(file_path,"/counts/",u.Plate[i,1],"_per_image_DDX4EdUv7_quantification.xlsx")
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
somatic <- apply_plate(a=somatic,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_TotalCells"), f = "Count_Filtered_nuclei")
#Sum Txrd+ cells per well per plate
txrd <- apply_plate(a=txrd,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_txrd"), f = "Count_Combined_DDX4")
#Sum Txrd-/EdU+ cells per well per plate
somatic_edu <- apply_plate(a=somatic_edu,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_edu"), f = "Count_Filtered_somatics")
#Sum cytoDD4+ cells per well per plate
cyto <- apply_plate(a=cyto,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_cyto"), f = "Count_CombinedObjects")
#Sum double positive cells per well per plate
double <- apply_plate(a=double,b="Metadata_Plate",d=sum_well, c="Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_double"), f = "Count_cytoDDX4_EdU")  
#Calculate somatic cells per well
somatic["Somatic_Count"] <- somatic$Count_TotalCells - txrd$Count_txrd
somatic["Somatic_Count"] <- somatic$Somatic_Count - somatic_edu$Count_edu
#Calculate dead DDX4 per well
txrd["Dead_DDX4"] <- txrd$Count_txrd - cyto$Count_cyto
#Combine data sets and resolve NaN
df <- cbind(somatic[c(1,2,4)], somatic_edu$Count_edu, (txrd[,3]-cyto[,3]),cyto[,3],double[,3],(double[,3]/cyto[,3]*100))
colnames(df) <- c("Plate", "Well","Somatic", "Somatic/EdU","Dead_DDX4","cytoDDX4","DDX4/EdU","Percent_Double")
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
  file <- paste0(file_path,"/counts/",u.Plate[i,1],"_DDX4EdUv7_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx(save,file)
}

#This code is really gross. I am so sorry I did not document it better. 
#I could not find a good way to do this, so I took a very round about way that is long and clunky and gives a ton of warning messages because I coerce the living daylights out of the data.
#Get Neighbor relationships
Neighbors <- Per_RelationshipsView[Per_RelationshipsView$Relationship == "Neighbors",]
#Create data frame to store output
output <- data.frame()
#Get list of unique images
u.image <- sort(unique(Neighbors$First.Image.Number))
#Loop through each unique image
for (i in 1:length(u.image)){
#Subset values for the given image
image_Neighbors <- Neighbors[Neighbors$First.Image.Number==u.image[i],]
#Remove duplicate relationships. Not strictly necessary yet but reduces number of objects
u.number <- unique(image_Neighbors$First.Object.Number)
u.Neighbors <- data.frame()
for (i in 1:length(u.number)){
  if (!u.number[i] %in% u.Neighbors$First.Object.Number){
  temp <- image_Neighbors[u.number[i] == image_Neighbors$Second.Object.Number,]  
  u.Neighbors <- rbind(u.Neighbors,temp)} else {
  temp <- image_Neighbors[u.number[i] == image_Neighbors$Second.Object.Number,]
  number <- u.number[i]
  u.temp <- unique(temp$First.Object.Number)
  for (i in 1:length(u.temp)){
    if (u.temp[i] %in% u.Neighbors$First.Object.Number & !u.temp[i] %in% u.Neighbors[u.Neighbors$First.Object.Number == number, "Second.Object.Number"]){
      temp_2 <- temp[u.temp[i] == temp$First.Object.Number,]
      u.Neighbors <- rbind(u.Neighbors,temp_2)      
    }}}}
#Create list of relationships
u.Neighbors_list <- list()
for (i in 1:length(u.Neighbors$First.Object.Number)){
  temp <- c(u.Neighbors$First.Object.Number[i], u.Neighbors$Second.Object.Number[i])
  u.Neighbors_list[[length(u.Neighbors_list)+1]] <- temp
}
#Find connections between objects
u.Neighbors_group <- list()
for (i in 1:length(u.Neighbors_list)){
  temp <- u.Neighbors_list[[i]]
  for (j in 1:length(u.Neighbors_list)){
    if (any(u.Neighbors_list[[i]] %in% u.Neighbors_list[[j]])){
      temp <- union(temp, u.Neighbors_list[[j]])
      }    
  }
  u.Neighbors_group[[length(u.Neighbors_group)+1]] <- temp
}
#Find connections between objects a second time
u.Neighbors_list <- list()
for (i in 1:length(u.Neighbors_group)){
  temp <- u.Neighbors_group[[i]]
  for (j in 1:length(u.Neighbors_group)){
    if (any(u.Neighbors_group[[i]] %in% u.Neighbors_group[[j]])){
      temp <- union(temp, u.Neighbors_group[[j]])
      }    
  }
  u.Neighbors_list[[length(u.Neighbors_list)+1]] <- temp
}
#Find connections between objects a third time
#This allows us to group objects together that are within 14 connections of each other. I am assuming we won't have more than 14 connections between objects.
#Check colony size. If any colonies are 16+, then we need to revisit this assumption.
temp_2 <- list()
for (i in 1:length(u.Neighbors_list)){
  temp <- u.Neighbors_list[[i]]
  for (j in 1:length(u.Neighbors_list)){
    if (any(u.Neighbors_list[[i]] %in% u.Neighbors_list[[j]])){
      temp <- union(temp, u.Neighbors_list[[j]])
      }    
  }
  temp_2[[length(temp_2)+1]] <- temp
}
u.Neighbors_list <- temp_2
#Remove duplicates
u.Neighbors_group <- list(u.Neighbors_list[[1]])
for (i in 1:length(u.Neighbors_list)){
  temp <- list()
  for (j in 1:length(u.Neighbors_group)){
       temp <- c(temp, any(u.Neighbors_list[[i]] %in% u.Neighbors_group[[j]]))
  }
  if (!any(temp)){
   u.Neighbors_group[[length(u.Neighbors_group)+1]] <- u.Neighbors_list[[i]] 
  }
}
#Get number of unique colonies
colony <- c(1:length(u.Neighbors_group))
#Get colony size
colony_size <- unlist(lapply(u.Neighbors_group, length))
#Create data frame with unique colonies, colony size, and image number
colonies <- cbind(unique(image_Neighbors$First.Image.Number), colony, colony_size)
colnames(colonies) <- c("ImageNumber","colony","colony_size")
#Add data to output data frame
output <- rbind(output,colonies)
}
#Add plate and well metadata columns
df <- cbind(0,0,output)
colnames(df) <- c("Metadata_Plate","Metadata_Well", colnames(output))
#Add plate and well values based on image number
for (i in 1:length(df[[1]])){
df[i,c("Metadata_Plate","Metadata_Well")] <- image.data[df[i,"ImageNumber"]==image.data[,"ImageNumber"], c("Metadata_Plate","Metadata_Well")]  
}
#Save data frame without missing images
sdf <- df
#Identify missing images.
missing <- image.data[!image.data[,"ImageNumber"] %in% df[,"ImageNumber"],"ImageNumber"]
if (length(missing) > 1){
  missing <- cbind(0,0,missing,0,0)
missing <- as.data.frame(missing)
colnames(missing) <- c("Metadata_Plate","Metadata_Well", colnames(output))
for (i in 1:length(missing[[1]])){
missing[i,c("Metadata_Plate","Metadata_Well")] <- image.data[missing[i,"ImageNumber"]==image.data[,"ImageNumber"], c("Metadata_Plate","Metadata_Well")]  
}
#Add missing images to df.
df <- rbind(df,missing)
} else {
  print("No missing images")
}
#Save raw data files per plate.
#Create list with a data frame for each plate.
u.Plate <- as.data.frame(unique(df["Metadata_Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df["Metadata_Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]
#Create data frame with file names based on plate names.
filename <- as.data.frame(sapply(u.Plate, paste0,"_raw_colony_data.xlsx"))
#Save each plate to a separate xlsx file.
lapply(1:length(per_plate), function(a) write.xlsx(per_plate[[a]], 
                                      file = paste0(file_path, "/counts/",filename[a,1]),
                                      row.names = FALSE))
#Subset data frame by colony size.
#sdf <- sdf[sdf["colony_size"]>2,]
#Create functions
#Sum number of colonies per well
sum_well <- function(a, b = "Metadata_Well", c = "colony"){
  u.Well <- unique(a[b])
  per_well <- as.data.frame(c(1))
  if (length(u.Well[,1]) > 1){
  for (i in 1:length(u.Well[,1])){
    per_well[i,1] <- sum(a[b]==u.Well[i,1])  
  } } else {
      per_well[1,1] <- sum(a[b]==u.Well[1,1])
    }
  return(per_well)
}
#Summary of colonies per well
summary_colony <- function(a, b = "Metadata_Well", c = "colony_size"){
  u.Well <- unique(a[b])
  per_well <- cbind(u.Well,0,0,0,0,0)
  if (length(u.Well[,1]) > 1){
  for (i in 1:length(u.Well[,1])){
    per_well[i,] <- t(data.frame(unclass(summary(a[a[b]==u.Well[i,1],c]))))
  
    } } else {
      per_well[1,] <- t(data.frame(unclass(summary(a[a[b]==u.Well[1,1],c]))))
    }
  return(per_well)
}
#Apply two functions by plate in a data set
apply_plate2 <- function(a="df", b="Plate",d="Function", c="Well", e="Column Names", f="Function"){
  u.Plate <- as.data.frame((unique(a[b])))
  temp <- as.data.frame(cbind(0,0,0,0,0,0,0,0,0))
  colnames(temp) <- e
  per_plate <- 0
  if (length(u.Plate[,1]>1)){
    for (i in 1:length(u.Plate[,1])){
      per_plate <- a[a[b]==u.Plate[i,1],]
      per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate), f(per_plate))
      colnames(per_plate) <- e
      temp <- rbind(temp, per_plate)
      }
  } else{
    per_plate <- a[a[b]==u.Plate[1,1],]
      per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate), f(per_plate))
      colnames(per_plate) <- e
      temp <- rbind(temp, per_plate)
  }
  temp <- temp[2:length(temp[,1]),]
  return(temp)
}
#Set column names
column_names <- c("Metadata_Plate","Metadata_Well", "Colony_Count","Colony_Min","Colony_1st_Q","Colony_Median","Colony_Mean","Colony_3rd_Q","Colony_Max")
#Combine images per well per plate using functions created in previous chunk
per_well <- apply_plate2(a=sdf, b="Metadata_Plate",c="Metadata_Well",d=sum_well, e=column_names, f=summary_colony)
#Add missing wells
if (length(missing) >1){
#Get missing wells
missing_well <- apply_plate2(a=missing, b="Metadata_Plate",c="Metadata_Well",d=sum_well, e=column_names, f=summary_colony)
#Set colony counts to zero
missing_well$Colony_Count <- 0
#Split data frame into list of data frames per plate
u.Plate <- as.data.frame(unique(per_well["Metadata_Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- per_well[per_well["Metadata_Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(per_well)
  }
names(per_plate) <- u.Plate[,1]
#Split missing well data frame
u.missing <- as.data.frame(unique(missing_well["Metadata_Plate"]))
per_plate_missing <- list(c(1))
if (length(u.missing[,1])>1){
  for (i in 1:length(u.missing[,1])){
    per_plate_missing[[i]] <- missing_well[missing_well["Metadata_Plate"]==u.missing[i,1],] 
  }} else {
    per_plate_missing <- list(missing_well)
  }
names(per_plate_missing) <- u.missing[,1]
#Loop through each plate
for (i in 1:length(u.missing[,1])){
#Get counts for each plate
df <- per_plate[[u.missing[i,1]]]
#Get potential missing wells for each plate
mdf <- per_plate_missing[[u.missing[i,1]]]
#Create temporary file of missing wells
temp <- mdf[!mdf$Metadata_Well %in% df$Metadata_Well,]
#If there are missing wells, add them to the data frame
if (length(temp[,1])>=1){
df <- rbind(df,temp)  
}
per_plate[[u.missing[i,1]]] <- df
}
}
#Create single data frame that contains all the information from each plate.
per_well <- data.frame()
if (length(per_plate) > 1){
 for (i in 1:length(per_plate)){
   per_well <- rbind(per_well, per_plate[[i]])
 } 
} else{
  per_well <- per_plate[[1]]
}
#Reorder data
#Order by well
per_well <- per_well[order(per_well[,"Metadata_Well"]),]
#Order by plate
per_well <- per_well[order(per_well[,"Metadata_Plate"]),]
#Save raw data files per plate
#Create list with a data frame for each plate
u.Plate <- as.data.frame(unique(per_well["Metadata_Plate"]))
plate_summary <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    plate_summary[[i]] <- per_well[per_well["Metadata_Plate"]==u.Plate[i,1],] 
  }} else {
    plate_summary <- list(per_well)
  }
#Create data frame with file names based on plate names
filename <- as.data.frame(sapply(u.Plate, paste0,"_colony_counts_per_well.xlsx"))
#Save each plate to a separate csv file.
for (i in 1:length(plate_summary)){
  write.xlsx(plate_summary[[i]], paste0(file_path,"/counts/",filename[i,1]))
}
