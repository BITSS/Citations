### What do I look for?
Find out if the website of the authors' of a paper have any data, code or files that relate to it.

### How do I classify an author's website?
1. Click on the author's name to obtain the first 15 search results (non-personalized) from Google.
2. Look for the author's website among these results. The university affiliation can help you identify the author, but might also have changed after the paper's publication.
3. If you think you found an author's website, confirm it by finding a reference to the paper. A good starting point is the CV, where many authors list their papers.
4. If you have found and confirmed an author's website, put the URL into the `website` column. 
5. Look through the whole website to find a reference to data, code or files of the paper. Put your result as `0`, `data`, `code` or `files` into the `website_category` column. If you find a reference, but it is broken, code it as `data_dead`, `code_dead` or `files_dead`.

### What if I do not find the author's website in the first 15 search results?
Add `research` to the search term, and repeat from step 1.

If that also does not find you the author's website, put `could_not_find` into the `website_category` column. 

### Some author names look weird
The extraction of author names is done automatically. Sometimes this will result in author names that are actually not names or repetition of names in slightly different variants (e.g. `James H. Fowler` and `James H. FowlerUniversity of California`). If an author name is clearly not a name or you have already previously looked for an author **in the same article**, you can put `skip` into the `website_category` column.

### What if there is more than one relevant website (e.g. university and personal)?
Search through all of them. Report the one that gives you the best reference to data, code or files into the `website` column. If more than one does, report the most personal/recent website.

### Tip
`Ctrl/⌘ + Click` on the link to open it in your browser, `Ctrl/⌘ + Click` on the article title to open the article. You do not need to press `Ctrl/⌘`, if you uncheck `Ctrl-click required to follow hyperlinks`, which you can find in `LibreOffice` -> `Preferences` -> `Security` -> `Options`.
