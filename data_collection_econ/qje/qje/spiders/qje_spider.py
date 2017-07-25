import scrapy
from scrapy.linkextractors import LinkExtractor
from scrapy.loader import ItemLoader
from scrapy.loader.processors import Join, MapCompose, Identity, TakeFirst
import qje.items
from urllib.parse import urljoin

def convert_relative_to_absolute_url(url,loader_context):
    return urljoin(loader_context['response'].url, url)

class OxfordArticleLoader(ItemLoader):
    default_item_class = qje.items.Article
    default_input_processor = MapCompose(str.strip)
    default_output_processor = Join()
    url_in = MapCompose(convert_relative_to_absolute_url)


class OxfordSpider(scrapy.Spider):
    allowed_domains = ['academic.oup.com']
    # Locate articles.
    volume_xpath = ('//div[@class="widget widget-'
                    'IssueYears widget-instance-OUP_Issues_Year_List"]/div/a')
    issue_xpath = '//div[@id="item_ResourceLink"]'
    article_xpath = '//div[@class="al-article-items"]'
    volume_extractor = LinkExtractor(restrict_xpaths=volume_xpath)
    issue_extractor = LinkExtractor(restrict_xpaths=issue_xpath)

    # Locate article fields on table of contents page.
    item_field_xpaths = {
        'title': 'h5/a/text()',
        'publication_date': '//div[@class="citation-date"]/text()',
        'url': 'h5/a/@href'
    }
    author_toc_xpath = './/span[@class="wi-fullname brand-fg"]/a/text()'

    # Locate article data
    doi_xpath = "//meta[@name = 'citation_doi']/@content"
    author_xpath = '//meta[@name = "citation_author"]/@content'
    title_xpath = "//meta[@name = 'citation_title']/@content"
    abstract_xpath = "//section[@class = 'abstract']//p"
    # JEL_xpath = "//div[@class = 'article-metadata']//a/text()"
    # content_xpath = "//div[@class='widget-items' and @data-widgetname='ArticleFulltext']"
    publication_date_xpath = "//meta[@name = 'citation_publication_date']/@content"
    pdf_url_xpath = "//meta[@name = 'citation_pdf_url']/@content"


    def parse(self, response):
        for volume in self.volume_extractor.extract_links(response):
            yield scrapy.Request(volume.url, callback=self.parse_volume)

    def parse_volume(self, response):
        for issue in self.issue_extractor.extract_links(response):
            yield scrapy.Request(issue.url, callback=self.parse_issue)

    def parse_issue(self, response):
        for article in response.xpath(self.article_xpath):
            if article.xpath(self.author_toc_xpath) == []:
                continue
            else:
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
        article_loader.add_xpath('doi', self.doi_xpath) 
        article_loader.add_xpath('title', self.title_xpath)
        article_loader.add_xpath('author', self.author_xpath)
        article_loader.add_xpath('abstract', self.abstract_xpath)
        # article_loader.add_xpath('content', self.content_xpath)
        # article_loader.add_xpath('JEL', self.JEL_xpath) 
        article_loader.add_xpath('publication_date', self.publication_date_xpath)
        article_loader.add_xpath('pdf_url', self.pdf_url_xpath)

        yield article_loader.load_item()


class QJESpider(OxfordSpider):
    name = 'qje'
    start_urls = ['https://academic.oup.com/qje/list-of-years?years=2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1997,1996,1995,1994,1993,1992,1991,1990,1989&jn=The%20Quarterly%20Journal%20of%20Economics']  # noqa: E501
    item_field_literals = {
        'journal': 'The Quarterly Journal of Economics',
    }


