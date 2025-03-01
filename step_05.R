## A script that performs PCA on a normalized count matrix.

args = base::commandArgs(trailingOnly = TRUE)
print(args)

path2_json_file = args[1]

# **********************************************************************
## Load in the necessary libraries:
print("*** Loading libraries ***")
options(stringsAsFactors = FALSE)
options(bitmapType='quartz')
library(jsonlite)
library(ggplot2)
library(dplyr)
library(factoextra)
library(readr)
library(stringr)

#### Read in input files ###
# JSON input file with SD and AVG thresholds
print("*** Reading the input files ***")
json = read_json(path2_json_file)
parent_folder = json$folders$output_folder
experiment = json$experiment_name
path2_design = file.path(parent_folder, "results", paste0(experiment, "_design.txt"))
path2_count = file.path(parent_folder, "results", paste0(experiment , "_Z_threshold.txt"))

### Read in the filtered count matrix and the design file ###
filt_count = as.matrix(read.table(path2_count, sep = "\t", header = TRUE, row.names = 1, check.names=FALSE))
design = read.table(path2_design, sep = "\t", header = TRUE, row.names = 1)


# **************** Start of the program **********************
print("*** Start of the program ***")

### Check that the count matrix has been normalized ###
mn = apply(filt_count, 1, mean)
stdev = apply(filt_count, 1, sd)

if (mean(mn) < -(0.0001) | mean(mn) > 0.0001){
  print("The count matrix is not normalized. Mean of means != 0")
  stop()
}

if (mean(stdev) != 1){
  print("Not all standard deviations of the normalized matrix == 1")
}

### Perform PCA on the samples ###

print("***Performing PCA. This can take a while.***")
cols = ncol(filt_count)
pca = prcomp(t(filt_count), scale = TRUE)
# for scree plot generation:
pcavar <- pca$sdev^2
per.pcavar = round(pcavar/sum(pcavar)*100,1)

### Generate a loading scores table ##
loadings = pca$rotation

### Save the loadings for each PC into a file ###
output_loadings = file.path(parent_folder, "results", paste0(experiment, "_pca_loading_scores.txt"))
write.table(loadings, file = output_loadings, sep = '\t',col.names=NA,row.names=TRUE,quote=FALSE)

# Save the eigenvalues
pca_eigenvalue=factoextra::get_eig(pca)
output_eigenvalues = file.path(parent_folder, "results", paste0(experiment, "_pca_eigenvalues.txt"))
write.table(pca_eigenvalue, file = output_eigenvalues, sep = '\t',col.names=NA,row.names=TRUE,quote=FALSE)

# Save the pca object
output_pca = file.path(parent_folder, "results", paste0(experiment, "_pca_object.rds"))
write_rds(pca, output_pca)

# Extract the design equation variables
for (i in 1:(length(json$design_variables))){
  if (str_length(json$design_variables[[i]]) > 0){
    nam <- paste0("formula", i)
    assign(nam, json$design_variables[[i]])
    last_number = i
  }else if (str_length(json$design_variables[[i]]) <= 0){
    print(" ")
  }
} 

# Figures for the report

figure6 = file.path(parent_folder, "figures", paste0(experiment, "_scree_plot.png"))
png(figure6)
factoextra::fviz_eig(pca) # another way to visualize percentage contribution
dev.off()

# figure of PC1 vs PC2
# Format the data the way ggplot2 likes it:
pca_data <- matrix(ncol= ncol(pca$x)+1, nrow = nrow(pca$x))
pca_data[,1] = rownames(pca$x)
for (columns in 1:ncol(pca$x)){
  pca_data[,columns+1] = pca$x[,columns]
}

### Save all PC to a file (not just significant/meaningful)
output_full_pca = file.path(parent_folder, "results", paste0(experiment, "_pca_scores.txt"))
write.table(pca$x, file = output_full_pca, sep = '\t',col.names=NA,row.names=TRUE,quote=FALSE)

pca_data = as.data.frame(pca_data)
names(pca_data)[1] = "Sample"
for (col_names in 2:ncol(pca_data)){
  names(pca_data)[col_names] = paste0("PC", col_names-1)
}

design$Sample = row.names(design)
pca_data = dplyr::left_join(pca_data, design, by = "Sample")

# Convert the PC columns to numeric in the data set
for (column in 1:ncol(pca_data)){
  colname = colnames(pca_data[column])
  if (sum(base::grep("PC", colname))>0){
    pca_data[,column] = as.numeric(pca_data[,column])
  }
}

# If loop to make a PC plot depending on whether we have 1 or 2 design formulas:

