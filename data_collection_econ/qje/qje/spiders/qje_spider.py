import scrapy

class qjeSpider(scrapy.Spider):
    name = "qje"

    def start_requests(self):
        urls = [
            'https://academic.oup.com/qje/article/131/4/1795/2468877/Evaluating-Public-Programs-with-Close-Substitutes?searchresult=1'
        ] #or other links
        for url in urls:
            yield scrapy.Request(url=url, callback=self.parse)

    def parse(self, response):
        yield{
        'doi':response.xpath("//meta[@name = 'citation_doi']/@content").extract(),
        'title':response.xpath("//meta[@name = 'citation_title']/@content").extract(),
        'author':response.xpath("//meta[@name = 'citation_author']/@content").extract(),
        'abstract':response.xpath("//section[@class = 'abstract']//p").extract(),
        'JEL': response.xpath("//div[@class = 'article-metadata']//a/text()").extract(),
        'content':response.xpath("//div[@class='widget-items' and @data-widgetname='ArticleFulltext']").extract(),
        }        


