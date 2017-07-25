import scrapy
from scrapy.linkextractors import LinkExtractor
from scrapy.loader import ItemLoader
from scrapy.loader.processors import Join, MapCompose, Identity, TakeFirst
import scraping.items
from scraping.models import Article, get_session
from scraping.tools import (convert_relative_to_absolute_url,
                            extract_doi_from_doi_org_url,
                            strip_duplicate_whitespaces, strip_numbers)


class OxfordArticleLoader(ItemLoader):
    default_item_class = scraping.items.Article
    default_input_processor = MapCompose(str.strip,
                                         strip_duplicate_whitespaces)
    default_output_processor = Join()

    doi_in = MapCompose(extract_doi_from_doi_org_url)

    url_in = MapCompose(convert_relative_to_absolute_url)


class OxfordBioInfoLoader(ItemLoader):
    default_item_class = scraping.items.BiographicInformation
    default_input_processor = MapCompose(str.strip,
                                         strip_duplicate_whitespaces)
    default_output_processor = Join()

    affiliation_in = MapCompose(lambda x: x.strip(' ;'))
    name_in = MapCompose(strip_numbers)
    source_id_in = Identity()
    source_id_out = TakeFirst()


class OxfordSpider(scrapy.Spider):
    allowed_domains = ['academic.oup.com']
    custom_settings = {
        'ITEM_PIPELINES': {'scraping.pipelines.ORMPipeline': 12,
                           'scraping.pipelines.AttachSourcePipeline': 17,
                           'scraping.pipelines.DuplicatesPipeline': 23,
                           'scraping.pipelines.DatabasePipeline': 42}
    }

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

    # Locate doi and bio_info fields on article page.
    doi_xpath = '//div[@class="citation-doi"]/a/text()'
    author_article_xpath = '//div[@class="al-author-name"]'
    affiliation_xpath = ('.//div[@class="info-card-affilitation"]')
    affiliation_text_xpath = (
        './/div[@class="aff" or @class="insititution"]/text()')
    bio_info_xpaths = {
        'name': 'a/text()',
        'email': ('.//div[@class="info-author-correspondence"'
                  ' or @class="addr-line" or @class="aff" ]/a[@href and not(@class="link link-uri")]/text()')
    }

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
        # Collect doi for article.
        article_loader = OxfordArticleLoader(response.meta['article'],
                                             response)
        article_loader.replace_xpath('doi', self.doi_xpath)
        article_loader.replace_xpath('publication_date', self.
                                     item_field_xpaths['publication_date'])
        yield article_loader.load_item()

        # Query source_id of newly created article.
        with get_session() as session:
            source_id = (session.query(Article.source_id).
                        filter(Article.url == response.meta['article']['url']).
                        one())

        # Collect all data for biographic information.
        for author in response.xpath(self.author_article_xpath):
            for affiliation in author.xpath(self.affiliation_xpath):
                affiliation_text = ''.join(
                    affiliation.xpath(self.affiliation_text_xpath).extract())
                bio_info_loader = OxfordBioInfoLoader(selector=author,
                                                      response=response)
                bio_info_loader.add_value('source_id', source_id)
                bio_info_loader.add_value('affiliation', affiliation_text)
                for field, xpath in self.bio_info_xpaths.items():
                    bio_info_loader.add_xpath(field, xpath)
                yield bio_info_loader.load_item()


class REStudSpider(OxfordSpider):
    name = 'restud'
    start_urls = ['https://academic.oup.com/restud/list-of-years?years=2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1997,1996,1995,1994,1993,1992,1991,1990,1989&jn=The%20Review%20of%20Economic%20Studies']  # noqa: E501
    item_field_literals = {
        'journal': 'Review of Economic Studies',
    }


class QJESpider(OxfordSpider):
    name = 'qje'
    start_urls = ['https://academic.oup.com/qje/list-of-years?years=2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1997,1996,1995,1994,1993,1992,1991,1990,1989&jn=The%20Quarterly%20Journal%20of%20Economics']  # noqa: E501
    item_field_literals = {
        'journal': 'The Quarterly Journal of Economics',
    }


class PolticalAnalysisSpider(OxfordSpider):
    name = 'political_analysis'
    start_urls = ['https://academic.oup.com/pan/list-of-years?years=2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1996,1993,1992,1991,1990,1989&jn=Political%20Analysis']  # noqa: E501
    item_field_literals = {
        'journal': 'Political Analysis',
    }


class SCANSpider(OxfordSpider):
    name = 'scan'
    start_urls = ['https://academic.oup.com/scan/list-of-years?years=2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1996,1993,1992,1991,1990,1989']  # noqa: E501
    item_field_literals = {
        'journal': 'Social Cognitive and Affective Neuroscience',
    }


class ESRSpider(OxfordSpider):
    name = 'esr'
    start_urls = ['https://academic.oup.com/esr/list-of-years?years=2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1996,1993,1992,1991,1990,1989']  # noqa: E501
    item_field_literals = {
        'journal': 'European Sociological Review',
    }


class SocialForcesSpider(OxfordSpider):
    name = 'social_forces'
    start_urls = ['https://academic.oup.com/sf/list-of-years?years=2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1996,1993,1992,1991,1990,1989']  # noqa: E501
    item_field_literals = {
        'journal': 'Social Forces',
    }
    affiliation_text_xpath = (
        'div[@class="aff"]/descendant-or-self::*/text()')


class SocialProblemsSpider(OxfordSpider):
    name = 'social_problems'
    start_urls = ['https://academic.oup.com/sp/list-of-years?years=2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1996,1993,1992,1991,1990,1989']  # noqa: E501
    item_field_literals = {
        'journal': 'Social Problems',
    }
