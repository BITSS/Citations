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
  
  ## sendKeysToElement function seems to be broken 
  ## TODO: here expected to be bugs, fix them.
  if (chosen != 'DOI') {
    dropEle$clickElement()
    #textbox <- remDr$findElement(using='class', value='select2-search__field')
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "enter"))
    #textbox$sendKeysToElement(list("DOI", key="enter"))
  }
  
  # enter doi number in the input field
  inputEle = remDr$findElement(using='id', value = 'value(input1)')
  inputEle$clickElement()
  inputEle$sendKeysToElement(list(doi,key="enter"))
  
  # wait for 5 seconds to make sure that the page has fully loaded
  Sys.sleep(5) 
  
  result<-remDr$findElement(using='class', value='smallV110')
  result$clickElement()
  
  Sys.sleep(3) 
  
  # can only get the first author, findElements does not work anymore
  ## TODO: fix bugs + better code
  authors <- remDr$findElement(using='class', value='FR_field')
  list<- remDr$findElement('xpath', '//*[@title="Find more records by this author"]')
  list$highlightElement()
  list$clickElement()
  
  countEle <- remDr$findElement(using='id', value='hitCount.top')
  count <- unlist(countEle$getElementText())
  
  return(count)
}


df<- read.csv('qje_citation.csv')
df["numberofpubs"] <- NA
df["checked"] <- 0



for (doi in df$doi){
  if (is.na(df$numberofpubs[df$doi == doi]) 
      && df$checked[df$doi == doi]==0){
    count = search(doi)
    df$numberofpubs[df$doi == doi] = count
    df$checked[df$doi == doi] = 1
  }
}

write.csv(df, file="qje_pubcount.csv")
