library(RSelenium)

ajps<-read.csv("ajps_citation.csv")
ajps$title<-NULL

aj_temp <- read.csv("ajps_article_coding_template.csv")
aj_temp <- aj_temp[, -c(4:7)]
aj_temp<-aj_temp[,-1]
ajps <- merge(ajps,aj_temp, by.x='doi',by.y='doi')
ajps_na <- subset(ajps, is.na(ajps$citation))

apsr <- read.csv("apsr_citation.csv")
apsr$title <- NULL
ap_temp <- read.csv("apsr_article_coding_template.csv")
ap_temp<- ap_temp[,-c(4:7)]
ap_temp<-ap_temp[,-1]
apsr <- merge(apsr,ap_temp, by.x='doi',by.y='doi')
apsr_na <- subset(apsr, is.na(apsr$citation))


#rd <- rsDriver(port = 4566L, browser = c( "phantomjs"))
remDr <- remoteDriver(port=4444)
#remDr <- rd[["client"]]
remDr$open()

search <- function(doi) {
  #doi <- as.character(doi)
  remDr$navigate("http://www.webofknowledge.com")
  clearEle = remDr$findElements(using='id', value='clearIcon1')
  if (length(clearEle)<1){
    remDr$navigate("http://www.webofknowledge.com")
  } 
  clearEle = remDr$findElement(using='id', value='clearIcon1')
  clearEle$clickElement()
  
  dropEle = remDr$findElement(using='id', value= 'select2-chosen-1')
  chosen = unlist(dropEle$getElementText())
  
  if (chosen != 'Title') {
    dropEle$clickElement()
    dropEle$sendKeysToElement(list(key = "down_arrow"))
    dropEle$sendKeysToElement(list(key = "enter"))  
  }
  
  
  inputEle = remDr$findElement(using='id', value = 'value(input1)')
  inputEle$sendKeysToElement(list(doi,key="enter"))
  
  # get citation number:
  Sys.sleep(5) 
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

aj_output <- lapply(ajps_na$title, search)
ajps_na$citation2<-aj_output
ajps_na <- data.frame(lapply(ajps_na, as.character), stringsAsFactors=FALSE)

ajps_new <- merge(ajps, ajps_na, all.x = TRUE)
ajps_new$citation <- with(ajps_new, ifelse(is.na(citation2), 
                                                   citation, citation2))
ajps_new$citation2<-NULL
ajps_na<- subset(ajps_new, ajps_new$citation=="NA")

write.csv(ajps_new, file="ajps_2ndCheck.csv")
write.csv(ajps_new, file="ajps_handsearch.csv")

ap_output <- lapply(apsr_na$title, search)
apsr_na$citation2<-ap_output
apsr_na <- data.frame(lapply(apsr_na, as.character), stringsAsFactors=FALSE)

apsr_new <- merge(apsr, apsr_na, all.x = TRUE)
apsr_new$citation <- with(apsr_new, ifelse(is.na(citation2), 
                                           citation, citation2))
apsr_new$citation2<-NULL

apsr_na<- subset(apsr_new, apsr_new$citation=="NA")

write.csv(apsr_new, file="apsr_2ndCheck.csv")
write.csv(apsr_na, file="apsr_handsearch.csv")


