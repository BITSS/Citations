library(tidyverse)
library(digest)

set.seed(42)
sample_rate = 0.25

aer <- read_csv('../data_collection_econ/pdf_to_txt/complete_aer.csv',
                col_types = cols(publication_date = col_date(format = '%Y/%m')))

aer <- aer %>%
  rowwise %>%
  mutate(hashed_doi = digest(doi, algo = 'md5', serialize = FALSE)) %>%
  group_by(journal, publication_date) %>%
  arrange(journal, publication_date, hashed_doi) %>%
  mutate(hash_rank = 1:n(),
         selected_into_sample = hash_rank <= ceiling(0.25 * n()))

aer %>% write_csv('../data_collection_econ/aer_with_sample_selection.csv')
