# Setup
library(tidyverse)
library(forcats)
library(stringr)
library(rprojroot) # find project root
setwd(find_root('README.md'))

# Tools
remove_hyperlink <- function(text, hyperlink_separator = ';'){
  hyperlink <- paste0('^=HYPERLINK\\(".+?"', hyperlink_separator, '"(.+?)"\\)$')
  str_replace(text, hyperlink, '\\1')
}

# Article coding (aka topic and type)
## Import harmonized files
ajps_article <- read_csv('data_entry/ajps_article_coding_harmonized.csv') %>%
  mutate(journal = 'ajps')
apsr_article <- read_csv('data_entry/apsr_article_coding_harmonized.csv') %>%
  mutate(journal = 'apsr')
apsr_centennial_article <- read_csv('data_entry/apsr_centennial_article_coding_harmonized.csv') %>%
  mutate(journal = 'apsr_centennial')

## Combine data from AJPS, APSR and APSR centennial into a single dataframe
article_coding <- bind_rows(ajps_article, apsr_article, apsr_centennial_article)

## Remove hyperlinking
article_coding <- article_coding %>%
  mutate_at('title', remove_hyperlink)

## If either topic or data type is 'skip', set the other column value to 'skip' as well
article_coding <- article_coding %>%
  mutate(article_topic1 = if_else(article_topic1 == 'skip' | article_data_type == 'skip', 'skip', article_topic1, article_topic1),
         article_data_type = if_else(article_topic1 == 'skip' | article_data_type == 'skip', 'skip', article_data_type, article_data_type))

## Define topic and data type levels
article_topic_levels <- c(
  'american_government_and_politics',
  'comparative_politics',
  'international_relations',
  'political_methodology',
  'political_theory',
  'skip'
)

article_data_type_levels <- c(
  'experimental',
  'observational',
  'simulations',
  'no_data',
  'skip'
)

article_coding <- article_coding %>%
  mutate_at('article_topic1', parse_factor, levels = article_topic_levels) %>%
  mutate_at('article_data_type', parse_factor, levels = article_data_type_levels)

# Author website
## Import harmonized files
ajps_author_website <- read_csv('data_entry/ajps_author_website_coding_harmonized.csv') %>%
  mutate(journal = 'ajps')
apsr_author_website <- read_csv('data_entry/apsr_author_website_coding_harmonized.csv') %>%
  mutate(journal = 'apsr')

# Combine data from AJPS and APSR into a single dataframe
author_website <- bind_rows(ajps_author_website, apsr_author_website)

## Remove hyperlinking
author_website <- author_website %>%
  mutate_at('author', remove_hyperlink, hyperlink_separator = ',')

## Define website category levels
website_category_levels <- c(
  'skip',
  'could_not_find',
  '0',
  'data_dead',
  'code_dead',
  'files_dead',
  'data',
  'code',
  'files'
)

author_website <- author_website %>%
  mutate_at('website_category', parse_factor, levels = website_category_levels, ordered = TRUE) %>%
  mutate(website_category_data = website_category %>%
           fct_collapse(`0` = c('0', 'code', 'code_dead'),
                        data_dead = c('data_dead', 'files_dead'),
                        data = c('data', 'files')
                        ),
         website_category_code = website_category %>%
           fct_collapse(`0` = c('0', 'data', 'data_dead'),
                        code_dead = c('code_dead', 'files_dead'),
                        code = c('code', 'files')
           ))

## Find highest level of availability
author_website <- author_website %>%
  group_by(doi) %>%
  mutate(author_website_data = max(website_category_data),
         author_website_code = max(website_category_code)) %>%
  # case_when in mutate is still experimental
  # https://stackoverflow.com/a/38649748/
  ungroup %>%
  mutate(
         author_website_files = case_when(
           .$author_website_data == 'data' & .$author_website_code == 'code' ~ 'files',
           .$author_website_data == 'data_dead' & .$author_website_code == 'code_dead' ~ 'files_dead',
           TRUE ~ as.character(.$website_category)
           ) %>%
           parse_factor(levels = website_category_levels, ordered = TRUE)
  ) %>%
  group_by(doi) %>%
  mutate_at('author_website_files', max)

