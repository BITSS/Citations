library(stringi)
library(stringr)
library(plyr)

#setwd('C:/Users/caoba/OneDrive/URAP2/Citations/data_collection_econ/pdf_to_txt')
#setwd('/home/baiyue/Documents/pdf_to_txt')

###################################################################################
##################### Extract Footnotes from TXT files ############################
###################################################################################

all_txt_files = list.files('./aertxt', pattern = '.txt')
mtx = matrix(0, ncol = 2, nrow = length(all_txt_files))
index_institution = data.frame(mtx, stringsAsFactors=FALSE)

find_footnote <- function (file){
  file_name = paste('aertxt/', file, sep = '')
  file_index = gsub("aer.txt", "", file)
  #read text into data frame
  df = try(data.frame(read.table(file_name, sep="\n", quote = "", encoding="UTF-8")))
  foot_row = which(substring(df$V1, 1, 1) == '*')[1]
  end_foot_row = 60
  if (is.na(foot_row)){
    return(c(file_name,NA))
  } else {
      if (foot_row >= 60) { 
        footnote_string = gsub('-', '', paste(df$V1[foot_row:120], collapse=""))
        return (c(file_index,footnote_string)) 
    } else {
      footnote_string = gsub('-', '', paste(df$V1[foot_row:end_foot_row], collapse=""))
      return (c(file_index,footnote_string)) 
      }
  }
}

for (i in c(1:2392)){
  index_institution[i,] = find_footnote(all_txt_files[i])
}

#mannually enter for row 2393, because can't read into dataframe
index_institution[2393,] = c('3361', '*Weiman: Department of Economics, Barnard College,3009 Broadway, NY, NY 10027 (e-mail: dfw5@columbia.edu); James: Department of Economics, University of Virginia, PO Box 400182, Charlottesville, VA 22904 (e-mail:jaj8y@virginia.edu).')

for (i in c(2394:length(all_txt_files))){
  index_institution[i,] = find_footnote(all_txt_files[i])
}

colnames(index_institution) = c('index', 'footnote')

# Save for record
inst<-file('aer_institution.csv',encoding="UTF-8")
write.csv(index_institution, inst)

index_institution = read.csv('aer_institution.csv', 
                             header = TRUE, 
                             stringsAsFactors = FALSE,
                             encoding="UTF-8")

index_institution = index_institution[,c(2,3)]
######################################################################################
###################### Import Article/School/Institution information #################
######################################################################################

indexed_aer = read.csv('indexed_aer.csv', 
                       header = TRUE, 
                       stringsAsFactors = FALSE,
                       encoding="UTF-8")
indexed_aer = indexed_aer[,c(-1)]

schools = read.csv('school_and_country_table.csv', 
                   header = TRUE, 
                   stringsAsFactors = FALSE,
                   encoding="UTF-8")

colnames(schools) = c('school_name','country', 'other_name')

######################################################################################
###################### Find Institution Matching   ###################################
######################################################################################

#extract all text before the main author says thanks or grateful,
#exclude all text about seminar participants and financial support

index_institution$pre_thank = unlist(lapply(index_institution$footnote, 
                                            function (x) {strsplit(tolower(x), 
                                                                   "thank|grate|seminar|support")[[1]][[1]][1]}))

#remove all spaces and non-letter characters
index_institution$collapse_pre_thank = lapply(index_institution$pre_thank, 
                                              function (x) {gsub("[^[:alnum:]]", "", x)})
#do the same for school names or institutions names
schools$collapsed_school = lapply(schools$school_name, 
                                  function (x) {gsub("[^[:alnum:]]| at ", "", tolower(x))})
#do the same for alternative anmes for each institution/school 
schools$collapsed_other = lapply(schools$other_name,
                                  function (x) {gsub("[^[:alnum:]]", "", tolower(x))})

#generate matching matrix
keywords <- tolower(schools$collapsed_school)
keywords1 <- tolower(schools$collapsed_other)
keywords1 = keywords1[keywords1 != ""]
strings <- unlist(index_institution$collapse_pre_thank)

matches <- data.frame(sapply(keywords, grepl, strings))
matches1 <- data.frame(sapply(keywords1, grepl, strings))
index_institution$uni = NA

