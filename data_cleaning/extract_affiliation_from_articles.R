# Setup
library(tidyverse)
library(stringr)
library(fuzzyjoin)
library(rprojroot) # find project root
setwd(find_root('README.md'))

# The manual entries will be used in regular expression, hence escape special characters
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
                        'University of California, Berkeley',
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
                        'Ohio State University',
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
                        'Essex University',
                        'Indiana University',
                        'Houston State University',
                        'Central Michigan University',
                        'Rutgers University',
                        'Rice University',
                        'Emory University',
                        'Marquette University',
                        'NBER',
                        'National Science Foundation',
                        'University of Georgia',
                        'European University Institute',
                        'Witherspoon Institute',
                        'University of Notre Dame',
                        'University of Wisconsin–Madison',
                        'Centre for Economic and Financial Research',
                        'Institute for Advanced Study, Princeton',
                        'Florida State University'
                        )

# AJPS
ajps <- read_csv('bld/ajps_articles_2006_2014.csv',
                 col_types = cols_only(doi = col_character(),
                                       title = col_character(),
                                       authors = col_character(),
                                       authors_description = col_character()))

ajps_affiliation_manual_regex = paste(paste(paste0('(?<=^', manual_authors, ')[, ]*'), collapse = '|'),
                                      paste(paste0('(?<![, ]{0,10}and[, ]{0,10})[, ]*(?=', manual_affiliations, '[, ]*$)'), collapse = '|'),
                                      sep = '|')

