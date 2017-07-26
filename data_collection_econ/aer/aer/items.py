# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy

class AerItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    pass

class Article(AerItem):
    doi = scrapy.Field()
    title = scrapy.Field()
    author = scrapy.Field()
    abstract = scrapy.Field()
    JEL = scrapy.Field()
    publication_date = scrapy.Field()
    journal = scrapy.Field()
    url = scrapy.Field()
    pdf_url = scrapy.Field()