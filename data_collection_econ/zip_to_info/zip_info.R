getwd()
setwd('/home/baiyue/Documents/URAP2/Citations/data_collection_econ/zip_to_info')
library(tools)

zip_list = data.frame(list.files('../econ_data/data_files'))
colnames(zip_list) = c('file_name')
zip_list$content = NA
zip_list$file_path = paste('../econ_data/data_files/', zip_list$file_name, sep = "")
zip_list$zip = grepl('.zip', zip_list$file_name)
zip_list$extensions = NA
zip_list$data = NA
zip_list$code = NA


for (i in c(1:59, 61:nrow(zip_list))){
  if (zip_list$zip[i]){
    zip_list$content[i] = list(unzip(zip_list$file_path[i], list = TRUE))
    zip_list$extensions[i] = lapply(zip_list$content[i], function(x){unique(file_ext(x[[1]]))})
  } else {
    zip_list$content[i] = NA
  }
}

zip_list$extensions[zip_list$zip == FALSE] = file_ext(zip_list$file_name[zip_list$zip == FALSE])


zip_list$nested_zip = grepl('.zip', zip_list$content)

nested_zips = subset(zip_list, nested_zip)

#20041118_data.zip file can't open

# command line used to extract nested zips 
unzip_command = "while [ $(find . -type f -name '*.zip' | wc -l) -gt 0 ]; do find -type f -name '*.zip' -exec unzip -o '{}' \\; -exec rm -- '{}' \\;; done"

#a directory to store unnested zip files
dir.create('./processed')

for (i in c(34:nrow(nested_zips))){
  folder = file_path_sans_ext(as.character(nested_zips$file_name[i]))
  dir.create(folder)
  file.copy(nested_zips$file_path[i], folder)
  setwd(folder)
  system(unzip_command)
  setwd('..')
  zip_command = paste(c('zip -r ./processed/', as.character(nested_zips$file_name[i]), ' ', folder), sep = "", collapse = "")
  system(zip_command)
  unlink(folder, recursive = TRUE)
}

for (i in c(1:20, 22:32, nrow(nested_zips))){
  nested_zips$file_path[i] = paste('./processed/', nested_zips$file_name[i], sep = "")
  nested_zips$content[i] = list(unzip(nested_zips$file_path[i], list = TRUE))
  nested_zips$extensions[i] = lapply(nested_zips$content[i], function(x){unique(file_ext(x[[1]]))})
}

#33 21 crazy zips, have problem opening 
#20031260 
#rhode

zip_list[match(nested_zips$file_name, zip_list$file_name), ] <- nested_zips

data_extensions = c("dta", 'csv', 'xls', 'sas', 'mat','CSV', 'XLS', 'nb', 'dat', 'DAT')
code_extensions = c('do', 'exe', 'm', 'r', 'h', 'c', 'M', 'f90', 'ado','java', 'SPS', 'sps')
zip_list$contain_txt = NA
zip_list$basenames = NA

for (i in c(1:59, 61:351)){
  zip_list$data[i] = length(intersect(zip_list$extensions[[i]], data_extensions)) != 0
  zip_list$code[i] = length(intersect(zip_list$extensions[[i]], code_extensions)) != 0
  zip_list$contain_txt[i] = 'txt' %in% zip_list$extensions[[i]]
  zip_list$extensions_collapsed[i] = paste(zip_list$extensions[[i]], collapse = " ; ")
  if (zip_list$zip[i]){
    zip_list$basenames[i] = list(basename(zip_list$content[[i]]$Name))
  } else {
    zip_list$basenames[i] = zip_list$file_name[i]
  }
  zip_list$basenames_collapsed[i] = paste(zip_list$basenames[[i]], collapse = " ; ")
}

zip_list$data = unlist(zip_list$data)
zip_list$code = unlist(zip_list$code)
zip_list$extensions_collapsed = unlist(zip_list$extensions_collapsed)

write.csv(zip_list[,c('file_name', 'data', 'code', 'contain_txt', 'basenames_collapsed', 'extensions_collapsed')], 
          'aer_data_attachment_info.csv')





