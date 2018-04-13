# Setup
library(tidyr)
library(dplyr)
library(forcats)
library(stringr)
library(rvest)
library(readr)
library(rprojroot) # find project root
setwd(find_root('README.md'))

# Tools
remove_hyperlink <- function(text, hyperlink_separator = ';'){
  hyperlink <- paste0('^=HYPERLINK\\(".+?"', hyperlink_separator, '"(.+?)"\\)$')
  str_replace(text, hyperlink, '\\1')
}

join_columns = c('journal', 'doi', 'title')

# Article JEL coding
## Import harmonized files
article_coding_jel <- read.csv('Econ_data/external/econlit_data_with_jel_topics.csv') %>%
  mutate(journal = aer.qje) %>%
  mutate(article_topic = JEL_econlit) %>%
  select(doi, journal, title, article_topic)

## Define JEL levels
article_jel_levels <- c(
  'General Economics and Teaching',
  'History of Economic Thought, Methodology, and Heterodox Approaches',
  'Mathematical and Quantitative Methods',
  'Microeconomics',
  'Macroeconomics and Monetary Economics',
  'International Economics',
  'Financial Economics',
  'Public Economics',
  'Health, Education and Welfare',
  'Labor and Demographic Economics',
  'Law and Economics',
  'Industrial Organization',
  'Business Administration and Business Economics; Marketing; Accounting; Personnel Economics',
  'Economic History',
  'Economic Development, Innovation, Technological Change, and Growth',
  'Economic Systems',
  'Agricultural and National Resource Economics; Environmental and Ecological Economics',
  'Urban, Rural, Regional, Real Estate, and Transportation Economics',
  'Miscellaneous Categories',
  'Other Special Topics',
  'skip'
)

levels(article_coding_jel$article_topic) <- article_jel_levels
article_coding_jel$article_topic[is.na(article_coding_jel$article_topic)] <- 'skip'

# Article data types
## Import harmonized files
aer_article_type <- read.csv('Econ_data/external/indexed_aer_with_jel_harmonized.csv') %>%
  mutate(journal = 'aer')
qje_article_type <- read.csv('Econ_data/external/indexed_qje_with_jel_harmonized.csv') %>%
  mutate(journal = 'qje')

## Combine data from AER, and QJE into a single dataframe
article_coding_type <- bind_rows(aer_article_type, qje_article_type)

## Combine JEL and Data types into single dataframe
article_coding <- article_coding_jel %>%
  left_join(article_coding_type, join_columns)

## Remove hyperlinking
article_coding <- article_coding %>%
  mutate_at('title', remove_hyperlink)

## Define data type levels
article_data_type_levels <- c(
  'experimental',
  'observational',
  'simulations',
  'no_data',
  'skip'
)

## If jel  is 'skip', set data type to 'skip' as well
article_coding <- article_coding %>% 
  mutate(article_data_type = if_else(article_topic == 'skip', 'skip', article_data_type))

article_coding <- article_coding %>%
  mutate(topic = parse_factor(article_topic, levels = article_jel_levels),
         data_type = parse_factor(article_data_type, levels = article_data_type_levels))

article_coding <- article_coding %>%
  select(journal, doi, title, publication_date, abstract, topic, data_type)

# Author website
## Import harmonized files
aer_author_website <- read.csv('Econ_data/external/aer_author_website_coding_harmonized.csv') %>%
  mutate(journal = 'aer')
qje_author_website <- read.csv('Econ_data/external/qje_author_website_coding_harmonized.csv') %>%
  mutate(journal = 'qje')

## Combine data from AER and QJE into a single dataframe
author_website <- bind_rows(aer_author_website, qje_author_website)

## Remove hyperlinking
author_website <- author_website %>%
  mutate_at('author', remove_hyperlink, hyperlink_separator = ',')

