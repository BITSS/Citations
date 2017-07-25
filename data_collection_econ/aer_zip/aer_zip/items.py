# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class AerZipItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    pass
# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

class Article(AerZipItem):
    doi = scrapy.Field()
    title = scrapy.Field()
    publication_date = scrapy.Field()
    url = scrapy.Field()
    data_url = scrapy.Field()
    corr_url = scrapy.Field()
    app_url = scrapy.Field()
    ds_url = scrapy.Field()
    journal = scrapy.Field()