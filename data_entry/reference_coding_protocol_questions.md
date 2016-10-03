# Questions

Please provide a specific article or row number as an example that illustrates your question.

### Ravina

  1. Several articles have referred us to supporting information section on the AJPS website for code/dataset/statistical analysis. Sometimes a link or a .doc. How do we classify this? In the mean time, Terri and I have classified it as `supp_info`.

  A: If it's not data or code to enable one to redo the same analysis that was conducted in the paper, we're not interested. Supplementary info like extra results, extra tables, the questionnaires used for the surveys, mathematical proofs, etc. aren't what we're looking for. Just call these `link`.
  
  2. There are a lot of Dataverse links. Are those `files` or `data`. 
  
  A: Those are mostly exactly what we're looking for. Unless they're quite explicit about it, it's almost certainly `files` and not just `data`. (Don't spend much time differentiating!)

### Kevin
  1. What if the excerpt includes a reference to a URL but not the explicit URL? How would we code this? `Row.283 racial predispositions. Models include control variables as discussed in text; complete results are AVAILABle from the author's web page.`

  A: This specific example is a reference to results, so it's a zero. However, author's web page (without a URL) should count as a `name`.

  2. Row 336-340
  What if several records are made for the same excerpt?  Wouldn't coding these records skew the data when we make the analysis, perhaps in a statistically significant way? How would we remedy this problem?

  A: Not an issue statistically, as we'll eventually boil all this down to a 0/1 for each article.

  3. Row 431 "also Erikson, MacKuen, and Stimson 2002) for a discussion of these issues."

	Would we code excerpts that cite other authors as "data_partial_name" or because these authors are not linked to a dataset, insitution, or website explicity, we would code them as NULL values.

  A: Again, this probably isn't a reference to data, so it's probably a zero. We're only interested in data, not methods (unless that means code). But in general a reference can point to a `link`, `name`, or `paper`.

  4. Row 437. "y of incumbent politicians to run an electoral cycle in fiscal balance. Section three describes the DATA used in the empirical analysis. Section four presents the empirical specifications employed as well"

	How do we treat excerpts that make references to specific parts of the data, without referencing any of the valid entities needed to code it as "data".

  A: This is an internal reference to part of the paper. It's a zero. We're looking for places people can download the exact dataset used in the paper.

  5. Row 650-656x
	How should we treat references to other authors in the Political Theory articles? Not many explicit mention of datasets, institutions, or websites, but many references to famous Political Theorists such as Rawls, Machiavelli,etc.

  A: We don't care about theory.

  6. Row 1331. "els of Tables 2 and 3 nor the significance of the black representation variables (these results are AVAILABle upon request). However, the metropolitan a=rea dummies did alter the results in Table 4, so here t"

	How do we code self-referential excerpts?

  A: We don't care about results. Also, 'available upon request' is a zero, even if it were for data or code.

### Terri
  1. There's an article that kept mentioning that additional analyses were available on the author's webpage, however there was no mention of the code or data being availble. I happened to check the journal and noticed that on the web page it says that all files can be found at that link. However, since it was written on the web page and not in the pdf, it did not show up in our file. (Journal Article #257 "What Stops the Torture").

  A: Good find! David is adding those notes to the data template and we'll let you know when we do that.
  
  2. If we find a data full link do we still have to record partials after that while we're looking for code links? (The protocol only mentions skipping after a files full link.)
  
  A: If you find a data full link, skip all other data references. Same goes for code.

### Rachel
  1. What if data reference is a cite of a paper? (not link/name)

  A: create a new option: paper.

  Thank you for answering my questions.
