# pywws - Python software for USB Wireless Weather Stations
# http://github.com/jim-easterbrook/pywws
# Copyright (C) 2008-13  Jim Easterbrook  jim@jim-easterbrook.me.uk

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

ifdef LANG
  LANG	:= $(firstword $(subst _, ,$(LANG)))
else
  LANG	:= en
endif

po_files	:= $(notdir $(wildcard translations/$(LANG)/*.po))
translations	:= $(notdir $(wildcard translations/*))
langs		:= $(filter-out %.pot, $(translations))

all : lang code/pywws/version.py doc
	python setup.py build

install :
	python setup.py install

dist : lang_all code/pywws/version.py doc_all
	python setup.py sdist

clean :
	rm -Rf doc/* code/pywws/locale/* translations/*/LC_MESSAGES \
		code3 build dist code/pywws/version.py

lang : $(po_files:%.po=translations/$(LANG)/LC_MESSAGES/%.mo) \
	$(po_files:%=code/pywws/locale/$(LANG)/LC_MESSAGES/pywws.mo)

lang_all :
	for lang in $(langs); do $(MAKE) LANG=$$lang lang; done

pots	:= pywws api essentials guides index pywws
lang_src : code/pywws/version.py \
		$(pots:%=translations/%.pot) \
		$(pots:%=translations/$(LANG)/%.po)

doc : lang code/pywws/version.py
	$(MAKE) -C doc_src html text SPHINXOPTS="-D language=$(LANG)"

doc_all :
	$(MAKE) doc LANG=en
	$(MAKE) doc LANG=fr

sources	:= $(wildcard code/*) $(wildcard code/pywws/*) \
	   $(wildcard code/pywws/services/*) $(wildcard code/pywws/locale/*/*/*)
sources	:= $(filter %.py %.mo %.txt %.ini, $(sources))
python3 : $(sources:code/%=code3/%)

.PHONY : doc dist

# convert to Python3
code3/%.py : code/%.py
	mkdir -p $(dir $@)
	cp $< $@
	2to3 -x import -w -n $@

code3/% : code/%
	mkdir -p $(dir $@)
	cp $< $@

# create a version file
.PHONY : code/pywws/version.py
COMMIT	:= $(shell git rev-parse --short master)
code/pywws/version.py :
	date +"version = '%y.%m_$(COMMIT)'" >$@

# copy pywws language file to code subdirectory
code/pywws/locale/%.mo : translations/%.mo
	mkdir -p $(dir $@)
	cp $< $@

# compile a language file
translations/$(LANG)/LC_MESSAGES/%.mo : translations/$(LANG)/%.po
	mkdir -p $(dir $@)
	msgfmt --output-file=$@ $<

# create or update a language file from extracted strings
translations/$(LANG)/%.po : translations/%.pot
	if [ -e $@ ]; then \
	  msgmerge $@ $< --no-wrap --update && \
	  touch $@ ; \
	else \
	  mkdir -p $(dir $@) && \
	  msginit --input=$< --output-file=$@ --no-wrap --locale=$(LANG) ; \
	fi

# extract marked strings from Python code
translations/pywws.pot :
	xgettext --language=Python --output=$@ --no-wrap \
		--copyright-holder="Jim Easterbrook" \
		--package-name=pywws --package-version=`date +"%y.%m"` \
		--msgid-bugs-address="jim@jim-easterbrook.me.uk" \
		code/*.py code/pywws/*.py

# extract strings for translation from documentation source
translations/%.pot :
	cd doc_src; \
	sphinx-build -b gettext . ../translations
