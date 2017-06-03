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
  mutate(topic = parse_factor(article_topic1, levels = article_topic_levels),
         data_type = parse_factor(article_data_type, levels = article_data_type_levels))

article_coding <- article_coding %>%
  select(journal, doi, title, abstract, topic, data_type)

# Author website
## Import harmonized files
ajps_author_website <- read_csv('data_entry/ajps_author_website_coding_harmonized.csv') %>%
  mutate(journal = 'ajps')
apsr_author_website <- read_csv('data_entry/apsr_author_website_coding_harmonized.csv') %>%
  mutate(journal = 'apsr')

## Combine data from AJPS and APSR into a single dataframe
author_website <- bind_rows(ajps_author_website, apsr_author_website)

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
ajps_dataverse <- read_csv('data_entry/ajps_dataverse_harmonized.csv') %>%
  mutate_at('issue_date', parse_date, format = '%B %Y') %>%
  mutate(journal = 'ajps')

apsr_dataverse <- read_csv('data_entry/apsr_dataverse_harmonized.csv') %>%
  mutate(journal = 'apsr')

## Combine data from AJPS and APSR into a single dataframe
dataverse <- bind_rows(ajps_dataverse, apsr_dataverse)

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
ajps_link <- read_csv('data_entry/ajps_link_coding_diff_resolution.csv') %>%
  mutate(journal = 'ajps')

apsr_link <- read_csv('data_entry/apsr_link_coding_RP.csv') %>%
  mutate(journal = 'apsr')

link <- bind_rows(ajps_link, apsr_link)

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
  mutate(availability_link = parse_factor(link_category_resolved, levels = availability_link_levels, ordered = TRUE, include_na = FALSE))

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
ajps_reference <- read_csv('data_entry/ajps_reference_coding_harmonized.csv') %>%
  mutate(journal = 'ajps')
apsr_reference <- read_csv('data_entry/apsr_reference_coding_harmonized.csv') %>%
  mutate(journal = 'apsr')
apsr_centennial_reference <- read_csv('data_entry/apsr_centennial_reference_coding_harmonized.csv') %>%
  mutate(journal = 'apsr_centennial')

## Combine data from AJPS and APSR and APSR Centennial into a single dataframe
reference <- bind_rows(ajps_reference, apsr_reference, apsr_centennial_reference)

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
  #drop_na(reference_what_how_much) %>%
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

# Merge article information
join_columns = c('journal', 'doi', 'title')
df <- article_coding %>%
  left_join(author_website, join_columns) %>%
  left_join(dataverse, join_columns) %>%
  left_join(link, join_columns) %>%
  left_join(reference, join_columns)

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
              mutate(availability = max(availability_website, availability_dataverse, availability_link, na.rm = TRUE) %>%
                       fct_recode('0' = 'NA')) %>%
              select(availability))

# Order columns
df <- df %>% select(journal, doi, title, abstract, topic, data_type,
                    availability, starts_with('availability_'), starts_with('reference_'))