# Summarize to one row per article
author_website <- author_website %>%
  ungroup() %>%
  distinct(journal, article_ix, doi, title, author_website_data, author_website_code, author_website_files)


# uploading and binding ajps and apsr dataverse
ajps_dataverse <- read.csv('data_entry/ajps_dataverse_diff_resolution_RP_TC.csv')

apsr_dataverse <- read.csv('data_entry/apsr_dataverse_diff_resolution_RP_TC.csv')

# bind ajps and apsr dataverse file and add dataverse variable to main df
dataverse <- bind_rows(ajps_dataverse, apsr_dataverse)

#made result_category_RP_TC_resolved a factor variable so that we could then
#individual vars for files, data, and code availability on dataverse
dataverse$result_category_RP_TC_resolved <- as.factor(dataverse$result_category_RP_TC_resolved)

dataverse <- dataverse %>%
  mutate(files_dataverse = dataverse$result_category_RP_TC_resolved == 'files',
         data_dataverse = dataverse$result_category_RP_TC_resolved == 'data',
         code_dataverse = dataverse$result_category_RP_TC_resolved == 'code')

dataverse$files_dataverse <- as.numeric(dataverse$files_dataverse)
dataverse$data_dataverse <- as.numeric(dataverse$data_dataverse)
dataverse$code_dataverse <- as.numeric(dataverse$code_dataverse)

# 'collapse' dataverse file so that there is only one obs. per article
dataverse1 <- dataverse %>%
  group_by(doi) %>%
  summarize(files_dataverse = max(files_dataverse),
            data_dataverse = max(data_dataverse),
            code_dataverse = max(code_dataverse))

# add files, data and code dataverse variables to the main df
main.df <- left_join(main.df, dataverse1, by='doi')

# if files_dataverse=1 then data_dataverse and code_dataverse =1
main.df$data_dataverse[main.df$files_dataverse == 1] <- '1'
main.df$code_dataverse[main.df$files_dataverse == 1] <- '1'


# uploading and binding ajps and apsr links
ajps_links <- read.csv('data_entry/ajps_link_coding_diff_resolution.csv')

apsr_links <- read.csv('data_entry/apsr_link_coding_RP.csv')

links <- bind_rows(ajps_links, apsr_links)

# create variables: files_link, data_link and code_link. Note: only consider full file, data and code
links <- links %>%
  mutate(files_link = links$link_category_resolved == 'files',
         data_link = links$link_category_resolved == 'data',
         code_link = links$link_category_resolved == 'code')

links$files_link <- as.numeric(links$files_link)
links$data_link <- as.numeric(links$data_link)
links$code_link <- as.numeric(links$code_link)

links <- links %>%
  group_by(doi) %>%
  summarize(files_link = max(files_link),
            data_link = max(data_link),
            code_link = max(code_link))

# If files = 1 then data = 1 and code = 1
links$data_link[links$files_link == 1] <- '1'
links$code_link[links$files_link == 1] <- '1'

# If data = 1 and code = 1 then files = 1
links$files_link[links$data_link == 1 & links$code_link == 1] <- '1'

# Make files_link, data_link and code_link numeric
links$files_link <- as.numeric(links$files_link)
links$data_link <- as.numeric(links$data_link)
links$code_link <- as.numeric(links$code_link)

# Append links to main.df
main.df <- left_join(main.df, links, by='doi')

# # # # # Reference Coding
ajps_references <- read.csv('data_entry/ajps_reference_coding_harmonized.csv')
apsr_references <- read.csv('data_entry/apsr_reference_coding_harmonized.csv')

references <- bind_rows(ajps_references, apsr_references)

