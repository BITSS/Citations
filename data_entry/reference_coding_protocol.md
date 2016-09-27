## Coding Protocol for Automated Text Search
Version: 2016.09.29 (See [github](http://github.com/bitss/citations) for history.)

### What do I look for?
References to the data or code used in the article.

### What is a reference?
A reference has 3 dimensions:

1. What is referenced?

  It must be one of the following.
 + `data`
 + `code`
 + `files` = data + code

2. How much is referenced?

  If the referenced data or code is for the entire article, it is a `full` reference. A reference for part of the data or code, e.g. only for a single variable, it is called `partial` reference.

3. How is it referenced?

 + `link`: The reference provides a URL
 + `name`: The reference mentions the name of a dataset, an institution or website without providing a URL
 + `paper`: The reference is a citation to a paper.

### How do I classify the matches?
If a match is not a reference to the data or code used in the article, it is irrelevant. We code this as `0`.

If a match is a reference, classify it along the 3 dimension mentioned above using underscores `_` as separators. If a reference is partial, add `partial`.

In total there are 13 possible values. Some selected examples:

+ `data_full_link`: Reference provides a URL to *all* of the data used in the article
+ `data_partial_link`: Reference provides a URL to parts of the data, e.g. certain variables, used in the article
+ `data_partial_name`: Reference mentions the name where parts of the data can be found, e.g. some variables are provided by an institution
+ `code_partial_link`: Reference provides a URL to some of the code used in the article, e.g. for code used in simulation, but not for code used in analysis
+ `files_full_name`: Reference mentions a location where both, data and code, can be found, e.g. the author's website
+ ...

### Where do I save my file?
Start with the template in `./Shared/Data/ajps_reference_coding_template.xlsx`, create a copy, replacing 'template' with your name.
Use LibreOffice Calc to open and save the file in `.ods` format.
After a day's work upload the latest version of your file to the Box folder. (Or use Box Sync.)

### Tip
For faster data entry, you can label irrelevant matches using a key close to your `enter` key, and replace that character with `0` later on.
