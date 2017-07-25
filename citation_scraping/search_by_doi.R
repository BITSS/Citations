library(RSelenium)
library(rvest)
library(magrittr)
library(foreach)

# Prior to run the next two lines of code to start the remoteDriver
# Please make sure to cd to this folder and run this next line of code in the terminal
# java -jar selenium-server-standalone-3.3.1.jar            
remDr <- remoteDriver(port=4444)
remDr$open()

# Read in the data and split into 3 seperate dataframes to split the task into smaller pieces.
df <- read.csv('apsr_centennial_reference_coding_template.csv')
df1 <- df[1:200,]
df2 <- df[201:401,]
df3 <- df[402:608,]

apsr <- read.csv('apsr_article.csv')
apsr1<-apsr[1:220,]
apsr2<-apsr[221:447,]


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
    result ='NA'
  } else {
    citationEle <-remDr$findElement(using='class',value='search-results-data-cite')
    result =unlist(citationEle$getElementText())
    result =regmatches(result, regexpr("[[:digit:]]+", result))
  }
  return(result)   
}

## apply search on each data frame
output <- lapply(df$doi, search)
df$citation <- output
df1 <- data.frame(lapply(df1, as.character), stringsAsFactors=FALSE)

output2 <- lapply(df2$doi, search)
df2$citation <- output2
df2 <- data.frame(lapply(df2, as.character), stringsAsFactors=FALSE)

output3 <- lapply(df3$doi, search)
df3$citation <- output3
df3 <- data.frame(lapply(df3, as.character), stringsAsFactors=FALSE)

output4 <- lapply(apsr1$doi, search)
apsr1$citation <- output4
apsr1 <- data.frame(lapply(apsr1, as.character), stringsAsFactors=FALSE)

output5 <- lapply(apsr2$doi, search)
apsr2$citation <- output5
apsr2 <- data.frame(lapply(apsr2, as.character), stringsAsFactors=FALSE)

## write out each resulted datafram to file
write.csv(df1, file="ajps1.csv")
write.csv(df2, file="ajps2.csv")
write.csv(df3, file="ajps3.csv")
write.csv(apsr1, file="apsr1.csv")
write.csv(apsr2, file="apsr2.csv")

## Read in ajps result dataframes to combine
ajps1 <- read.csv('ajps1.csv')
ajps2 <- read.csv('ajps2.csv')
ajps3 <- read.csv('ajps3.csv')
library(plyr)
ajps<- rbind.fill(ajps1, ajps2, ajps3)

apsr1 <- read.csv('apsr1.csv')
apsr2 <- read.csv('apsr2.csv')
apsr<- rbind.fill(apsr1, apsr2)

### Redo search on NA results for ajps
NAsearch <- ajps[is.na(ajps$citation),]
NAresult <- lapply(NAsearch$doi, search)
NAsearch$citation2 <- NAresult

# merge the result back to original dataframe and write out to file
checked_ajps <- merge(ajps, NAsearch, all.x=TRUE)
checked_ajps$citation <- with(checked_ajps, ifelse(is.na(citation2), 
                                                   citation, citation2))
checked_ajps$citation2 <- NULL
checked_ajps <- data.frame(lapply(checked_ajps, as.character), stringsAsFactors=FALSE)
write.csv(checked_ajps, file="ajps_byDoi.csv")

### Redo search on NA results for apsr
NAsearch1 <- apsr[is.na(apsr$citation),]
NAresult1 <- lapply(NAsearch1$doi, search)
NAsearch1$citation2 <- NAresult1

checked_apsr <- merge(apsr, NAsearch1, all.x=TRUE)
checked_apsr$citation <- with(checked_apsr, ifelse(is.na(citation2), 
                                                   citation, citation2))
checked_apsr$citation2 <- NULL
checked_apsr <- data.frame(lapply(checked_apsr, as.character), stringsAsFactors=FALSE)
write.csv(checked_apsr, file="apsr_byDoi.csv")
