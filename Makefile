
DESTDIR=/home/len/repos/lenjaffe.com/AdventPlanet


all: gzip_html


# regenerate gzipped assets
gzip_html: $(DESTDIR)/index.html.gz $(DESTDIR)/news.html.gz

$(DESTDIR)/index.html.gz: $(DESTDIR)/index.html
	(cd $(DESTDIR); gzip -c index.html > index.html.gz; git add index.html.gz)


$(DESTDIR)/news.html.gz: $(DESTDIR)/news.html
	(cd $(DESTDIR); gzip -c news.html > news.html.gz; git add news.html.gz)