if (exists("formula2")){
  figure7 = file.path(parent_folder, "figures", paste0(experiment, "PC1_PC2.png"))
  png(figure7)
  print(ggplot(data = pca_data, aes_string(x = "PC1", y = "PC2",
                                     label = formula1,
                                     color = formula2)) +
    geom_text() +
    xlab(paste("PC1: ", per.pcavar[1], "%", sep = ""))+
    ylab(paste("PC2: ", per.pcavar[2], "%", sep = ""))+
    theme_bw() +
    ggtitle(paste("PC1 vs PC2", "| Experiment: ", experiment))+
    theme(axis.text.x=element_blank(),
          axis.text.y=element_blank()))
  dev.off()
} else if (!exists("formula2") & exists("formula1")){
  figure7 = file.path(parent_folder, "figures", paste0(experiment, "PC1_PC2.png"))
  png(figure7)
  print(ggplot(data = pca_data, aes_string(x = "PC1", y = "PC2",
                                     label = formula1,
                                     color = formula1)) +
    geom_text() +
    xlab(paste("PC1: ", per.pcavar[1], "%", sep = ""))+
    ylab(paste("PC2: ", per.pcavar[2], "%", sep = ""))+
    theme_bw() +
    ggtitle(paste("PC1 vs PC2", "| Experiment: ", experiment))+
    theme(axis.text.x=element_blank(),
          axis.text.y=element_blank()))
  dev.off()
} else if (!exists("formula2") & !exists("formula1")){
  print("--- Error: Missing design variable. Please check the JSON input file ***")
} else if (exists("formula2") & !exists("formula1")){
  print("--- Error: please change the JSON file. If there is only one design variable, save it under design1 ***")
} else {
  print("--- Error: there is a problem with the design formula. Please check the JSON input file ***")
}


# Same loop, but for PC2 and PC3
if (exists("formula2")){
  figure8 = file.path(parent_folder, "figures", paste0(experiment, "PC2_PC3.png"))
  png(figure8)
  print(ggplot(data = pca_data, aes_string(x = "PC2", y = "PC3", label = formula1,
                              color = formula2)) +
    geom_text() +
    xlab(paste("PC2: ", per.pcavar[2], "%", sep = ""))+
    ylab(paste("PC3: ", per.pcavar[3], "%", sep = ""))+
    theme_bw() +
    ggtitle(paste("PC2 vs PC3", "| Experiment: ", experiment))+
    theme(axis.text.x=element_blank(),
          axis.text.y=element_blank()))
  dev.off()
  
}else if (!exists("formula2") & exists("formula1")){
  figure8 = file.path(parent_folder, "figures", paste0(experiment, "PC2_PC3.png"))
  png(figure8)
  print(ggplot(data = pca_data, aes_string(x = "PC2", y = "PC3", label = formula1,
                              color = formula1)) +
    geom_text() +
    xlab(paste("PC2: ", per.pcavar[2], "%", sep = ""))+
    ylab(paste("PC3: ", per.pcavar[3], "%", sep = ""))+
    theme_bw() +
    ggtitle(paste("PC2 vs PC3", "| Experiment: ", experiment))+
    theme(axis.text.x=element_blank(),
          axis.text.y=element_blank()))
  dev.off()
  
} else if (!exists("formula2") & !exists("formula1")){
  print("--- Error: Missing design variable. Please check the JSON input file ***")
} else if (exists("formula2") & !exists("formula1")){
  print("--- Error: please change the JSON file. If there is only one design variable, save it under design1 ***")
} else {
  print("--- Error: there is a problem with the design formula. Please check the JSON input file ***")
}

#Same loop, but for facet plot of PC1 (added 7/18/21)
if (exists("formula2")){
  PC1_facetplot = file.path(parent_folder, "figures", paste0(experiment, "PC1_facetplot.png"))
  png(PC1_facetplot)
  print(ggplot(data = pca_data, aes_string(x = "Sample", y = "PC1", fill=formula2)) +
    geom_bar(stat="identity", position=position_dodge())+
    facet_grid(. ~ pca_data[,formula1], scales='free')+
    labs(y="Sample Loading")+
    theme_bw() +
    ggtitle(paste("PC1: ", per.pcavar[1], "% | Experiment: ", experiment,sep = ""))+
    theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()))
  dev.off()
  
}else if (!exists("formula2") & exists("formula1")){
  PC1_facetplot = file.path(parent_folder, "figures", paste0(experiment, "PC1_facetplot.png"))
  png(PC1_facetplot)
  print(ggplot(data = pca_data, aes_string(x = "Sample", y = "PC1", fill=formula1)) +
    geom_bar(stat="identity", position=position_dodge())+
    theme_bw() +
    theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+ 
    ggtitle(paste("PC1: ", per.pcavar[1], "% | Experiment: ", experiment,sep = "")))
  dev.off()
  
} else if (!exists("formula2") & !exists("formula1")){
  print("--- Error: Missing design variable. Please check the JSON input file ***")
} else if (exists("formula2") & !exists("formula1")){
  print("--- Error: please change the JSON file. If there is only one design variable, save it under design1 ***")
} else {
  print("--- Error: there is a problem with the design formula. Please check the JSON input file ***")
}

