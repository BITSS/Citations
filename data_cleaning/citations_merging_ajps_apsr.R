
ajps_type_topic <- read.csv("../../URAPshared/Data/ajps_article_coding_harmonized.csv")

apsr_type_topic <- read.csv("../../URAPshared/Data/apsr_article_coding_harmonized.csv")

#binding the apsr and ajps files onto a df
library(dplyr)
library(tidyr)
main.df <- bind_rows(ajps_type_topic, apsr_type_topic)

#changing levels
topic_levels <- c("political_theory","american_government_and_politics",
                  "political_methodology","international_relations",
                  "comparative_politics")

main.df$article_topic1 <- factor(main.df$article_topic1, levels = topic_levels)

data_type_levels <- c("experimental", "observational", "simulations", "")
main.df$article_data_type <- factor(main.df$article_data_type)


#data availability 
ajps_author_website <- read.csv("../../URAPshared/Data/ajps_author_website_coding_harmonized.csv")
apsr_author_website <- read.csv("../../URAPshared/Data/apsr_author_website_coding_harmonized.csv")

author_web <- bind_rows(ajps_author_website, apsr_author_website)

# combining factor levels 
author_web <- author_web %>%
  mutate(data.avail = author_web$website_category == "data",
         code.avail = author_web$website_category == "code",
         files.avail = author_web$website_category == "files") 

author_web$data.avail <- as.numeric(author_web$data.avail)
author_web$code.avail <- as.numeric(author_web$code.avail)
author_web$files.avail <- as.numeric(author_web$files.avail)

# getting an observation per article
author_web_data <- author_web %>%
  group_by(doi) %>%
  summarize(data_web = max(data.avail),
            code_web = max(code.avail),
            files_web = max(files.avail))

# adding data, code and files availability to the main data frame
main.df <- right_join(main.df, author_web_data, by = "doi")

# this was an erratum on an erratum == "files" were available for the paper, but this here was 
# a clarification on that paper. 
main.df <- mutate(main.df, files_web = replace(files_web, doi == "10.1111/j.1540-5907.2011.00554.x", "skip"))

# if files = 1 then data & code = 1 ,
main.df$data_web[main.df$files_web == 1] <- "1"

main.df$code_web[main.df$files_web == 1] <- "1"

# for obs. where data was available from one author and code from another, files=1
main.df$files_web[main.df$data_web == 1 & main.df$code_web ==1] <- "1"


# uploading and binding ajps and apsr dataverse
ajps_dataverse <- read.csv("../../URAPshared/Data/ajps_dataverse_diff_resolution_RP_TC.csv")

apsr_dataverse <- read.csv("../../URAPshared/Data/apsr_dataverse_diff_resolution_RP_TC.csv")

# bind ajps and apsr dataverse file and add dataverse variable to main df
dataverse <- bind_rows(ajps_dataverse, apsr_dataverse)

#made result_category_RP_TC_resolved a factor variable so that we could then 
#individual vars for files, data, and code availability on dataverse
dataverse$result_category_RP_TC_resolved <- as.factor(dataverse$result_category_RP_TC_resolved)

dataverse <- dataverse %>% 
  mutate(files_dataverse = dataverse$result_category_RP_TC_resolved == "files",
         data_dataverse = dataverse$result_category_RP_TC_resolved == "data",
         code_dataverse = dataverse$result_category_RP_TC_resolved == "code")
  
dataverse$files_dataverse <- as.numeric(dataverse$files_dataverse)
dataverse$data_dataverse <- as.numeric(dataverse$data_dataverse)
dataverse$code_dataverse <- as.numeric(dataverse$code_dataverse)

# "collapse" dataverse file so that there is only one obs. per article 
dataverse1 <- dataverse %>%
  group_by(doi) %>%
  summarize(files_dataverse = max(files_dataverse),
            data_dataverse = max(data_dataverse),
            code_dataverse = max(code_dataverse))

# add files, data and code dataverse variables to the main df
main.df <- left_join(main.df, dataverse1, by="doi")

# if files_dataverse=1 then data_dataverse and code_dataverse =1
main.df$data_dataverse[main.df$files_dataverse == 1] <- "1"
main.df$code_dataverse[main.df$files_dataverse == 1] <- "1"


# uploading and binding ajps and apsr links
ajps_links <- read.csv("../../URAPshared/Data/ajps_link_coding_diff_resolution.csv")

apsr_links <- read.csv("../../URAPshared/Data/apsr_link_coding_RP.csv")

links <- bind_rows(ajps_links, apsr_links)

# create variables: files_link, data_link and code_link. Note: only consider full file, data and code
links <- links %>% 
  mutate(files_link = links$link_category_resolved == "files",
         data_link = links$link_category_resolved == "data",
         code_link = links$link_category_resolved == "code")

links$files_link <- as.numeric(links$files_link)
links$data_link <- as.numeric(links$data_link)
links$code_link <- as.numeric(links$code_link)

links <- links %>%
  group_by(doi) %>%
  summarize(files_link = max(files_link),
            data_link = max(data_link),
            code_link = max(code_link))

# If files = 1 then data = 1 and code = 1
links$data_link[links$files_link == 1] <- "1"
links$code_link[links$files_link == 1] <- "1"

# If data = 1 and code = 1 then files = 1
links$files_link[links$data_link == 1 & links$code_link == 1] <- "1"

# Make files_link, data_link and code_link numeric
links$files_link <- as.numeric(links$files_link)
links$data_link <- as.numeric(links$data_link)
links$code_link <- as.numeric(links$code_link)

# Append links to main.df
main.df <- left_join(main.df, links, by="doi")

# # # # # Reference Coding 
ajps_references <- read.csv("../../URAPshared/Data/ajps_reference_coding_harmonized.csv")
apsr_references <- read.csv("../../URAPshared/Data/apsr_reference_coding_harmonized.csv")

references <- bind_rows(ajps_references, apsr_references)

references <- references %>%
  mutate(files_full_name = reference_category == "files_full_name",
            data_full_name = reference_category == "data_full_name",
            code_full_name = reference_category == "code_full_name")

references$files_full_name <- as.numeric(references$files_full_name)
references$data_full_name <- as.numeric(references$data_full_name)
references$code_full_name <- as.numeric(references$code_full_name)

ref <- references %>%
  group_by(doi) %>%
  summarise(files_references = max(files_full_name),
            data_references = max(data_full_name),
            code_references = max(code_full_name))
  







###### TEST FOR EACH MERGER ##########
anti_join(dv, main, by = 'doi') %>% nrows