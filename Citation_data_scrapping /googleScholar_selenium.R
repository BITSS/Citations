library(RSelenium)

#rd <- rsDriver(port = 4566L, browser = c( "phantomjs"))
remDr <- remoteDriver(port=4444)
#remDr <- rd[["client"]]
remDr$open()

# ajps
ajps <- read.csv('ajps_2ndCheck.csv')
aj1 <- ajps[1:100,]
aj2 <- ajps[101:200,]
aj3 <- ajps[201:300,]
aj4 <- ajps[301:400,]
aj5 <- ajps[401:500,]
aj6 <- ajps[501:608,]

# apsr
apsr <- read.csv('apsr_2ndCheck.csv')
ap1<-apsr[1:220,]
ap2<-apsr[221:447,]

search <- function(input) {
  #doi <- as.character(doi)
  remDr$navigate("http://scholar.google.com")
  
  inputEle = remDr$findElement(using='id', value = 'gs_hp_box_in')
  inputEle$sendKeysToElement(list(input,key="enter"))
  
  # get citation number:
  Sys.sleep(2) 
  citationEle <-remDr$findElements(using='xpath',value='//*[@id="gs_ccl_results"]/div[1]/div[2]/div[3]')
  if (length(citationEle)<1) {
    result ='NA'
  } else {
    citationEle <-remDr$findElement(using='xpath',value='//*[@id="gs_ccl_results"]/div[1]/div[2]/div[3]')
    result =unlist(citationEle$getElementText())
    result =regmatches(result, regexpr("[[:digit:]]+", result))
  }
  return(result)   
}

## apply search on each data frame
output1 <- lapply(aj1$title, search)
aj1$google_citation <- output
aj1 <- data.frame(lapply(df1, as.character), stringsAsFactors=FALSE)

output2 <- lapply(aj2$title, search)
aj2$google_citation <- output2
aj2 <- data.frame(lapply(df2, as.character), stringsAsFactors=FALSE)

output3 <- lapply(aj3$title, search)
aj3$google_citation <- output3
aj3 <- data.frame(lapply(df3, as.character), stringsAsFactors=FALSE)


output4 <- lapply(ap1$title, search)
ap1$google_citation <- output4
ap1 <- data.frame(lapply(apsr1, as.character), stringsAsFactors=FALSE)

output5 <- lapply(ap2$title, search)
ap2$google_citation <- output5
ap2 <- data.frame(lapply(ap2, as.character), stringsAsFactors=FALSE)
## write out 
write.csv(aj1, file="ajps1.csv")
write.csv(aj2, file="ajps2.csv")
write.csv(aj3, file="ajps3.csv")
write.csv(ap1, file="apsr1.csv")
write.csv(ap2, file="apsr2.csv")

## Read in ajps result dataframes to combine
aj1 <- read.csv('ajps1.csv')
aj2 <- read.csv('ajps2.csv')
aj3 <- read.csv('ajps3.csv')
library(plyr)
ajps<- rbind.fill(aj1, aj2, aj3)

ap1 <- read.csv('apsr1.csv')
ap2 <- read.csv('apsr2.csv')
apsr<- rbind.fill(ap1, ap2)


ajps <- data.frame(lapply(ajps, as.character), stringsAsFactors=FALSE)
write.csv(ajps, file="ajps_citation.csv")

apsr <- data.frame(lapply(apsr, as.character), stringsAsFactors=FALSE)
write.csv(apsr, file="apsr_citation.csv")
