Using the files `apsr_dataverse_search` and `ajps_dataverse_search`, please code the dataverse link of each article. Add your initials and save the file to Box.

Use the filter function for the `result_category` column and select only the _empty_ cells.

Create a new column with the title confirmed_category.

## What do I look for?
There are two things that you should loook for in the files:
1. `authors_apsr_toc` matches `dataverse_authors`

2. `title` matches `dataverse_name` - ignore "replication data for" in the `dataverse_name`

## How do I classify an article in the cofirmed_category?

1. `files`: `authors_apsr_toc` matches `dataverse_authors`, the `title` matches `dataverse_name`, and `dataverse_name` begins with "replication data for"

2. 'data`: `authors_apsr_toc` does not match `dataverse_authors` and/or the `title` does not match `dataverse_name`, and/or `dataverse_name` does not begin with "replication data for". Categorize it as `data` after checking the dataverse link.

3. `code`: `authors_apsr_toc` does not match `dataverse_authors` and/or the `title` does not match `dataverse_name`, and/or `dataverse_name` does not begin with "replication data for". Categorize it as `code` after checking the dataverse link.


Tip

Ctrl/⌘ + Click on the article title to open the article. You do not need to press Ctrl/⌘, if you uncheck Ctrl-click required to follow hyperlinks, which you can find in LibreOffice -> Preferences -> Security -> Options.
