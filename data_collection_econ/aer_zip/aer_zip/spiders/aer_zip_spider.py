import scrapy
from scrapy.linkextractors import LinkExtractor
from scrapy.loader import ItemLoader
from scrapy.loader.processors import Join, MapCompose, Identity, TakeFirst
import urllib
from urllib.parse import urljoin
import aer_zip.items
from urllib.request import urlretrieve

# link_list = ['https://eml.berkeley.edu//~saez/course131/socialinsurance_ch12_new.pdf']
# for link in link_list:
#     urlretrieve(link, 'lol.pdf')

def convert_relative_to_absolute_url(url,loader_context):
    return urljoin("https://www.aeaweb.org", url)

class OxfordArticleLoader(ItemLoader):
    default_item_class = aer_zip.items.Article
    default_input_processor = MapCompose(str.strip)
    default_output_processor = Join()
    url_in = MapCompose(convert_relative_to_absolute_url)

class OxfordSpider(scrapy.Spider):
    allowed_domains = ['www.aeaweb.org']

    # Locate articles.
    issue_xpath = '//a[contains(@href,"/issues/")]'
    article_xpath = '//article[@class = "journal-article "]'
    issue_extractor = LinkExtractor(restrict_xpaths=issue_xpath)

    # Locate articles on issue page
    item_field_xpaths = {
        'title': 'h3/a/text()',
        'publication_date': '//meta[@name = "citation_publication_date"]/@content',
        'url': 'h3/a/@href'
    }

    # locate fields on article page
    item_article_xpaths = {
        'doi' : '//meta[@name = "citation_doi"]/@content',
        'title' : '//meta[@name = "title"]/text()',
        'app_url' : '//ul[@id = "additionalMaterials"]/li/a[contains(@href, "app")]/@href',
        'corr_url': '//ul[@id = "additionalMaterials"]/li/a[contains(@href, "corr")]/@href',
        'ds_url': '//ul[@id = "additionalMaterials"]/li/a[contains(@href, "ds")]/@href',
        'data_url': '//ul[@id = "additionalMaterials"]/li/a[not(contains(@href, "ds") or contains(@href, "app") or contains(@href, "corr"))]/@href',
        'publication_date': '//meta[@name = "citation_publication_date"]/@content'
    }

    def parse(self, response):
        for issue in self.issue_extractor.extract_links(response):
            yield scrapy.Request(issue.url, callback=self.parse_issue)

    def parse_issue(self, response):
        for article in response.xpath(self.article_xpath):
            article_loader = OxfordArticleLoader(selector=article,
                                                     response=response)
            for field, literal in self.item_field_literals.items():
                article_loader.add_value(field, literal)
            for field, xpath in self.item_field_xpaths.items():
                article_loader.add_xpath(field, xpath)
            article_item = article_loader.load_item()
            yield scrapy.Request(article_item['url'],
                                    callback=self.parse_article,
                                    meta={'article': article_item})

    def parse_article(self, response):
        article_loader = OxfordArticleLoader(response.meta['article'],
                                             response)
        for field, xpath in self.item_article_xpaths.items():
            article_loader.add_xpath(field, xpath)
        yield article_loader.load_item()



class aer_zipSpider(OxfordSpider):
    name = 'aer_zip'
    start_urls = ['https://www.aeaweb.org/journals/aer/issues']
    item_field_literals = {
        'journal': 'American Economic Review',
        }





