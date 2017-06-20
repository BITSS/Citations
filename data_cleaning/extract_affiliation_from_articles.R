# Setup
library(tidyverse)
library(stringr)
library(rprojroot) # find project root
setwd(find_root('README.md'))

# AJPS
ajps <- read_csv('bld/ajps_articles_2006_2014.csv',
                 col_types = cols_only(doi = col_character(),
                                       title = col_character(),
                                       authors = col_character(),
                                       authors_description = col_character()))

## The manual entries will be used in regular expression, hence escape special characters
manual_authors = c('Samuel Merrill III',
                   'Darwin W. Miller, III',
                   'Edgar E. Ramirez De La Cruz',
                   'James M. Snyder, Jr\\.',
                   'James M. Snyder Jr\\.',
                   'Ekaterina Zhuravskaya',
                   'Jens Großer',
                   'Ernesto Reuben',
                   'Kenneth Benoit')

manual_affiliations = c('California State University, Los Angeles',
                        'London School of Economics and Political Science',
                        'California Institute of Technology',
                        'Centro de Investigación y Docencia Económicas',
                        'Washington University in St. Louis',
                        'Ak-Bidai Ltd.',
                        'Barcelona GSE',
                        'George Mason University',
                        "Institut d'Anàlisi Econòmica CSIC and Barcelona GSE",
                        'Peace Research Institute Oslo \\(PRIO\\)',
                        'University at Buffalo, SUNY',
                        'Stanford Graduate School of Business',
                        'Wilkes University',
                        'University of Florida',
                        'University of Maryland',
                        'University of Wisconsin-Madison',
                        'Massachusetts Institute of Technology',
                        'California State University, Fresno',
                        'Arizona State University',
                        'Hertie School of Governance',
                        'Instituto Tecnológico Autónomo de México',
                        'London School of Economics',
                        'Stanford GSB',
                        'Power System Engineering, Inc.',
                        'International University of Japan',
                        'United States Naval Academy',
                        'Uppsala University',
                        'Washington University in St. Louis',
                        'March Institute and University of Wisconsin-Madison',
                        'Michigan State University',
                        'Southern Illinois University',
                        'Princeton University',
                        'Duke University',
                        'Florida State College at Jacksonville',
                        'New York University',
                        'Stanford University',
                        'Columbia University',
                        "King's College London",
                        'Gardner-Webb University',
                        'Florida State University',
                        'Fundação Getúlio Vargas',
                        'Graduate Institute of International and Development Studies',
                        'ETH Zürich',
                        'Hebrew University of Jerusalem',
                        'University of Mannheim',
                        'Mills College',
                        'Hungarian Academy of Sciences',
                        'Yale University',
                        'Dickinson College',
                        'Public Policy Institute of California',
                        'Vanderbilt University',
                        'Harvard University',
                        'Northwestern University',
                        'Cornell University',
                        'University of Nottingham',
                        'Yale University',
                        'Academia Sinica',
                        'Aarhus University',
                        'Tel Aviv University',
                        'Tel-Aviv University',
                        'Stockholm School of Economics',
                        'Karolinska Institutet',
                        'Federal Reserve Bank of New York',
                        'Griffith University',
                        'Pennsylvania State University',
                        'Texas A&M University',
                        'Osaka University',
                        'Boston University',
                        'International Finance Corporation',
                        'Harvard University and NBER',
                        'National Public Radio',
                        'Georgetown University',
                        'Institute for Social Research',
                        'Roskilde University',
                        'Louisiana State University',
                        'Davidson College',
                        'University of Oslo',
                        'Centre for the Study of Civil War, PRIO',
                        'George Washington University',
                        'Essex University')

ajps_affiliation_manual_regex = paste(paste(paste0('(?<=^', manual_authors, ')[, ]*'), collapse = '|'),
                                      paste(paste0('[, ]*(?=', manual_affiliations, '[, ]*$)'), collapse = '|'),
                                      sep = '|')

ajps_affiliation_pattern_regex = paste('[, ]*(Close author notes|Corresponding author)[, ]*',
                                       '[, ]*(?=(The|Universi|College)[^$,])',
                                       ', ',
                                       "(?<=[[:alpha:]]{1,100} [[:alpha:]'\\-]{1,100}| [[:alpha:]]\\. [[:alpha:]']{1,100})[,\\s](?=[[:alpha:] '\\&]+ (University|College)$)",
                                       sep = '|')

ajps <- ajps %>% separate_rows(authors, sep = 'Search for more papers by this author') %>%
  filter(authors != '') %>%
  separate(authors, into = c('author_name_manual', 'author_affiliation_manual'), sep = ajps_affiliation_manual_regex,
           remove = FALSE, extra = 'merge') %>%
  separate(authors, into = c('author_name_pattern', 'author_affiliation_pattern'), sep = ajps_affiliation_pattern_regex,
           remove = FALSE, extra = 'merge') %>%
  mutate(author_name = if_else(is.na(author_affiliation_manual), author_name_pattern, author_name_manual),
         author_affiliation = if_else(is.na(author_affiliation_manual), author_affiliation_pattern, author_affiliation_manual))

# APSR
apsr <- read_csv('bld/apsr_article_content_2006_2014.csv',
                 col_types = cols_only(doi = col_character(),
                                       title = col_character(),
                                       authors = col_character(),
                                       authors_affiliations = col_character()))
apsr <- apsr %>% separate_rows(authors_affiliations, sep = ';') %>%
  filter(authors_affiliations != '')

# Combine journals
apsr <- apsr %>% mutate(journal = 'apsr') %>%
  rename(author_name = authors,
         author_affiliation = authors_affiliations)
ajps <- ajps %>% mutate(journal = 'ajps')

df <- bind_rows(ajps, apsr) %>%
  select(journal, doi, title, author_name, author_affiliation)

## Extract affiliations from authors with multiple affiliations
ajps <- ajps %>% separate_rows(author_affiliation, sep = paste(paste0('(?<=', paste(manual_affiliations, collapse = '|'), ') and '),
                                                               paste0(' and (?=', paste(manual_affiliations, collapse = '|'), ')'),
                                                               sep = '|'))

# Remove leading or trailing special characters
df <- df %>% mutate_at('author_affiliation', str_replace_all,
                 pattern = '^[, ]+|[, ]+$', replace = '')
df %>% write_csv('bld/article_author_affiliation.csv')
