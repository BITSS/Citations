### What do I look for?
Use AutoFilter to select all references that are `data_full_link`, `code_full_link` or `files_full_link`. Follow each link to look for the data/code/files referenced in the paper.

### How do I classify the links?
Every link should fall into one of the following categories:

+ `dead`: The link gives you an error such as `Page not found` or `404 Error`, or does not resolve at all (in the last case double-check your internet/WiFi connection).
+ `redirect_to_general`: The link redirects to a website **not tied to the author or paper** (e.g. main university website). Such a redirect will also have a different URL.
+ `could_not_find`: The link leads to a website tied to the author or paper, but even after searching through this website, the referenced data/code/files could not be found. This includes the case, where you it looks like you found the right link on the website, but that one is `dead` or does not contain any of the referenced data/code/files.
+ `restricted_access`: Registration, special library access or a password is required to access the referenced data/code/files of the link.
+ `data`: The link leads to the referenced data.
+ `code`: The link leads to the referenced code.
+ `files` = `data` + `code`

### The URL looks weird
The list of URLs was generated automatically. Sometimes, the URL detection algorithm is too greedy and thereby breaks a URL. For example

`http://web.mit.edu/17.251/www/data_page.html.16Many` (does not work)

should actually be

`http://web.mit.edu/17.251/www/data_page.html` (does work),

but the algorithm did not detect the end of the sentence after `html`.

### Rescue a `dead` or `redirect_to_general` link
If and only if a link seems `dead` or `redirect_to_general`, manually try to find the correct URL, as follows:

1. Remove weird looking characters at the end of the URL
2. If the link still seems `dead` or `redirect_to_general`, then go up one folder (that is remove characters from the end until the next `/`) and try again.
3. Repeat 2. until you find a working URL or reach the top level domain such as `.com` or `.edu`.

If all URLs from above procedure still seem `dead` or `redirect_to_general`, keep the original label.

If you do find a URL from above procedure that is neither `dead` nor `redirect_to_general`, enter that working URL into the `fixed_link` column. Use the first working URL, not the URL that ultimate links to the data/code/files.

Then search for the data/code/files starting from the working URL.

#### Example
+ `http://ms.cc.sunysb.edu/~mlebo/details.htm.10It` redirects to `https://sites.google.com/a/stonybrook.edu/matthew-lebo/details.htm.10It` which seems `dead`.
+ Following step 1, remove `.10It` and try `https://sites.google.com/a/stonybrook.edu/matthew-lebo/details.htm`
+ .. which also seems `dead`. Following step 2, go up one folder by removing `details.htm` and try `https://sites.google.com/a/stonybrook.edu/matthew-lebo/`
+ .. which leads to a working website that is tied to the author or paper.
+ Enter `https://sites.google.com/a/stonybrook.edu/matthew-lebo/` into `fixed_link`.
+ Look for the referenced data/code/files in `https://sites.google.com/a/stonybrook.edu/matthew-lebo/`
+ Starting from the working URL, the referenced files can be found under the `Papers` section, so code this link as `files`.

### Where do I save my file?
Start with the template in `./Shared/Data/ajps_link_coding_template.ods`, create a copy, replacing `template` with your initials.
Use LibreOffice Calc to open and save the file in `.ods` format.
After a day's work upload the latest version of your file to the Box folder. (Or use Box Sync.)

### Tip
`Ctrl/⌘ + Click` on the link to open it in your browser, `Ctrl/⌘ + Click` on the article title to open the article. You do not need to press `Ctrl/⌘`, if you uncheck `Ctrl-click required to follow hyperlinks`, which you can find in `LibreOffice` -> `Preferences` -> `Security` -> `Options`.
