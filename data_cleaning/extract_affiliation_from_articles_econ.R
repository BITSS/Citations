library(tidyverse)

preposition_pattern = '[[:punct:]]\\W|\\W[[:punct:]]|^The\\W|\\W(the|of|at|—?)(?=\\W)|[:space:](?=[:space:])|—'

df_ranking_econ <- read.csv("bld/econ_uni_rankings.csv", stringsAsFactors = F, encoding="UTF-8") %>%
  select(university, ranking) %>%
  mutate(
    university_formatted = str_replace_all(university,
                                           pattern = preposition_pattern,
                                           replacement = ' ')
  )

df_aer <- read.csv("bld/indexed_aer.csv", stringsAsFactors = F, encoding="UTF-8") %>%
  select(index, doi, author, title, institution) %>%
  mutate(institution = ifelse(author == "Blau, Francine D.", "Cornell University", institution)) %>%
  select(-author) %>%
  separate(institution, paste0("inst", 1:10), sep = " / ", extra = "warn") %>%
  gather("value", "university", 4:13) %>%
  mutate(
    university = recode(university,
                        "University of Michigan" = "University of Michigan Ann Arbor",
                        "University of Wisconsin" = "University of Wisconsin Madison",
                        "University of Minnesota" = "University of Minnesota Twin Cities",
                        "Carnegie Mellon University" = "Carnegie Mellon University (Tepper)",
                        "University of Texas at Austin" = "University of Texas—Austin",
                        "Purdue University" = "Purdue University—West Lafayette (Krannert)",
                        "University of Illinois at Urbana-Champaign" = "University of Illinois—Urbana-Champaign",
                        "University of Wisconsin-Madison" = "University of Wisconsin—Madison",
                        "Pennsylvania State University" = "Pennsylvania State University—University Park",
                        "Rutgers University" = "Rutgers, The State University of New Jersey—New Brunswick",
                        "University of Iowa" = "University of Iowa (Tippie)",
                        "Indiana University" = "Indiana University—Bloomington",
                        "University of Kentucky" = "University of Kentucky (Gatton)",
                        "University of Nebraska-Lincoln" = "University of Nebraska—Lincoln",
                        "University of North Carolina at Chapel Hill" = "University of North Carolina—Chapel Hill",
                        "North Carolina State University" = "North Carolina State University—Raleigh",
                        "University of Wisconsin-Milwaukee" = "University of Wisconsin—Milwaukee",
                        "Clemson University" = "Clemson University (Walker)",
                        "Louisiana State University" = "Louisiana State University—Baton Rouge",
                        "University of New York, Stony Brook" = "Stony Brook University—SUNY",
                        "University of North Carolina, Chapel Hill" = "University of North Carolina—Chapel Hill",
                        "Northwesterm University" = "Northwestern University",
                        "University of Georgia" = "University of Georgia (Terry)"
    )
  ) %>%
  mutate(
    university_formatted = str_replace_all(university,
                                           pattern = preposition_pattern,
                                           replacement = ' '),
    university_formatted = str_replace_all(university_formatted,
                                           pattern = "<U\\+00A0>",
                                           replacement = '')
    ) %>%
  left_join(df_ranking_econ, by = "university_formatted") %>%
  group_by(doi) %>%
  summarise(top_rank = min(ranking, na.rm = T)) %>%
  mutate(top_rank = ifelse(top_rank == Inf, NA, top_rank))

df_qje <- read.csv("bld/indexed_qje_institution.csv", stringsAsFactors = F, encoding="UTF-8") %>%
  select(index, doi, title, institution) %>%
  separate(institution, paste0("inst", 1:15), sep = " / ", extra = "warn") %>%
  gather("value", "university", 4:13) %>%
  mutate(
    university = recode(university,
                        "University of California at Berkeley" = "University of California, Berkeley",
                        "University of Maryland" = "University of Maryland—College Park",
                        "University of Michigan" = "University of Michigan—Ann Arbor",
                        "Harvard" = "Harvard University",
                        "Stanford" = "Stanford University",
                        "UCLA" = "University of California, Los Angeles",
                        "University of California-Berkeley" = "University of California, Berkeley",
                        "University of California-Los Angeles" = "University of California, Los Angeles",
                        "University of California at Santa Barbara" = "University of California, Santa Barbara",
                        "University of Georgia" = "University of Georgia (Terry)",
                        "Carnegie Mellon University" = "Carnegie Mellon University (Tepper)",
                        "Harvard Business School" = "Harvard University",
                        "MIT" = "Massachusetts Institute of Technology",
                        "Penn State University" = "Pennsylvania State University—University Park",
                        "Pennsylvania State University" = "Pennsylvania State University—University Park",
                        "UC Berkeley" = "University of California, Berkeley",
                        "UC San Diego" = "University of California, San Diego",
                        "University of California at Los Angeles" = "University of California, Los Angeles",
                        "University of California at San Diego" = "University of California, San Diego",
                        "University of Colorado" = "University of Colorado—Boulder",
                        "University of Minnesota" = "University of Minnesota—Twin Cities",
                        "University of Wisconsin-Madison" = "University of Wisconsin—Madison",
                        "Yale" = "Yale University",
                        "Yale School of Management" = "Yale University",
                        "University of Chicago" = "University of Chicago",
                        "Abdul Latif Jameel Poverty Action Lab" = "Massachusetts Institute of Technology",
                        "Columbia Business School" = "Columbia University",
                        "University of Wisconsin at Madison" = "University of Wisconsin—Madison",
                        "M.I.T." = "Massachusetts Institute of Technology",
                        "Poverty Action Lab" = "Massachusetts Institute of Technology",
                        "Rutgers University" = "Rutgers, The State University of New Jersey—New Brunswick",
                        "State University of New York at Binghamton" = "Binghamton University—SUNY",
                        "State University of New York at Stony Brook" = "Stony Brook University—SUNY",
                        "The Johns Hopkins University" = "Johns Hopkins University",
                        "The Wharton School" = "University of Pennsylvania",
                        "University of California-Santa Cruz" = "University of California, Santa Cruz",
                        "University of California at Davis" = "University of California, Davis",
                        "University of California,Los Angeles" = "University of California, Los Angeles",
                        "Washington University, St. Louis" = "Washington University in St. Louis"
                        )
  ) %>%
  mutate(
    university_formatted = str_replace_all(university,
                                           pattern = preposition_pattern,
                                           replacement = ' '),
    university_formatted = str_replace_all(university_formatted,
                                           pattern = "<U\\+00A0>",
                                           replacement = '')
  ) %>%
  left_join(df_ranking_econ, by = "university_formatted") %>%
  group_by(doi) %>%
  summarise(top_rank = min(ranking, na.rm = T)) %>%
  mutate(top_rank = ifelse(top_rank == Inf, NA, top_rank))

# View(df_qje %>% 
#        filter(is.na(ranking)) %>% 
#        select(university.x, university_formatted) %>% 
#        group_by(university.x, university_formatted) %>%
#        summarise(n = n()) %>%
#        arrange(-n))
# 
# View(unique(df_ranking_econ$university_formatted))

write.csv(df_aer, "bld/article_author_top_rank_aer.csv", row.names = F)
write.csv(df_qje, "bld/article_author_top_rank_qje.csv", row.names = F)