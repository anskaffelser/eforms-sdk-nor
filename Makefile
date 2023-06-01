EFORMS_MINOR ?= $$(./bin/property -p sdk_minor)
EFORMS_PATCH ?= $$(./bin/property -p sdk_patch)
EFORMS_VERSION = $(EFORMS_MINOR).$(EFORMS_PATCH)

VERSION := $(shell echo -n $${PROJECT_VERSION:-dev-$$(date -u +%Y%m%d-%H%M%Sz)})

SAXON_MAJOR ?= 12
SAXON_MINOR ?= 2

default: clean-light build

clean-light:
	@rm -rf target/eforms-sdk-nor

clean:
	@rm -rf target .bundle/vendor

version:
	@echo $(EFORMS_VERSION)

versions:
	@echo -n "MATRIX="
	@./bin/versions

build: target/eforms-sdk-nor

extract: .bundle/vendor target/eforms-sdk
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/extract-codelists
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/extract-translations
	@rm src/translations/rule.yaml

update-code: .bundle/vendor
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/update-code

status: .bundle/vendor
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/translation-status src/codelists src/translations

package: package-tgz package-zip

package-tgz:
	@rm -f target/eforms-sdk-nor-*.tar.gz
	@cd target/eforms-sdk-nor && tar -czf ../eforms-sdk-nor-$(VERSION).tar.gz *

package-zip:
	@rm -f target/eforms-sdk-nor-*.zip
	@cd target/eforms-sdk-nor && zip -q9r ../eforms-sdk-nor-$(VERSION).zip *

target/eforms-sdk: .bundle/vendor target/eforms-sdk/README.md

target/eforms-sdk/README.md:
	@echo "* Downloading eForms SDK $(EFORMS_VERSION)"
	@mkdir -p target
	@rm -rf target/eforms-sdk
	@wget -q https://github.com/OP-TED/eForms-SDK/archive/refs/tags/$(EFORMS_VERSION).zip -O target/eforms-sdk.zip
	@unzip -qo target/eforms-sdk.zip -d target
	@mv target/eForms-SDK-$(EFORMS_VERSION) target/eforms-sdk
	@rm -rf target/eforms-sdk.zip

.bundle/vendor:
	@echo "* Install dependencies"
	@bundler install --path=.bundle/vendor

target/eforms-sdk-nor: \
	target/eforms-sdk-nor/codelists \
	target/eforms-sdk-nor/efx-grammar \
	target/eforms-sdk-nor/fields \
	target/eforms-sdk-nor/notice-types \
	target/eforms-sdk-nor/schemas \
	target/eforms-sdk-nor/schematrons \
	target/eforms-sdk-nor/translations \
	target/eforms-sdk-nor/view-templates \
	target/eforms-sdk-nor/xslt \
	target/eforms-sdk-nor/README.md \
	target/eforms-sdk-nor/LICENSE-eForms-SDK \
	target/eforms-sdk-nor/LICENSE-eForms-SDK-NOR

target/eforms-sdk-nor/codelists: target/eforms-sdk bin/create-codelists src/properties.yaml
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/create-codelists

target/eforms-sdk-nor/efx-grammar: target/eforms-sdk
	@echo "* Copy EHX grammar"
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/efx-grammar target/eforms-sdk-nor/efx-grammar

target/eforms-sdk-nor/fields: \
	target/eforms-sdk-nor/fields/eu.json \
	target/eforms-sdk-nor/fields/national.json

target/eforms-sdk-nor/fields/eu.json: target/eforms-sdk bin/process-fields
	@echo "* Create fields subset (eu)"
	@mkdir -p target/eforms-sdk-nor/fields
	@ruby bin/process-fields \
		-i target/eforms-sdk/fields/fields.json \
		-c src/fields/eu.yaml \
		-o target/eforms-sdk-nor/fields/eu.json

target/eforms-sdk-nor/fields/national.json: target/eforms-sdk bin/process-fields
	@echo "* Create fields subset (national)"
	@mkdir -p target/eforms-sdk-nor/fields
	@ruby bin/process-fields \
		-i target/eforms-sdk/fields/fields.json \
		-c src/fields/national.yaml \
		-o target/eforms-sdk-nor/fields/national.json

target/eforms-sdk-nor/notice-types: target/eforms-sdk
	@echo "* Copy notice types"
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/notice-types target/eforms-sdk-nor/notice-types

target/eforms-sdk-nor/schemas: target/eforms-sdk
	@echo "* Copy schemas (XSD)"
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/schemas target/eforms-sdk-nor/schemas

target/eforms-sdk-nor/schematrons: \
	target/eforms-sdk-nor/schematrons/eforms-dynamic.sch \
	target/eforms-sdk-nor/schematrons/eforms-static.sch \
	target/eforms-sdk-nor/schematrons/norway-eu.sch \
	target/eforms-sdk-nor/schematrons/norway-national.sch

target/eforms-sdk-nor/schematrons/eforms-dynamic.sch: target/eforms-sdk target/saxon src/xslt/sch-cleanup.xslt
	@echo "* Preparing Schematron: eforms-dynamic.sch"
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon.jar -s:target/eforms-sdk/schematrons/dynamic/complete-validation.sch -xsl:bin/xslt/sch-include.xslt \
	| java -jar target/saxon/saxon.jar -s:- -xsl:src/xslt/sch-cleanup.xslt -o:target/eforms-sdk-nor/schematrons/eforms-dynamic.sch