ajps_affiliation_pattern_regex = paste('[, ]*(Close author notes|Corresponding author)([, ]*|[A-Z])',
                                       '[, ]*(?=(The|Universi|College)[^$,])',
                                       ', ',
                                       "(?<=[[:alpha:]]{1,10} [[:alpha:]'\\-]{1,10}| [[:alpha:]]\\. [[:alpha:]']{1,10})[,\\s](?=[[:alpha:] '\\&]+ (University|College)$)",
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

affiliation <- bind_rows(ajps, apsr) %>%
  select(journal, doi, title, author_name, author_affiliation)

# Extract affiliations from authors with multiple affiliations
affiliation <- affiliation %>% separate_rows(author_affiliation, sep = paste(paste0('(?<=', paste(manual_affiliations, collapse = '|'), ') and '),
                                                               paste0('\\Wand\\W([Tt]he\\W){0,1}(?=', paste(manual_affiliations, collapse = '|'), ')'),
                                                               sep = '|'))

# Set some affiliations manually
manual_affiliation_mapping <- tribble(
  ~doi, ~author_name, ~manual_affiliation,
  '10.1111/j.1540-5907.2012.00589.x', 'Xiaobo Lü', 'Texas A&M University College Station',
  '10.1111/j.1540-5907.2012.00589.x', 'Kenneth Scheve', 'Yale University',
  '10.1111/j.1540-5907.2011.00568.x', 'Peter K. Hatemi', 'Pennsylvania State University University Park',
  '10.1111/j.1540-5907.2012.00574.x', 'Deniz Aksoy', 'Princeton University',
  '10.1111/ajps.12015', 'Jens Großer,Florida State', 'Princeton University',
  '10.1111/ajps.12015', 'Jens Großer,Florida State', 'Florida State University',
  '10.1111/ajps.12032', 'Jens Großer,Corresponding authorFlorida State University and Institute for Advanced Study, Princeton Jens Großer, Florida State University and Institute for Advanced Study, Princeton,Thomas R. Palfrey', 'Princeton University',
  '10.1111/ajps.12032', 'Jens Großer,Corresponding authorFlorida State University and Institute for Advanced Study, Princeton Jens Großer, Florida State University and Institute for Advanced Study, Princeton,Thomas R. Palfrey', 'Florida State University',
  '10.1017/S0003055408080027', 'SCOTT SIGMUND GARTNER', 'University of California, Davis',
  '10.1111/j.1540-5907.2007.00312.x', 'Miriam A. Golden', 'University of California at Los Angeles',
  '10.1111/j.1540-5907.2009.00388.x', 'Donald Wittman', 'University of California, Santa Cruz',
  '10.1111/j.1540-5907.2010.00475.x', 'Branislav L. Slantchev', 'University of California, San Diego',
  '10.1017/S0003055406062022', 'MATIAS IARYCZOWER;PABLO T. SPILLER;MARIANO TOMMASI', 'University of California, Berkeley',
  '10.1017/S0003055406062034', 'TIMOTHY R. JOHNSON;PAUL J. WAHLBECK;JAMES F. SPRIGGS', 'University of California, Davis',
  '10.1017/S0003055406062095', 'ROBERT PEKKANEN;BENJAMIN NYBLADE;ELLIS S. KRAUSS', 'University of California, San Diego',
  '10.1017/S0003055406062101', 'CHERIE D. MAESTAS;SARAH FULTON;L. SANDY MAISEL;WALTER J. STONE', 'University of California, Davis',
  '10.1017/S0003055406062265', 'JAMES ADAMS;SAMUEL MERRILL', 'University of California—Davis',
  '10.1017/S0003055407070116', 'KEVIN M. ESTERLING', 'University of California, Riverside',
  '10.1017/S0003055407070244', 'ROBERT POWELL', 'University of California, Berkeley',
  '10.1017/S0003055407070438', 'THOMAS CHAPMAN;PHILIP G. ROEDER', 'University of California, San Diego',
  '10.1017/S0003055407070499', 'JAMES HABYARIMANA;MACARTAN HUMPHREYS;DANIEL N. POSNER;JEREMY M. WEINSTEIN', 'University of California, Los Angeles',
  '10.1017/S0003055407070530', 'ROBERT POWELL', 'University of California, Berkeley',
  '10.1017/S0003055408080040', 'MICHAEL L. ROSS', 'University California, Los Angeles',
  '10.1017/S0003055408080064', 'SAMUEL MERRILL;BERNARD GROFMAN;THOMAS L. BRUNELL', 'University of California, Irvine',
  '10.1017/S0003055408080106', 'SIMEON NICHTER', 'University of California, Berkeley',
  '10.1017/S0003055408080209', 'JAMES H. FOWLER;LAURA A. BAKER;CHRISTOPHER T. DAWES', 'University of California, San Diego',
  '10.1017/S0003055408080374', 'SCOTT DESPOSATO;ETHAN SCHEINER', 'University of California, San Diego',
  '10.1017/S0003055408080374', 'SCOTT DESPOSATO;ETHAN SCHEINER', 'University of California, Davis',
  '10.1017/S0003055409090078', 'ZOLTAN L. HAJNAL', 'University of California, San Diego',
  '10.1017/S0003055410000109', 'THOMAS G. HANSFORD;BRAD T. GOMEZ', 'University of California–Merced',
  '10.1017/S0003055410000596', 'HENRY E. BRADY;JOHN E. MCNULTY', 'University of California, Berkeley',
  '10.1017/S0003055411000542', 'JASJEET S. SEKHON;ROCÍO TITIUNIK', 'University of California at Berkeley',
  '10.1017/S0003055412000378', 'BRANISLAV L. SLANTCHEV', 'University of California at San Diego',
  '10.1017/S000305541300004X', 'ERIK J. ENGSTROM;JESSE R. HAMMOND;JOHN T. SCOTT', 'University of California, Davis',
  '10.1017/S0003055413000063', 'JAMES H. FOWLER;CHRISTOPHER T. DAWES', 'University of California, San Diego',
  '10.1017/S0003055413000245', 'HENRY A. KIM;BRAD L. LEVECK', 'University of California, San Diego',
  '10.1017/S0003055413000300', 'ROBERT S. TAYLOR', 'University of California, Davis',
  '10.1017/S0003055413000397', 'GERALD GAMM;THAD KOUSSER', 'University of California, San Diego',
  '10.1017/S0003055413000609', 'SHALINI SATKUNANANDAN', 'University of California, Davis',
  '10.1017/S0003055414000215', 'JOHN T. SCOTT', 'University of California, Davis'
)

affiliation <- affiliation %>% left_join(manual_affiliation_mapping, by = c('doi', 'author_name')) %>%
  mutate(author_affiliation = ifelse(is.na(manual_affiliation), author_affiliation, manual_affiliation))

# Remove leading or trailing uninformative characters
affiliation <- affiliation %>% mutate_at('author_affiliation', str_replace_all,
                 pattern = '^\\W+|\\W+$', replace = '')

# Prepare for join of article author affiliation with ranking
ranking <- read_csv('external/uni_ranking.csv',
                    locale = locale(encoding = 'windows-1252'))

ranking <- ranking %>%
  separate(university, into = c('university', 'location'), sep = '\n', extra = 'merge') %>%
  mutate_at(c('university', 'location'), str_trim)

## Simplify university names for improved fuzzy join
preposition_pattern = '[[:punct:]]\\W|\\W[[:punct:]]|^The\\W|\\W(the|of|at|—?)(?=\\W)|[:space:](?=[:space:])'

ranking <- ranking %>%
  mutate(affiliation_join = str_replace_all(university,
                                            pattern = preposition_pattern,
                                            replacement = ' '))

affiliation <- affiliation %>%
  mutate(affiliation_join = str_replace_all(author_affiliation,
                                            pattern = preposition_pattern,
                                            replacement = ' '))

affiliation_recodings = tribble(
  ~affiliation_join, ~affiliation_join_recode,
  'University Michigan', 'University Michigan Ann Arbor',
  'Texas A&M University', 'Texas A&M University College Station',
  'Indiana University', 'Indiana University Bloomington',
  'University Maryland', 'University Maryland College Park',
  'Pennsylvania State University', 'Pennsylvania State University University Park',
  'University Minnesota Twin Cis', 'University Minnesota Twin Cities',
  'University Minnesota', 'University Minnesota Twin Cities',
  'Rutgers The State University New Jersey New Brunswick', 'Rutgers University',
  'University Minnesota Law School', 'University Minnesota Twin Cities',
  'Louisana State University', 'Louisiana State University Baton Rouge',
  'Stanford Graduate School Business', 'Stanford University',
  'Stanford GSB', 'Stanford University',
  'University Nebraska', 'University Nebraska Lincoln',
  'University Missouri', 'University Missouri Columbia',
  'University Tennessee', 'University Tennessee Knoxville',
  'CUNY Graduate School and University Center', 'City University New York',
  'Baruch College and Graduate Center City University New York', 'City University New York',
  'Harvard Law School', 'Harvard University',
  'Harvard Business School', 'Harvard University',
  'UCLA', 'University California Los Angeles',
  'University Colorado', 'University Colorado Boulder',
  'Purdue University', 'Purdue University West Lafayette',
  'Binghamton University', 'Binghamton University SUNY',
  'Stony Brook University', 'Stony Brook University SUNY',
  'University New York–Stony Brook', 'Stony Brook University SUNY',
  'University Buffalo', 'University Buffalo SUNY',
  'Massachusetts Institute Technology MIT', 'Massachusetts Institute Technology',
  'Brook University', 'Stony Brook University SUNY',
  'Northwestern University School Law', 'Northwestern University',
  'University North Carolina', 'University North Carolina Chapel Hill',
  'University Texas', 'University Texas Austin',
  'University Washington–Seattle', 'University Washington',
  'University Wisconsin', 'University Wisconsin Madison',
  'Washington University', 'Washington University in St Louis'
  )

ranking <- ranking %>%
  stringdist_left_join(affiliation_recodings, by = 'affiliation_join',
                                  max_dist = 1, method = 'lcs') %>%
  mutate(affiliation_join = ifelse(is.na(affiliation_join_recode),
                                   affiliation_join.x,
                                   affiliation_join_recode))

affiliation <- affiliation %>%
  stringdist_left_join(affiliation_recodings, by = 'affiliation_join',
                       max_dist = 2, method = 'lcs') %>%
  mutate(affiliation_join = ifelse(is.na(affiliation_join_recode),
                                   affiliation_join.x,
                                   affiliation_join_recode))

## Join article author affiliation with ranking
df <- affiliation %>%
  stringdist_left_join(ranking, by = 'affiliation_join',
                       max_dist = 3, distance_col = 'join_string_distance',
                       method = 'lcs') %>%
  arrange(join_string_distance) %>%
  distinct(doi, title, author_name, author_affiliation, .keep_all = TRUE) %>%
  arrange(journal, doi, title, author_name)

# Find top ranked author
df <- df %>% group_by(journal, doi, title) %>%
  mutate(top_rank = max(ranking, na.rm = TRUE)) %>%
  distinct(.keep_all = TRUE) %>%
  select(journal, doi, title, top_rank)

df %>% write_csv('bld/article_author_top_rank.csv')
