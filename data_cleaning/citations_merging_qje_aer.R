# Setup -------------------------------------------------------------------

library(tidyverse)
library(rprojroot) # find project root
setwd(find_root('README.md'))

# Tools -------------------------------------------------------------------

remove_hyperlink <- function(text, hyperlink_separator = ';'){
  hyperlink <- paste0('^=HYPERLINK\\(".+?"', hyperlink_separator, '"(.+?)"\\)$')
  str_replace(text, hyperlink, '\\1')
}

join_columns = c('journal', 'doi')


# Article JEL coding ------------------------------------------------------

## Import harmonized files
article_coding_jel <- read.csv('external_econ/econlit_data_with_jel_topics.csv', stringsAsFactors = F) %>%
  mutate(
    journal = aer.qje,
    article_topic = JEL_econlit
    ) %>%
  select(doi, journal, article_topic)


# Article data types ------------------------------------------------------

## Import harmonized files
aer_article_type <- read.csv('external_econ/indexed_aer_with_jel_harmonized.csv', stringsAsFactors = F) %>%
  mutate(journal = 'aer')
qje_article_type <- read.csv('external_econ/indexed_qje_with_jel_harmonized.csv', stringsAsFactors = F) %>%
  mutate(journal = 'qje')

## Combine data from AER, and QJE into a single dataframe
article_coding_type <- bind_rows(aer_article_type, qje_article_type)

## Combine JEL and Data types into single dataframe
article_coding <- article_coding_jel %>%
  left_join(article_coding_type, join_columns)

article_coding <- article_coding %>%
  rename(topic = article_topic,
         data_type = article_data_type) %>%
  select(journal, doi, title, author, abstract, publication_date, topic, data_type, institution)


# Author website ----------------------------------------------------------

## Import harmonized files
aer_author_website <- read.csv('external_econ/aer_author_website_coding_harmonized.csv', stringsAsFactors = F) %>%
  select(doi, website_category) %>%
  mutate(journal = 'aer')
qje_author_website <- read.csv('external_econ/qje_author_website_coding_harmonized.csv', stringsAsFactors = F) %>%
  select(doi, website_category) %>%
  mutate(journal = 'qje')

## Combine data from AER and QJE into a single dataframe
author_website <- bind_rows(aer_author_website, qje_author_website)

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
  group_by(journal, doi) %>%
  summarise(availability_website = max(availability_website)) %>%
  mutate(availability_website = as.character(availability_website))


# Dataverse ---------------------------------------------------------------

## Import harmonized files
## Dataverse files were coded only by RP and TC, so take their resolution file as source
qje_dataverse <- read.csv('external_econ/qje_dataverse_search_GC.csv', stringsAsFactors = F) %>%
  select(doi, result_category, confirmed_category) %>%
  mutate(journal = 'qje')
aer_dataverse <- read.csv('external_econ/aer_dataverse_search_GC.csv', stringsAsFactors = F) %>%
  select(doi, result_category, confirmed_category) %>%
  mutate(journal = 'aer')

## Combine data from AJPS and APSR into a single dataframe
dataverse <- bind_rows(qje_dataverse, aer_dataverse)

## Relabel variable and levels to be consistent with other files
dataverse <- dataverse %>%
  unite("availability_dataverse", c("result_category", "confirmed_category"), sep = "") %>%
  mutate(availability_dataverse = ifelse(availability_dataverse == 'none', '0', availability_dataverse))


# Links -------------------------------------------------------------------

aer_link <- read.csv('external_econ/aer_with_sample_selection_link_coding_harmonized.csv', stringsAsFactors = F) %>%
  select(doi, link_category) %>%
  mutate(journal = 'aer')
qje_link <- read.csv('external_econ/qje_link_coding_harmonized.csv', stringsAsFactors = F) %>%
  select(doi, link_category) %>%
  mutate(journal = 'qje')

link <- bind_rows(aer_link, qje_link) %>%
  mutate(link_category = ifelse(link_category == "", NA, link_category))

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
  group_by(journal, doi) %>%
  summarise(availability_link = max(availability_link))