target/eforms-sdk-nor/schematrons/eforms-static.sch: target/eforms-sdk target/saxon src/xslt/sch-cleanup.xslt
	@echo "* Preparing Schematron: eforms-static.sch"
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon.jar -s:target/eforms-sdk/schematrons/static/complete-validation.sch -xsl:bin/xslt/sch-include.xslt \
	| java -jar target/saxon/saxon.jar -s:- -xsl:src/xslt/sch-cleanup.xslt -o:target/eforms-sdk-nor/schematrons/eforms-static.sch

target/eforms-sdk-nor/schematrons/norway-eu.sch: target/saxon target/sch/eu
	@echo "* Preparing Schematron: norway-eu.sch"
	@java -jar target/saxon/saxon-he-12.2.jar \
		-s:target/sch/eu/main.sch \
		-xsl:bin/xslt/sch-include.xslt \
		-o:target/eforms-sdk-nor/schematrons/norway-eu.sch

target/eforms-sdk-nor/schematrons/norway-national.sch: target/saxon target/sch/national
	@echo "* Preparing Schematron: norway-national.sch"
	@java -jar target/saxon/saxon-he-12.2.jar \
		-s:target/sch/national/main.sch \
		-xsl:bin/xslt/sch-include.xslt \
		-o:target/eforms-sdk-nor/schematrons/norway-national.sch

target/eforms-sdk-nor/translations: \
	target/eforms-sdk-nor/translations/business-term_en.xml \
	target/eforms-sdk-nor/translations/business-term_nb.xml

target/eforms-sdk-nor/translations/business-term_en.xml: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/translations target/eforms-sdk-nor/translations

target/eforms-sdk-nor/translations/business-term_nb.xml: target/eforms-sdk src/properties.yaml bin/create-translations
	@mkdir -p target/eforms-sdk-nor
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/create-translations
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/create-translations --complete

target/eforms-sdk-nor/view-templates: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/view-templates target/eforms-sdk-nor/view-templates

target/eforms-sdk-nor/xslt: \
	target/eforms-sdk-nor/xslt/nor-to-eforms.xslt

target/eforms-sdk-nor/xslt/nor-to-eforms.xslt:
	@echo "* Copy XSLT: nor-to-eforms"
	@mkdir -p target/eforms-sdk-nor/xslt
	@cp src/xslt/nor-to-eforms.xslt target/eforms-sdk-nor/xslt/nor-to-eforms.xslt

target/eforms-sdk-nor/README.md: src/template/README.md
	@echo "* Create README"
	@mkdir -p target/eforms-sdk-nor
	@cat src/template/README.md | VERSION="$(VERSION)" EFORMS_VERSION="$(EFORMS_VERSION)" envsubst > target/eforms-sdk-nor/README.md

target/eforms-sdk-nor/LICENSE-eForms-SDK: target/eforms-sdk/LICENSE
	@echo "* Copy LICENSE (eForms)"
	@mkdir -p target/eforms-sdk-nor
	@cp target/eforms-sdk/LICENSE target/eforms-sdk-nor/LICENSE-eForms-SDK

target/eforms-sdk-nor/LICENSE-eForms-SDK-NOR: src/template/LICENSE
	@echo "* Copy LICENSE (Norway)"
	@mkdir -p target/eforms-sdk-nor
	@cp src/template/LICENSE target/eforms-sdk-nor/LICENSE-eForms-SDK-NOR


target/saxon:
	@echo "* Download Saxon"
	@rm -rf target/saxon
	@mkdir -p target
	@wget -q "https://github.com/Saxonica/Saxon-HE/raw/main/$(SAXON_MAJOR)/Java/SaxonHE$(SAXON_MAJOR)-$(SAXON_MINOR)J.zip" -O target/saxon.zip
	@unzip -q target/saxon.zip -d target/saxon
	@cp target/saxon/saxon-he-$(SAXON_MAJOR).$(SAXON_MINOR).jar target/saxon/saxon.jar
	@rm target/saxon.zip


target/sch: \
	target/sch/eu \
	target/sch/national

target/sch/eu: \
	target/sch/eu/main.sch
	@touch target/sch/eu

target/sch/eu/main.sch: src/template/main.sch
	@mkdir -p target/sch/eu
	@cat src/template/main.sch | VERSION="$(VERSION)" EFORMS_VERSION="$(EFORMS_VERSION)" KIND="eu" envsubst > target/sch/eu/main.sch

target/sch/national: \
	target/sch/national/main.sch
	@touch target/sch/national

target/sch/national/main.sch: src/template/main.sch
	@mkdir -p target/sch/national
	@cat src/template/main.sch | VERSION="$(VERSION)" EFORMS_VERSION="$(EFORMS_VERSION)" KIND="national" envsubst > target/sch/national/main.sch

target/schxslt:
	@mkdir -p target
	@wget -q https://github.com/schxslt/schxslt/releases/download/v1.9.5/schxslt-1.9.5-xslt-only.zip -O target/schxslt.zip
	@unzip -qo target/schxslt.zip -d target
	@rm target/schxslt.zip
	@mv target/schxslt* target/schxslt

sch-to-xslt:
	@java -jar target/saxon/saxon.jar -s:$(src) -xsl:target/schxslt/2.0/pipeline-for-svrl.xsl -o:$(src).xslt