Using the files `apsr_dataverse_search` and `ajps_dataverse_search`, please code the dataverse link of each article. Add your initials and save the file to Box.

Use the filter function for the `result_category` column and select only the _empty_ cells.

Create a new column with the title confirmed_category.

## What do I look for?
There are two things that you should loook for in the files:

1. `authors_apsr_toc` matches `dataverse_authors`

2. `title` matches `dataverse_name` - ignore "replication data for" in the `dataverse_name`

## How do I classify an article in the cofirmed_category?

1. If `authors_apsr_toc` matches `dataverse_authors` and the `title` matches `dataverse_name`or `dataverse_name` begins with "replication data for", then code as `files`. (Essentially there's a dataverse with the same authors and title as the paper, only a minor punctuation difference.)

2. If `authors_apsr_toc` does not match `dataverse_authors` but the `title` matches `dataverse_name`, follow the link. If the data and/or code there are replication data/code for the *original* intended article (not the one that comes up for whatever reason in the Dataverse search) then classify the dataverse link as  `none`, `data`, `code`, or `files` according to the normal rules.  

3. If `authors_apsr_toc` matches `dataverse_authors` but the `title` does not match `dataverse_name`, follow the link. If the data and/or code there are replication data/code for the *original* intended article (not the one that comes up for whatever reason in the Dataverse search) then classify the dataverse link as `none`, `data`, `code`, or `files` according to the normal rules.

4. If `authors_apsr_toc` does not match `dataverse_authors` *and* the `title`does not match `dataverse_name` *or* after following the link from one of the situations above, dataverse contains neither data nor code for the *original* article.


Tip

Ctrl/⌘ + Click on the article title to open the article. You do not need to press Ctrl/⌘, if you uncheck Ctrl-click required to follow hyperlinks, which you can find in LibreOffice -> Preferences -> Security -> Options.