#Same loop, but for facet plot of PC2 (added 7/18/21)
if (exists("formula2")){
  PC2_facetplot = file.path(parent_folder, "figures", paste0(experiment, "PC2_facetplot.png"))
  png(PC2_facetplot)
  print(ggplot(data = pca_data, aes_string(x = "Sample", y = "PC2", fill=formula2)) +
    geom_bar(stat="identity", position=position_dodge())+
    facet_grid(. ~ pca_data[,formula1], scales='free')+
    labs(y="Sample Loading")+
    theme_bw() +
    ggtitle(paste("PC2: ", per.pcavar[2], "% | Experiment: ", experiment,sep = ""))+
    theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()))
  dev.off()
  
}else if (!exists("formula2") & exists("formula1")){
  PC2_facetplot = file.path(parent_folder, "figures", paste0(experiment, "PC2_facetplot.png"))
  png(PC2_facetplot)
  print(ggplot(data = pca_data, aes_string(x = "Sample", y = "PC2", fill=formula1)) +
    geom_bar(stat="identity", position=position_dodge())+
    theme_bw() +
    theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+ 
    ggtitle(paste("PC2: ", per.pcavar[2], "% | Experiment: ", experiment,sep = "")))
  dev.off()
  
} else if (!exists("formula2") & !exists("formula1")){
  print("--- Error: Missing design variable. Please check the JSON input file ***")
} else if (exists("formula2") & !exists("formula1")){
  print("--- Error: please change the JSON file. If there is only one design variable, save it under design1 ***")
} else {
  print("--- Error: there is a problem with the design formula. Please check the JSON input file ***")
}

#Same loop, but for facet plot of PC3 (added 7/18/21)
if (exists("formula2")){
  PC3_facetplot = file.path(parent_folder, "figures", paste0(experiment, "PC3_facetplot.png"))
  png(PC3_facetplot)
  print(ggplot(data = pca_data, aes_string(x = "Sample", y = "PC3", fill=formula2)) +
    geom_bar(stat="identity", position=position_dodge())+
    facet_grid(. ~ pca_data[,formula1], scales='free')+
    labs(y="Sample Loading")+
    theme_bw() +
    ggtitle(paste("PC3: ", per.pcavar[3], "% | Experiment: ", experiment,sep = ""))+
    theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()))
  dev.off()
  
}else if (!exists("formula2") & exists("formula1")){
  PC3_facetplot = file.path(parent_folder, "figures", paste0(experiment, "PC3_facetplot.png"))
  png(PC3_facetplot)
  print(ggplot(data = pca_data, aes_string(x = "Sample", y = "PC3", fill=formula1)) +
    geom_bar(stat="identity", position=position_dodge())+
    theme_bw() +
    theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+ 
    ggtitle(paste("PC3: ", per.pcavar[3], "% | Experiment: ", experiment,sep = "")))
  dev.off()
  
} else if (!exists("formula2") & !exists("formula1")){
  print("--- Error: Missing design variable. Please check the JSON input file ***")
} else if (exists("formula2") & !exists("formula1")){
  print("--- Error: please change the JSON file. If there is only one design variable, save it under design1 ***")
} else {
  print("--- Error: there is a problem with the design formula. Please check the JSON input file ***")
}


# Updating the json copy
path_2_json_copy = file.path(parent_folder, "results", paste0(experiment, "_json_copy.json"))
json_copy <- read_json(path_2_json_copy)
json_copy$path_2_results$all_loading_scores = as.character(output_loadings)
json_copy$path_2_results$eigenvalues = as.character(output_eigenvalues)
json_copy$path_2_results$pca_object = as.character(output_pca)
json_copy$figures$scree_plot = as.character(figure6)
json_copy$figures$PC1_PC2 = as.character(figure7)
json_copy$figures$PC2_PC3 = as.character(figure8)
#lines below added 7/18/21
json_copy$figures$PC1_facetplot = as.character(PC1_facetplot)
json_copy$figures$PC2_facetplot = as.character(PC2_facetplot)
json_copy$figures$PC3_facetplot = as.character(PC3_facetplot)
write_json(json_copy, path_2_json_copy, auto_unbox = TRUE)

