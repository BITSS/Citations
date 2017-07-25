install.packages(RCurl)
install.packages("downloader")
library(RCurl)
library(downloader)

setwd('C:/Users/caobaiyue/Desktop/aer')
aer = read.csv('indexed_aer.csv', stringsAsFactors=FALSE)

#some data cleaning 
aer = aer[aer$author!= '',]
aer_nrow = nrow(aer)

testit <- function(x)
{
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 # The cpu usage should be negligible
}

useragent =  c("Mozilla/5.0 (Windows; U; Windows NT 5.1; en - US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6",
               'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1',
               'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41',
               'Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)',
               'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0',
               "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1)",
               'Mozilla/5.0 (Linux; Android 5.1.1; SM-G928X Build/LMY47X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.83 Mobile Safari/537.36',
               'Mozilla/5.0 (Linux; Android 6.0.1; E6653 Build/32.2.A.0.253) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.98 Mobile Safari/537.36',
               'Mozilla/5.0 (Linux; Android 5.1.1; SHIELD Tablet Build/LMY48C) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.98 Safari/537.36',
               'Mozilla/5.0 (Linux; Android 4.4.3; KFTHWI Build/KTU84M) AppleWebKit/537.36 (KHTML, like Gecko) Silk/47.1.79 like Chrome/47.0.2526.80 Safari/537.36',
               'Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)')


for (k in c(271:357)){
  rando = sample(1:11, 1)
  options(HTTPUserAgent = useragent[rando])
  url = aer$pdf_url[k]
  index = aer$index[k]
  file_name = paste(index, 'aer.pdf', sep = '')
  if (index %% 50 == 0){
    download(url, file_name, mode = 'wb')
    delay = sample(5:60, 1)
    testit(delay)
  } else {
    download(url, file_name, mode = 'wb')
    delay = runif(1, min=3, max=5)
    testit(delay)
  }
}


 
        
        


