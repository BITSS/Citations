library(RSelenium)
library(rvest)
library(magrittr)
library(foreach)

# Prior to run the next two lines of code to start the remoteDriver
# Please make sure to cd to this folder and run this next line of code in the terminal
# java -jar selenium-server-standalone-3.3.1.jar            
remDr <- remoteDriver(port=4444)
remDr$open()

# Main function to search on webofknowledge by doi 
search <- function(doi) {
  
  remDr$navigate("http://www.webofknowledge.com")
  
  # click on the clear button in case there is previous search entry
  clearEle = remDr$findElements(using='id', value='clearIcon1')
  if (length(clearEle)<1){
    remDr$navigate("http://www.webofknowledge.com")
  } 
  clearEle = remDr$findElement(using='id', value='clearIcon1')
  clearEle$clickElement()
  
  # in dropdown menu for search criteria chose the element "doi"
  dropEle = remDr$findElement(using='id', value= 'select2-select1-container')
  chosen = unlist(dropEle$getElementText())
  
  if (chosen != 'DOI') {
    dropEle$clickElement()
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "enter"))  
  }
  
  # enter doi number in the input field
  inputEle = remDr$findElement(using='id', value = 'value(input1)')
  inputEle$sendKeysToElement(list(doi,key="enter"))
  
  # wait for 5 seconds to make sure that the page has fully loaded
  Sys.sleep(5) 
  
  # get citation number:
  citationEle <-remDr$findElements(using='class',value='search-results-data-cite')
  if (length(citationEle)<1) {
    result = NA
  } else {
    citationEle <-remDr$findElement(using='class',value='search-results-data-cite')
    result =unlist(citationEle$getElementText())
    result =regmatches(result, regexpr("[[:digit:]]+", result))
  }

  return(result)   
}

# Main function to search on webofknowledge by title
search_title <- function(title) {
  
  remDr$navigate("http://www.webofknowledge.com")
  
  # click on the clear button in case there is previous search entry
  clearEle = remDr$findElements(using='id', value='clearIcon1')
  if (length(clearEle)<1){
    remDr$navigate("http://www.webofknowledge.com")
  } 
  clearEle = remDr$findElement(using='id', value='clearIcon1')
  clearEle$clickElement()
  
  # in dropdown menu for search criteria chose the element "Title"
  dropEle = remDr$findElement(using='id', value= 'select2-select1-container')
  chosen = unlist(dropEle$getElementText())
  
  if (chosen != 'Title') {
    dropEle$clickElement()
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "enter"))  
  }
  
  # enter title in the input field
  inputEle = remDr$findElement(using='id', value = 'value(input1)')
  inputEle$sendKeysToElement(list(title,key="enter"))
  
  # wait for 5 seconds to make sure that the page has fully loaded
  Sys.sleep(5) 
  
  # get citation number:
  citationEle <-remDr$findElements(using='class',value='search-results-data-cite')
  if (length(citationEle)<1) {
    result = NA
  } else {
    citationEle <-remDr$findElement(using='class',value='search-results-data-cite')
    result =unlist(citationEle$getElementText())
    result =regmatches(result, regexpr("[[:digit:]]+", result))
  }
  return(result)   
}




df<- read.csv('indexed_aer.csv')
df<- df[,c("doi","author","title")]
df["citation"] <- NA
df["checked"] <- 0



for (doi in df$doi){
  if (is.na(df$citation[df$doi == doi]) 
      && df$checked[df$doi == doi]==0){
    citation = search(doi)
    df$citation[df$doi == doi] = citation
    df$checked[df$doi == doi] = 1
  }
}

for (title in df$title){
  if (is.na(df$citation[df$title == title]) 
      && df$checked[df$title == title]==1){
    citation = search_title(title)
    df$citation[df$title == title] = citation
  }
}

write.csv(df, file="aer_citation.csv")
