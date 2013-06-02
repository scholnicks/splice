# Makefile for splice installation
#
# See http://www.scholnick.net/splice for details

# Edit as necessary

PERL      = $(shell which perl)
PERLLIB   = $(shell $(PERL) -V:sitelib | cut -d"'" -f2)
BINDIR    = $(shell $(PERL) -V:installsitebin | cut -d"'" -f2)
MANDIR    = $(shell $(PERL) -V:installman1dir | cut -d"'" -f2)

install: main modules doc

test:
	@echo $(PERL)
	@echo $(PERLLIB)
	@echo $(BINDIR)
	@echo $(MANDIR)

main:
	cp splice.pl $(BINDIR)/splice
	chmod 755 $(BINDIR)/splice

modules:
	cp -R Splice $(PERLLIB)
	chmod 755 $(PERLLIB)/Splice
	chmod a+r $(PERLLIB)/Splice/*.pm
	
doc:
	install -m 644 splice.1 $(MANDIR)

rc:
	cp splice.rc $(HOME)/.splicerc
