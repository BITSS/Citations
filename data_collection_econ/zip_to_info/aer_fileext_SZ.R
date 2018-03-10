###
# The following adds to baiyue's zip_info.R file. The original produces the aer_data_attachment_info.csv
# I read in this CSV and modify it in the following ways:
#   include the DOIs, titles and URLS
#   include .f (fortram) files to be classified as code
#   include variable if txt file is a readme file
#   include variable if filename includes the word "data"
# -Simon Zhu 3/9/2018
###

getwd()
setwd('/Citations/data_collection_econ/zip_to_info')

library(tidyr)
library(dplyr)
library(rvest)

add_mat <- read.csv("C:/Users/snake/Box/URAPshared/Data/Econ_data/aer_additional_material.csv")
zip_list <- read.csv("C:/Users/snake/Box/URAPshared/Data/Econ_data/aer_data_attachment_info.csv")

# Select 2001-2009 data
add_mat_01_09 <- add_mat %>% 
  separate(publication_date, into = c("pubyear", "pubmonth"), sep = "/") %>%
  filter(pubyear >= 2001 & pubyear <= 2009)

# extract the name of the .zip files
add_mat_01_09$filename <- as.character(sub('^.*/','', add_mat_01_09$data_url))

# append the dois, titles and URLs
zip_list$doi = NA
zip_list$title = NA
zip_list$url = NA
for(i in c(1:nrow(zip_list))){
  for(j in c(1:nrow(add_mat_01_09))){
    if(identical(as.character(zip_list$file_name[i]), add_mat_01_09$filename[j])) {
      zip_list$doi[i] = as.character(add_mat_01_09$doi[j])
      zip_list$title[i] = as.character(add_mat_01_09$title[j])
      zip_list$url[i] = as.character(add_mat_01_09$url[j])
    }
  }
}

# modify code extensions to include fortran (.f)
data_extensions = c("dta", 'csv', 'xls', 'sas', 'mat','CSV', 'XLS', 'nb', 'dat', 'DAT')
code_extensions = c('do', 'exe', 'm', 'r', 'h', 'c', 'M', 'f90', 'ado','java', 'SPS', 'sps', 'f', 'F')

# Change data type
zip_list$extensions = strsplit(as.character(zip_list$extensions_collapsed), split = " ; ")
zip_list$basenames = as.character(zip_list$basenames_collapsed)

# Checking if data or code
for (i in c(1:nrow(zip_list))){
  zip_list$data[i] = length(intersect(zip_list$extensions[[i]], data_extensions)) != 0
  zip_list$code[i] = length(intersect(zip_list$extensions[[i]], code_extensions)) != 0
}

# improve on txt
# make sure it isn't a readme
zip_list$readme = NA
for (i in c(1:nrow(zip_list))){
  zip_list$contain_txt[i] = 'txt' %in% zip_list$extensions[[i]]
  if (zip_list$contain_txt[i]){
    zip_list$readme[i] = grepl('[Rr][Ee][Aa][Dd].[^;].(TXT|txt)', zip_list$basenames[i])
  } else {
    zip_list$readme[i] = FALSE
  }
}

# column if filename contains data
for (i in c(1:nrow(zip_list))){
  zip_list$contain_data[i] = grepl('[Dd][Aa][Tt][Aa]', zip_list$basenames[[i]])
}

write.csv(zip_list[,c('file_name', 'doi', 'title', 'url', 'data', 'code', 'contain_txt', 'contain_data', 'basenames_collapsed', 'extensions_collapsed')], "aer_fileext_SZ.csv")  