## Define website category levels
availability_website_levels <- c(
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

## Find highest level of availability
author_website <- author_website %>%
  mutate(availability_website = parse_factor(website_category, levels = availability_website_levels, ordered = TRUE)) %>%
  mutate(availability_website_data = availability_website %>%
           fct_collapse(`0` = c('0', 'code', 'code_dead'),
                        data_dead = c('data_dead', 'files_dead'),
                        data = c('data', 'files')
           ),
         availability_website_code = availability_website %>%
           fct_collapse(`0` = c('0', 'data', 'data_dead'),
                        code_dead = c('code_dead', 'files_dead'),
                        code = c('code', 'files')
           ))

author_website <- author_website %>%
  group_by(doi) %>%
  mutate_at(c('availability_website_data', 'availability_website_code'), max) %>%
  # Using 'case_when' in 'mutate' is still experimental
  # https://stackoverflow.com/a/38649748/
  ungroup %>%
  mutate(
    availability_website = case_when(
      .$availability_website_data == 'data' & .$availability_website_code == 'code' ~ 'files',
      .$availability_website_data == 'data_dead' & .$availability_website_code == 'code_dead' ~ 'files_dead',
      TRUE ~ as.character(.$website_category)
    ) %>%
      parse_factor(levels = availability_website_levels, ordered = TRUE)
  ) %>%
  group_by(doi) %>%
  mutate_at('availability_website', max)

## Summarize to one row per article
author_website <- author_website %>%
  ungroup() %>%
  distinct(journal, doi, title, availability_website)

# Dataverse
## Import harmonized files
## Dataverse files were coded only by RP and TC, so take their resolution file as source
qje_dataverse <- read.csv('Econ_data/external/qje_dataverse_search_GC.csv') %>%
  mutate(journal = 'qje')
aer_dataverse <- read.csv('Econ_data/external/aer_dataverse_search_GC.csv') %>%
  mutate(journal = 'aer')

## Combine data from AJPS and APSR into a single dataframe
dataverse <- bind_rows(qje_dataverse, aer_dataverse)

## Relabel variable and levels to be consistent with other files
dataverse <- dataverse %>%
  mutate(availability_dataverse = result_category) %>%
  mutate_at('availability_dataverse', fct_collapse, `0` = c('none'))

## Define dataverse category levels
availability_dataverse_levels <- c(
  '0',
  'data',
  'code',
  'files'
)

## Find highest level of availability
dataverse <- dataverse %>%
  mutate_at('availability_dataverse', parse_factor, levels = availability_dataverse_levels, ordered = TRUE) %>%
  mutate(availability_dataverse_data = availability_dataverse %>%
           fct_collapse(`0` = c('code'),
                        data = c('data', 'files')
           ),
         availability_dataverse_code = availability_dataverse %>%
           fct_collapse(`0` = c('data'),
                        code = c('code', 'files')
           ))

dataverse <- dataverse %>%
  group_by(doi) %>%
  mutate_at(c('availability_dataverse_data', 'availability_dataverse_code'), max) %>%
  # Using 'case_when' in 'mutate' is still experimental
  # https://stackoverflow.com/a/38649748/
  ungroup %>%
  mutate(
    availability_dataverse = case_when(
      .$availability_dataverse_data == 'data' & .$availability_dataverse_code == 'code' ~ 'files',
      TRUE ~ as.character(.$availability_dataverse)
    ) %>%
      parse_factor(levels = availability_dataverse_levels, ordered = TRUE)
  ) %>%
  group_by(doi) %>%
  mutate_at('availability_dataverse', max) %>%
  ungroup

## Summarize to one row per article
dataverse <- dataverse %>%
  distinct(journal, doi, title, availability_dataverse)

# Links
aer_link <- read.csv('Econ_data/external/aer_with_sample_selection_link_coding_harmonized.csv') %>%
  mutate(journal = 'aer')
qje_link <- read.csv('Econ_data/external/qje_link_coding_harmonized.csv') %>%
  mutate(journal = 'qje')

link <- bind_rows(aer_link, qje_link)

availability_link_levels <- c(
  'dead',
  'redirect_to_general',
  'could_not_find',
  'restricted_access',
  'data',
  'code',
  'files'
)

link <- link %>%
  mutate(availability_link = parse_factor(link_category, levels = availability_link_levels, ordered = TRUE, include_na = FALSE))

## Drop observations with unknown factor levels
link <- link %>%
  drop_na(availability_link)

## Find highest level of availability
link <- link %>%
  mutate(availability_link_data = availability_link %>%
           fct_collapse(could_not_find = c('code'),
                        data = c('data', 'files')),
         availability_link_code = availability_link %>%
           fct_collapse(could_not_find = c('data'),
                        code = c('code', 'files')))

link <- link %>%
  group_by(doi) %>%
  mutate_at(c('availability_link_data', 'availability_link_code'), max) %>%
  # Using 'case_when' in 'mutate' is still experimental
  # https://stackoverflow.com/a/38649748/
  ungroup %>%
  mutate(
    availability_link = case_when(
      .$availability_link_data == 'data' & .$availability_link_code == 'code' ~ 'files',
      TRUE ~ as.character(.$availability_link)
    ) %>%
      parse_factor(levels = availability_link_levels, ordered = TRUE)
  ) %>%
  group_by(doi) %>%
  mutate_at('availability_link', max) %>%
  ungroup

## Summarize to one row per article
link <- link %>%
  distinct(journal, doi, title, availability_link)

# References
## Import harmonized files
aer_reference <- read.csv('Econ_data/external/aer_with_sample_selection_reference_coding_harmonized.csv') %>%
  mutate(journal = 'aer')
qje_reference <- read.csv('Econ_data/external/qje_reference_coding_harmonized.csv') %>%
  mutate(journal = 'qje')


## Combine data from AER and QJE into a single dataframe
reference <- bind_rows(aer_reference, qje_reference)

## Remove hyperlinking
reference <- reference %>%
  mutate_at('title', remove_hyperlink, hyperlink_separator = ',')

## Define reference levels
reference <- reference %>%
  separate(reference_category, into = c('reference_what',
                                        'reference_how_much',
                                        'reference_how'),
           sep = '_', remove = FALSE, fill = 'right') %>%
  mutate(reference_how_much = if_else(is.na(reference_how_much), reference_what, reference_how_much),
         reference_how = if_else(is.na(reference_how), reference_what, reference_how))

reference_what_levels <- c(
  'skip',
  '0',
  'data',
  'code',
  'files'
)

reference_how_much_levels <- c(
  'skip',
  '0',
  'partial',
  'full'
)

reference_how_levels <- c(
  'skip',
  '0',
  'paper',
  'name',
  'link',
  'dataverse'
)

reference <- reference %>%
  mutate_at('reference_what', parse_factor, levels = reference_what_levels, ordered = TRUE) %>%
  mutate_at('reference_how_much', parse_factor, levels = reference_how_much_levels, ordered = TRUE) %>%
  mutate_at('reference_how', parse_factor, levels = reference_how_levels, ordered = TRUE)

## Find highest level of stated availability
reference_strict_levels <- c('link', 'dataverse')
reference_easy_levels <- c('link', 'dataverse', 'paper' ,'name')
reference_united_levels <- c(
  '0_0',
  '0_1',
  '1_0',
  '1_1'
)
reference_what_how_much_levels <- c('NA',
                                    'code_partial', 'data_partial', 'files_partial',
                                    'code_full', 'data_full', 'files_full')

reference <- reference %>%
  mutate(reference_strict = reference_how %in% reference_strict_levels,
         reference_easy = reference_how %in% reference_easy_levels)

## Note that at this point 'code' + 'data' != 'files', since 'files' is evaluated only from entries that contain 'files_x_x'.
## This is useful to dinstinguish two references, 'code' and 'data', from a single 'files' reference.
reference <- reference %>%
  unite(reference_what_how_much, reference_what, reference_how_much, remove = FALSE) %>%
  mutate_at('reference_what_how_much', factor, levels = reference_what_how_much_levels) %>%
  group_by(doi, reference_what_how_much) %>%
  mutate_at(c('reference_strict', 'reference_easy'), max) %>%
  ungroup %>%
  unite(reference, reference_strict, reference_easy, remove = FALSE) %>%
  mutate_at('reference', parse_factor, levels = reference_united_levels, ordered = TRUE) %>%
  select(journal, doi, title, reference_what_how_much, reference) %>%
  # As of Jun 2, 2017 'drop = FALSE' in 'spread' is not working as intended.
  # https://github.com/tidyverse/tidyr/issues/254
  # Add 'NA' as level of 'reference_what_how_much_levels' to preserve articles with only '0_0' reference values
  distinct %>%
  spread(reference_what_how_much, reference, fill = '0_0', drop = TRUE) %>%
  select(-`<NA>`)

## Make sure that 'code' + 'data' = files.
## This removes the distinction between two references, 'code' and 'data', and a single 'files' reference.
reference <- reference %>%
  group_by(doi) %>%
  mutate(code_partial = max(code_partial, files_partial),
         data_partial = max(data_partial, files_partial),
         code_full = max(code_full, files_full),
         data_full = max(data_full, files_full),
         files_partial = min(code_partial, data_partial),
         files_full = min(code_full, data_full)) %>%
  ungroup

## Create separate variables for 'strict' and 'easy' definition of availability
reference <- reference %>%
  separate(code_partial, paste0('reference_code_partial_', c('strict', 'easy'))) %>%
  separate(data_partial, paste0('reference_data_partial_', c('strict', 'easy'))) %>%
  separate(files_partial, paste0('reference_files_partial_', c('strict', 'easy'))) %>%
  separate(code_full, paste0('reference_code_full_', c('strict', 'easy'))) %>%
  separate(data_full, paste0('reference_data_full_', c('strict', 'easy'))) %>%
  separate(files_full, paste0('reference_files_full_', c('strict', 'easy')))

# File Extensions (from AEA website, only applicable to AER)
file_extensions <- read.csv('Econ_data/external/aer_fileext_SZ.csv') %>%
  mutate(journal = 'aer')

## Define file extension category levels
availability_fileext_levels <- c(
  '0',
  'data',
  'code',
  'files'
)

## Find highest level of availability
file_extensions <- file_extensions %>%
  mutate(availability_fileext_data = ifelse(data == TRUE, "data", 0)) %>% 
  mutate(availability_fileext_code = ifelse(code == TRUE, "code", 0)) %>%
  mutate(availability_fileext = case_when(
    data == TRUE & code == TRUE ~ "files",
    data == TRUE & code == FALSE ~ "data",
    data == FALSE & code == TRUE ~ "code",
    data == FALSE & code == FALSE ~ "0"
  ) %>%
    parse_factor(levels = availability_fileext_levels, ordered = TRUE)
  ) %>%
  group_by(doi) %>%
  mutate_at('availability_fileext', max)

## Summarize to one row per article
file_extensions <- file_extensions %>%
  ungroup() %>%
  distinct(journal, doi, title, availability_fileext)

# Merge all article information
df <- article_coding %>%
  left_join(author_website, join_columns) %>%
  left_join(dataverse, join_columns) %>%
  left_join(link, join_columns) %>%
  left_join(reference, join_columns) %>%
  left_join(file_extensions, join_columns)

# Combine availability measure from different sources into single variable
availability_levels = c(
  'NA',
  '0',
  'code',
  'data',
  'files'
)

df <- df %>%
  bind_cols(df %>%
              mutate_at(vars(starts_with('availability_')),
                        parse_factor, levels = availability_levels, ordered = TRUE, include_na = TRUE) %>%
              rowwise %>%
              mutate(availability = max(availability_website, availability_dataverse, availability_link, availability_fileext, na.rm = TRUE) %>%
                       fct_recode('0' = 'NA')) %>%
              select(availability))

# Merge with citation_count data
aer_citation_count <- read.csv('Econ_data/external/aer_citations_scopus.csv') %>%
  mutate(journal = 'aer')
qje_citation_count <- read.csv('Econ_data/external/qje_citations_scopus.csv') %>%
  mutate(journal = 'qje')

## Values for title appear in both right-hand side and citation data. Choose value from right-hand side data.
citation_count <- bind_rows(aer_citation_count, qje_citation_count) %>%
  select(journal, doi, citation_count = citation)

df <- df %>%
  left_join(citation_count, by = c('journal', 'doi'))

# Order columns
df <- df %>% select(journal, publication_date, citation_count, doi, topic, data_type, title, abstract,
                    availability, starts_with('availability_'), starts_with('reference_'))

# Fixing problem with publication date
df <- df %>%
  drop_na(publication_date)
for (i in 1:length(df$publication_date)) {
   if (nchar(df$publication_date[i]) == 7) {
     df$publication_date[i] = paste(df$publication_date[i], "01", sep = "/")
   }
}

# Write dataframe to file
output_file <- 'citations_clean_data.csv'
df %>% write.csv(output_file)

