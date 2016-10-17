### What do I look for?
Follow each link to look for data or code that relates to the reference mentioned in the paper.

### How do I classify the links?
Every link should fall into one of the following categories:

+ `dead`: The link gives you an error such as `Page not found` or `404 Error`, or does not resolve at all (in the last case double-check your internet/WiFi connection!)
+ `redirect_to_general`: The link redirects to a website **not tied to the author or paper** (e.g. main university website). Such a redirect will also have a different URL.
+ `could_not_find`: The link leads to a website tied to the author or paper, but even after searching through this website, the mentioned data/code/files could not be found. 
+ `restricted_access`: Registration, special library access or a password is required to access the contents of the link.
+ `data`: The link leads to the data mentioned in the reference.
+ `code`: The link leads to the code mentioned in the reference.
+ `files` = `data` + `code`

### The URL looks weird
The list of URLs was generated automatically. Sometimes, the URL detection algorithm is too greedy and thereby breaks a URL. For example `http://web.mit.edu/17.251/www/data_page.html.16Many` (does not work) should actually be `http://web.mit.edu/17.251/www/data_page.html` (does work), but the algorithm did not detect the end of the sentence after `html`.

If link still seems `dead` or `redirect_to_general`, we ask you to inspect every URL for such weirdness, and manually try to find the correct URL, as follows:
1. Remove weird looking characters at the end of the URL
2. If link still seems `dead` or `redirect_to_general`, then go up one folder (that is remove characters from the end until the next `/`) and try again.
3. Repeat 2. until you reach the top level domain such as `.com` or `.edu`.

If you find a working URL with this procedure, enter the working URL into the `fixed_link` column.

#### Example
+ `http://www.stat.washington.edu/hoff/CODE/GBME/.14We` seems `dead`.
+ Following step 1, remove `.14We` and try `http://www.stat.washington.edu/people/pdhoff/CODE/GBME/`

+ .. which also seems `dead`. Following step 2, go up one folder by removing `GBME/` and try `http://www.stat.washington.edu/people/pdhoff/CODE/`

+ .. which also seems `dead`. Repeat step 2, by removing `CODE/` and try `http://www.stat.washington.edu/people/pdhoff/`

+ .. which leads to a working homepage with `code` and `data` available.

### Where do I save my file?
Start with the template in `./Shared/Data/ajps_link_coding_template.ods`, create a copy, replacing `template` with your initials.
Use LibreOffice Calc to open and save the file in `.ods` format.
After a day's work upload the latest version of your file to the Box folder. (Or use Box Sync.)

### Tip
`Ctrl/⌘ + Click` on the link to open it in your browser (`Ctrl/⌘ + Click` on the title will open the article). You do not need to press `Ctrl/⌘`, if you uncheck `Ctrl-click required to follow hyperlinks` in `LibreOffice` -> `Preferences` -> `Security` -> `Options`.