# References --------------------------------------------------------------

## Import harmonized files
aer_reference <- read.csv('external_econ/aer_with_sample_selection_reference_coding_harmonized.csv', stringsAsFactors = F) %>%
  select(doi, reference_category) %>%
  mutate(journal = 'aer')
qje_reference <- read.csv('external_econ/qje_reference_coding_harmonized.csv', stringsAsFactors = F) %>%
  select(doi, reference_category) %>%
  mutate(journal = 'qje')

## Combine data from AER and QJE into a single dataframe
reference <- bind_rows(aer_reference, qje_reference)

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
reference_strict_levels <- c('link')
reference_easy_levels <- c('link', 'paper' ,'name')
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
  select(journal, doi, reference_what_how_much, reference) %>%
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
  ungroup()

## Create separate variables for 'strict' and 'easy' definition of availability
reference <- reference %>%
  separate(code_partial, paste0('reference_code_partial_', c('strict', 'easy'))) %>%
  separate(data_partial, paste0('reference_data_partial_', c('strict', 'easy'))) %>%
  separate(files_partial, paste0('reference_files_partial_', c('strict', 'easy'))) %>%
  separate(code_full, paste0('reference_code_full_', c('strict', 'easy'))) %>%
  separate(data_full, paste0('reference_data_full_', c('strict', 'easy'))) %>%
  separate(files_full, paste0('reference_files_full_', c('strict', 'easy')))


# File Extensions ---------------------------------------------------------

# File Extensions (from AEA website, only applicable to AER)
file_extensions <- read.csv('external_econ/aer_fileext_SZ.csv', stringsAsFactors = F) %>%
  select(doi, data, code) %>%
  mutate(journal = 'aer')

## Find highest level of availability
file_extensions <- file_extensions %>%
  mutate(availability_fileext_data = ifelse(data == TRUE, "data", "0")) %>% 
  mutate(availability_fileext_code = ifelse(code == TRUE, "code", "0")) %>%
  mutate(availability_fileext = case_when(
    data == TRUE & code == TRUE ~ "files",
    data == TRUE & code == FALSE ~ "data",
    data == FALSE & code == TRUE ~ "code",
    data == FALSE & code == FALSE ~ "0"
  )) %>%
  select(journal, doi, availability_fileext)


# Merge -------------------------------------------------------------------

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
aer_citation_count <- read.csv('external_econ/aer_citations_scopus.csv', stringsAsFactors = F) %>%
  mutate(journal = 'aer')
qje_citation_count <- read.csv('external_econ/qje_citations_scopus.csv', stringsAsFactors = F) %>%
  mutate(journal = 'qje')

## Values for title appear in both right-hand side and citation data. Choose value from right-hand side data.
citation_count <- bind_rows(aer_citation_count, qje_citation_count) %>%
  select(journal, doi, citation_count = citation)

df <- df %>%
  left_join(citation_count, by = c('journal', 'doi'))

# Order columns
df <- df %>% select(journal, publication_date, citation_count, doi, topic, data_type, title, author, abstract,
                    availability, starts_with('availability_'), starts_with('reference_'), institution)

# Fixing problem with publication date
df <- df %>%
  drop_na(publication_date)
for (i in 1:length(df$publication_date)) {
  if (nchar(df$publication_date[i]) == 7) {
    df$publication_date[i] = paste(df$publication_date[i], "01", sep = "/")
  }
}

# merge university ranking 
aer_university_rank <- read.csv('external_econ/article_author_top_rank_aer.csv', stringsAsFactors = F)
qje_university_rank <- read.csv('external_econ/article_author_top_rank_qje.csv', stringsAsFactors = F)
university_rank <- bind_rows(aer_university_rank, qje_university_rank)

df <- df %>%
  left_join(university_rank, by = "doi")
df$top_rank[is.na(df$top_rank)] <- 125

# Write dataframe to file
output_file <- 'external_econ/citations_clean_data.csv'
df %>% write.csv(output_file)
