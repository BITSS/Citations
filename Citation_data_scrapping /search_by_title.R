library(RSelenium)

# Prior to run the next two lines of code for starting the remoteDriver
# Please make sure to cd to this folder and run this next line of code in the terminal
# java -jar selenium-server-standalone-3.3.1.jar    
remDr <- remoteDriver(port=4444)
remDr$open()


## Read in data and extract columns with NA
ajps<-read.csv("ajps_byDoi.csv")
ajps$title<-NULL

aj_temp <- read.csv("ajps_article_coding_template.csv")
aj_temp <- aj_temp[, -c(4:7)]
aj_temp<-aj_temp[,-1]
ajps <- merge(ajps,aj_temp, by.x='doi',by.y='doi')
ajps_na <- subset(ajps, is.na(ajps$citation))

apsr <- read.csv("apsr_byDoi.csv")
apsr$title <- NULL
ap_temp <- read.csv("apsr_article_coding_template.csv")
ap_temp<- ap_temp[,-c(4:7)]
ap_temp<-ap_temp[,-1]
apsr <- merge(apsr,ap_temp, by.x='doi',by.y='doi')
apsr_na <- subset(apsr, is.na(apsr$citation))


# Main function to search on webofknowledge by title
search <- function(doi) {

  remDr$navigate("http://www.webofknowledge.com")
  
  # click on the clear button in case there is previous search entry
  clearEle = remDr$findElements(using='id', value='clearIcon1')
  if (length(clearEle)<1){
    remDr$navigate("http://www.webofknowledge.com")
  } 
  clearEle = remDr$findElement(using='id', value='clearIcon1')
  clearEle$clickElement()
  
  # in dropdown menu for search criteria chose the element "Title"
  dropEle = remDr$findElement(using='id', value= 'select2-chosen-1')
  chosen = unlist(dropEle$getElementText())
  
  if (chosen != 'Title') {
    dropEle$clickElement()
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "enter"))  
  }
  
  # enter title in the input field
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


# apply the search function on ajps NA rows and save the result 
aj_output <- lapply(ajps_na$title, search)
ajps_na$citation2<-aj_output
ajps_na <- data.frame(lapply(ajps_na, as.character), stringsAsFactors=FALSE)

# merge with searched-by-doi file and replace NA with new results
ajps_new <- merge(ajps, ajps_na, all.x = TRUE)
ajps_new$citation <- with(ajps_new, ifelse(is.na(citation2), 
                                                   citation, citation2))
ajps_new$citation2<-NULL

# filter out rows that still have NA and save as handsearch file.
ajps_na<- subset(ajps_new, ajps_new$citation=="NA")
write.csv(ajps_new, file="ajps_byTitle.csv")
write.csv(ajps_na, file="ajps_handsearch.csv")

# apply the search function on apsr NA rows and save the result 
ap_output <- lapply(apsr_na$title, search)
apsr_na$citation2<-ap_output
apsr_na <- data.frame(lapply(apsr_na, as.character), stringsAsFactors=FALSE)

# merge with searched-by-doi file and replace NA with new results
apsr_new <- merge(apsr, apsr_na, all.x = TRUE)
apsr_new$citation <- with(apsr_new, ifelse(is.na(citation2), 
                                           citation, citation2))
apsr_new$citation2<-NULL

# filter out rows that still have NA and save as handsearch file.
apsr_na<- subset(apsr_new, apsr_new$citation=="NA")
write.csv(apsr_new, file="apsr_byTitle.csv")
write.csv(apsr_na, file="apsr_handsearch.csv")


