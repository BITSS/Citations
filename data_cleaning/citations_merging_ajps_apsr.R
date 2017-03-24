setwd("/Users/Terri/Dropbox/URAP")

ajps_type_topic <- read.csv("ajps_article_coding_harmonized.csv")

apsr_type_topic <- read.csv("apsr_article_coding_harmonized.csv")

#binding the apsr and ajps files onto one df.
library(dplyr)
library(tidyr)
main.df <- bind_rows(ajps_type_topic, apsr_type_topic)

#changing levels: removing skips and blanks as levels 
topic_levels <- c("political_theory","american_government_and_politics","political_methodology","international_relations","comparative_politics")
main.df$article_topic1 <- factor(main.df$article_topic1, levels = topic_levels)

data_type_levels <- c("experimental", "observational", "simulations", "")
main.df$article_data_type <- factor(main.df$article_data_type)

#data availability 
ajps_author_website <- read.csv("ajps_author_website_coding_harmonized.csv")
apsr_author_website <- read.csv("apsr_author_website_coding_harmonized.csv")

author_web <- bind_rows(ajps_author_website, apsr_author_website)

# combining factor levels 
library(car)

author_web$website_category <- factor(author_web$website_category)

author_web$website_category <- recode(author_web$website_category, "c('data_dead', 'code_dead', 'files_dead')='dead'")

#ordering factor levels 
author_web$website_category <- factor(author_web$website_category, 
                                      levels = c("files", "data", "code",
                                                 "dead", "0", "could_not_find", "skip"))

y <- factor(author_web$website_category, levels = c("skip", "could_not_find", "0", "dead", "code", 
                                                    "data", "files"))
          