references <- references %>%
  mutate(files_full_name = reference_category == 'files_full_name',
            data_full_name = reference_category == 'data_full_name',
            code_full_name = reference_category == 'code_full_name')

references$files_full_name <- as.numeric(references$files_full_name)
references$data_full_name <- as.numeric(references$data_full_name)
references$code_full_name <- as.numeric(references$code_full_name)

ref <- references %>%
  group_by(doi) %>%
  summarise(files_references = max(files_full_name),
            data_references = max(data_full_name),
            code_references = max(code_full_name))




# # # #TESTING
# # # AJPS
test_ajpsweb <- ajps_author_website %>%
  mutate(data.avail = ajps_author_website$website_category == 'data',
         code.avail = ajps_author_website$website_category == 'code',
         files.avail = ajps_author_website$website_category == 'files')

test_ajpsweb$data.avail <- as.numeric(test_ajpsweb$data.avail)
test_ajpsweb$code.avail <- as.numeric(test_ajpsweb$code.avail)
test_ajpsweb$files.avail <- as.numeric(test_ajpsweb$files.avail)


test_ajpsweb <- test_ajpsweb %>%
  group_by(doi) %>%
  summarize(data_web = max(data.avail),
            code_web = max(code.avail),
            files_web = max(files.avail))

# # # # # APSR
test_apsrweb <- apsr_author_website %>%
  mutate(data.avail = apsr_author_website$website_category == 'data',
         code.avail = apsr_author_website$website_category == 'code',
         files.avail = apsr_author_website$website_category == 'files')

test_apsrweb$data.avail <- as.numeric(test_apsrweb$data.avail)
test_apsrweb$code.avail <- as.numeric(test_apsrweb$code.avail)
test_apsrweb$files.avail <- as.numeric(test_apsrweb$files.avail)

test_apsrweb %>%
  group_by(doi) %>%
  summarize(title = first(title),
            data_web = max(data.avail),
            code_web = max(code.avail),
            files_web = max(files.avail)) %>%
  anti_join(apsr_type_topic, by='doi') %>% View()
  summarize(distinct_title = n_distinct(title))

## checking for 'extra' articles in test_apsrweb with apsr_type_topic by doi
apsr_diff <- anti_join(test_apsrweb, apsr_type_topic, by = 'doi')










# # # # Reference coding check
ajps_references <- read.csv('data_entry/ajps_reference_coding_harmonized.csv')
apsr_references <- read.csv('data_entry/apsr_reference_coding_harmonized.csv')

ajps_references <- ajps_references %>%
  mutate(files_full_name = reference_category == 'files_full_name',
         data_full_name = reference_category == 'data_full_name',
         code_full_name = reference_category == 'code_full_name')

ajps_references$files_full_name <- as.numeric(ajps_references$files_full_name)
ajps_references$data_full_name <- as.numeric(ajps_references$data_full_name)
ajps_references$code_full_name <- as.numeric(ajps_references$code_full_name)

test_ajpsref <- ajps_references %>%
  group_by(doi) %>%
  summarise(files_references = max(files_full_name),
            data_references = max(data_full_name),
            code_references = max(code_full_name))

apsr_references <- apsr_references %>%
  mutate(files_full_name = reference_category == 'files_full_name',
         data_full_name = reference_category == 'data_full_name',
         code_full_name = reference_category == 'code_full_name')

apsr_references$files_full_name <- as.numeric(apsr_references$files_full_name)
apsr_references$data_full_name <- as.numeric(apsr_references$data_full_name)
apsr_references$code_full_name <- as.numeric(apsr_references$code_full_name)

test_apsrref <- apsr_references %>%
  group_by(doi) %>%
  summarise(files_references = max(files_full_name),
            data_references = max(data_full_name),
            code_references = max(code_full_name))


###### TEST FOR EACH MERGER ##########
anti_join(dv, main, by = 'doi') %>% nrows