#get a list of unique matchings for each article entry
for (i in c(1: nrow(index_institution))){
  uni_collapsed = keywords[unlist(matches[i,])]
  uni_collapsed_other = keywords1[unlist(matches1[i,])]
  uni_collapsed_other = uni_collapsed_other[uni_collapsed_other != ""]
  uni_collapsed = c(uni_collapsed, uni_collapsed_other)
  index_institution$uni_collapsed[i] = list(uni_collapsed)
}

#Set all unmatched to NA 
index_institution$uni_collapsed = lapply(index_institution$uni_collapsed, 
                               function(x) if(identical(x, character(0))) NA_character_ else x)


#23 unmatched 
unmatched = subset(index_institution, is.na(uni_collapsed))
unmatched = subset(unmatched, !is.na(footnote))
unmatched$pre_thank_sep = lapply(unmatched$pre_thank, 
                                 function (x) {strsplit(tolower(x), ",")})

######################################################################################
######################    settle with final name    ##################################
######################################################################################

#convert collapsed names into normal names
for (i in c(1:nrow(index_institution))){
  uni_collapsed_list = unlist(index_institution$uni_collapsed[i])
  uni_list1 = lapply(uni_collapsed_list, function (x) {which(schools$collapsed_school == x)})
  uni_list2 = lapply(uni_collapsed_list, function (x) {which(schools$collapsed_other == x)})
  uni_list = unique(c(unlist(uni_list1), unlist(uni_list2)))
  index_institution$uni[i] = list(schools$school_name[uni_list])
}

######################################################################################
################## Download Draf File for inspection #################################
######################################################################################

draft = index_institution[,c('index', 'pre_thank', 'uni')]
draft$uni = lapply(draft$uni, 
                       function (x) {paste0(x, collapse = ' / ')})
draft$uni = unlist(draft$uni)
write.csv(draft, 'aer_insitution_draft.csv',  row.names = FALSE)

#correction log: 
# nuf<U+FB01>eld college to Nuffield College
# 2160aer.txt contains footnote irregularity, republicatoin of 313
# 2329 UC, irvine, author didn't put campus name
# 2883 report 
# 2939 Northwestern university
# 3050 report 
# 313 footnote misdetected because of math formula
# 3234 werid footnote format
# 3367  humboldt  universität  zu  berlin ,weird characters
# 3491 report
# 3493 report
# 447 report
# 503 same issue as 2939
# 670 report 
# 800 first time issue of 3234

######################################################################################
##################       Check the unread articles         ###########################
######################################################################################
unread = index_institution[grep('aer', index_institution$index),]
unread = data.frame(unread[,c('index')])
colnames(unread) = c('file_path')
unread$index = lapply(unread$file_path, 
                             function(x) {gsub("aertxt/", "", x)})
unread$index = lapply(unread$index, 
                      function(x) {gsub("aer.txt", "", x)})
unread$index = as.numeric(unlist(unread$index))
unread = merge(unread, indexed_aer, by=c("index","index"), all.x = TRUE)
write.csv(unread, 'unread.csv',  row.names = FALSE)

#13, 220, 850, 1056, 2066, 3317, 3468 did not use asterisk for footnote
#article 3323 has unexpected indentation for asterisk, undetected by code
#all others are meeting minutes and journal reports or editor's note 

######################################################################################
################## Finish inspectoin and manual imput ################################
################## merge info into indexed_aer.csv    ################################
######################################################################################

final = read.csv('aer_insitution_draft.csv', 
                             header = TRUE, 
                             stringsAsFactors = FALSE,
                             encoding="UTF-8")

unread = read.csv('unread.csv', 
                  header = TRUE, 
                  stringsAsFactors = FALSE,
                  encoding="UTF-8")

unread$uni = unread$X.1
unread = subset(unread, X == 1)
final <- merge(indexed_aer, final[,c('index', 'uni')],by=c("index","index"), all.x = TRUE)


final$uni[final$index %in% unread$index] = unread$uni

write.csv(final, 'indexed_aer.csv',  row.names = FALSE)




#3237, 3507












