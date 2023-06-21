EFORMS_MINOR ?= $$(./bin/property -p sdk_minor)
EFORMS_PATCH ?= $$(./bin/property -p sdk_patch)
EFORMS_VERSION = $(EFORMS_MINOR).$(EFORMS_PATCH)

VERSION := $(shell echo $${PROJECT_VERSION:-dev-$$(date -u +%Y%m%d-%H%M%Sz)})

SAXON_MAJOR ?= 12
SAXON_MINOR ?= 2

default: clean-light build

clean-light:
	@rm -rf target/eforms-sdk-nor target/sch target/*.asice target/buildconfig.xml target/eforms-sdk/schemas/all.xsd target/tests

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
	@test ! -d src/patch/$(EFORMS_MINOR) || patch --directory=target/eforms-sdk -p1 < $$(ls src/patch/$(EFORMS_MINOR)/*.patch)

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
	@echo "* Copy EFX grammar"
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/efx-grammar target/eforms-sdk-nor/efx-grammar

target/eforms-sdk-nor/fields: \
	target/eforms-sdk-nor/fields/eu.json \
	target/eforms-sdk-nor/fields/national.json

target/eforms-sdk-nor/fields/eu.json: target/eforms-sdk bin/process-fields src/fields/eu.yaml
	@echo "* Create fields subset (eu)"
	@mkdir -p target/eforms-sdk-nor/fields
	@ruby bin/process-fields \
		-i target/eforms-sdk/fields/fields.json \
		-c src/fields/eu.yaml \
		-o target/eforms-sdk-nor/fields/eu.json

target/eforms-sdk-nor/fields/national.json: target/eforms-sdk bin/process-fields src/fields/national.yaml
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
	target/eforms-sdk-nor/schematrons/eu-eforms-dynamic.sch \
	target/eforms-sdk-nor/schematrons/eu-eforms-static.sch \
	target/eforms-sdk-nor/schematrons/national-eforms-dynamic.sch \
	target/eforms-sdk-nor/schematrons/national-eforms-static.sch \
	target/eforms-sdk-nor/schematrons/eu-norway.sch \
	target/eforms-sdk-nor/schematrons/national-norway.sch

target/sch-eforms/eforms-dynamic.sch: target/eforms-sdk target/saxon src/xslt/sch-switch-message.xslt
	@echo "* Preparing Schematron: eforms-dynamic.sch"
	@mkdir -p target/sch-eforms
	@java -jar target/saxon/saxon.jar -s:target/eforms-sdk/schematrons/dynamic/complete-validation.sch -xsl:src/xslt/sch-include.xslt \
	| java -jar target/saxon/saxon.jar -s:- -xsl:src/xslt/sch-switch-message.xslt -o:target/sch-eforms/eforms-dynamic.sch

target/sch-eforms/eforms-static.sch: target/eforms-sdk target/saxon src/xslt/sch-switch-message.xslt
	@echo "* Preparing Schematron: eforms-static.sch"
	@mkdir -p target/sch-eforms
	@java -jar target/saxon/saxon.jar -s:target/eforms-sdk/schematrons/static/complete-validation.sch -xsl:src/xslt/sch-include.xslt \
	| java -jar target/saxon/saxon.jar -s:- -xsl:src/xslt/sch-switch-message.xslt -o:target/sch-eforms/eforms-static.sch

target/eforms-sdk-nor/schematrons/eu-eforms-dynamic.sch: target/sch-eforms/eforms-dynamic.sch src/xslt/sch-cleanup-eu.xslt
	@echo "* Preparing Schematron: eu-eforms-dynamic.sch"
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon.jar -s:target/sch-eforms/eforms-dynamic.sch -xsl:src/xslt/sch-cleanup-eu.xslt -o:target/eforms-sdk-nor/schematrons/eu-eforms-dynamic.sch

target/eforms-sdk-nor/schematrons/eu-eforms-static.sch: target/sch-eforms/eforms-static.sch src/xslt/sch-cleanup-eu.xslt
	@echo "* Preparing Schematron: eu-eforms-static.sch"
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon.jar -s:target/sch-eforms/eforms-static.sch -xsl:src/xslt/sch-cleanup-eu.xslt -o:target/eforms-sdk-nor/schematrons/eu-eforms-static.sch

target/eforms-sdk-nor/schematrons/national-eforms-dynamic.sch: target/sch-eforms/eforms-dynamic.sch src/xslt/sch-cleanup-national.xslt
	@echo "* Preparing Schematron: national-eforms-dynamic.sch"
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon.jar -s:target/sch-eforms/eforms-dynamic.sch -xsl:src/xslt/sch-cleanup-national.xslt -o:target/eforms-sdk-nor/schematrons/national-eforms-dynamic.sch

target/eforms-sdk-nor/schematrons/national-eforms-static.sch: target/sch-eforms/eforms-static.sch src/xslt/sch-cleanup-national.xslt
	@echo "* Preparing Schematron: national-eforms-static.sch"
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon.jar -s:target/sch-eforms/eforms-static.sch -xsl:src/xslt/sch-cleanup-national.xslt -o:target/eforms-sdk-nor/schematrons/national-eforms-static.sch

target/eforms-sdk-nor/schematrons/eu-norway.sch: target/saxon target/sch/eu/main.sch
	@echo "* Preparing Schematron: eu-norway.sch"
	@java -jar target/saxon/saxon.jar \
		-s:target/sch/eu/main.sch \
		-xsl:src/xslt/sch-include.xslt \
		-o:target/eforms-sdk-nor/schematrons/eu-norway.sch 

target/eforms-sdk-nor/schematrons/national-norway.sch: target/saxon target/sch/national/main.sch
	@echo "* Preparing Schematron: national-norway.sch"
	@java -jar target/saxon/saxon.jar \
		-s:target/sch/national/main.sch \
		-xsl:src/xslt/sch-include.xslt \
		-o:target/eforms-sdk-nor/schematrons/national-norway.sch

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


target/sch: target/sch/eu/main.sch target/sch/national/main.sch

target/sch/eu/main.sch: target/sch/eu/fields.sch src/template/main.sch
	@mkdir -p target/sch/eu
	@cat src/template/main.sch | VERSION="$(VERSION)" EFORMS_VERSION="$(EFORMS_VERSION)" KIND="eu" envsubst > target/sch/eu/main.sch

target/sch/eu/fields.sch: target/eforms-sdk-nor/fields/eu.json bin/fields-sch
	@mkdir -p target/sch/eu
	@./bin/fields-sch -i target/eforms-sdk-nor/fields/eu.json -o target/sch/eu/fields.sch

target/sch/national/main.sch: target/sch/national/fields.sch src/template/main.sch
	@mkdir -p target/sch/national
	@cat src/template/main.sch | VERSION="$(VERSION)" EFORMS_VERSION="$(EFORMS_VERSION)" KIND="national" envsubst > target/sch/national/main.sch

target/sch/national/fields.sch: target/eforms-sdk-nor/fields/national.json bin/fields-sch
	@mkdir -p target/sch/national
	@./bin/fields-sch -i target/eforms-sdk-nor/fields/national.json -o target/sch/national/fields.sch

target/schxslt:
	@mkdir -p target
	@wget -q https://github.com/schxslt/schxslt/releases/download/v1.9.5/schxslt-1.9.5-xslt-only.zip -O target/schxslt.zip
	@unzip -qo target/schxslt.zip -d target
	@rm target/schxslt.zip
	@mv target/schxslt* target/schxslt

target/iso-schematron:
	@mkdir -p target
	@wget -q https://github.com/Schematron/schematron/releases/download/2020-10-01/iso-schematron-xslt2.zip -O target/iso-schematron.zip
	@unzip -qo target/iso-schematron.zip -d target/iso-schematron

target/buildconfig.xml: \
	target/sch/eu-eforms-static-can.xslt \
	target/sch/eu-eforms-static-cn.xslt \
	target/sch/eu-eforms-static-pin.xslt \
	target/sch/eu-norway.xslt \
	target/sch/national-eforms-static.xslt \
	target/sch/national-norway.xslt \
	src/template/buildconfig.xml
	@mkdir -p target
	@cat src/template/buildconfig.xml | EFORMS_MINOR="$(EFORMS_MINOR)" envsubst > target/buildconfig.xml


target/sch/eu-eforms-static-can.sch: src/xslt/sch-splitter.xslt target/eforms-sdk-nor/schematrons/eu-eforms-static.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/sch-splitter.xslt \
		-s:target/eforms-sdk-nor/schematrons/eu-eforms-static.sch \
		-o:target/sch/eu-eforms-static-can.sch \
		target=can

target/sch/eu-eforms-static-cn.sch: src/xslt/sch-splitter.xslt target/eforms-sdk-nor/schematrons/eu-eforms-static.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/sch-splitter.xslt \
		-s:target/eforms-sdk-nor/schematrons/eu-eforms-static.sch \
		-o:target/sch/eu-eforms-static-cn.sch \
		target=cn

target/sch/eu-eforms-static-pin.sch: src/xslt/sch-splitter.xslt target/eforms-sdk-nor/schematrons/eu-eforms-static.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/sch-splitter.xslt \
		-s:target/eforms-sdk-nor/schematrons/eu-eforms-static.sch \
		-o:target/sch/eu-eforms-static-pin.sch \
		target=pin


target/sch/eu-eforms-static-can.xslt: target/iso-schematron src/xslt/prepare-validator.xslt target/sch/eu-eforms-static-can.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/prepare-validator.xslt \
		-s:target/sch/eu-eforms-static-can.sch \
	| java -jar target/saxon/saxon.jar \
		-xsl:target/iso-schematron/iso_svrl_for_xslt2.xsl \
		-s:- \
		-o:target/sch/eu-eforms-static-can.xslt

target/sch/eu-eforms-static-cn.xslt: target/iso-schematron src/xslt/prepare-validator.xslt target/sch/eu-eforms-static-cn.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/prepare-validator.xslt \
		-s:target/sch/eu-eforms-static-cn.sch \
	| java -jar target/saxon/saxon.jar \
		-xsl:target/iso-schematron/iso_svrl_for_xslt2.xsl \
		-s:- \
		-o:target/sch/eu-eforms-static-cn.xslt

target/sch/eu-eforms-static-pin.xslt: target/iso-schematron src/xslt/prepare-validator.xslt target/sch/eu-eforms-static-pin.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/prepare-validator.xslt \
		-s:target/sch/eu-eforms-static-pin.sch \
	| java -jar target/saxon/saxon.jar \
		-xsl:target/iso-schematron/iso_svrl_for_xslt2.xsl \
		-s:- \
		-o:target/sch/eu-eforms-static-pin.xslt

target/sch/national-eforms-static.xslt: target/iso-schematron src/xslt/prepare-validator.xslt target/eforms-sdk-nor/schematrons/national-eforms-static.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/prepare-validator.xslt \
		-s:target/eforms-sdk-nor/schematrons/national-eforms-static.sch \
	| java -jar target/saxon/saxon.jar \
		-xsl:target/iso-schematron/iso_svrl_for_xslt2.xsl \
		-s:- \
		-o:target/sch/national-eforms-static.xslt
	
target/sch/eu-norway.xslt: target/iso-schematron src/xslt/prepare-validator.xslt target/eforms-sdk-nor/schematrons/eu-norway.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/prepare-validator.xslt \
		-s:target/eforms-sdk-nor/schematrons/eu-norway.sch \
	| java -jar target/saxon/saxon.jar \
		-xsl:target/iso-schematron/iso_svrl_for_xslt2.xsl \
		-s:- \
		-o:target/sch/eu-norway.xslt

target/sch/national-norway.xslt: target/iso-schematron src/xslt/prepare-validator.xslt target/eforms-sdk-nor/schematrons/national-norway.sch
	@mkdir -p target/sch
	@java -jar target/saxon/saxon.jar \
		-xsl:src/xslt/prepare-validator.xslt \
		-s:target/eforms-sdk-nor/schematrons/national-norway.sch \
	| java -jar target/saxon/saxon.jar \
		-xsl:target/iso-schematron/iso_svrl_for_xslt2.xsl \
		-s:- \
		-o:target/sch/national-norway.xslt

target/dev.anskaffelser.eforms.sdk-nor.asice: target/buildconfig.xml # $$(find src/tests -type f)
	@echo "* Build and test for validator"
	@rm -rf target/tests target/*.asice
	@for f in $$(find src/tests -type f); do file=$$(echo $$f | cut -d'/' -f2-); mkdir -p target/$$(dirname $$file); cat $$f | EFORMS_MINOR="$(EFORMS_MINOR)" envsubst > target/$$file; done
	@docker run --rm -i \
		-v $$(pwd)/target:/src \
		-u $$(id -u):$$(id -g) \
		anskaffelser/validator:edge build \
		 -x -t -n dev.anskaffelser.eforms.sdk-$(EFORMS_MINOR)-nor -b $(VERSION) -target validator-target /src || true
	@mv target/validator-target/dev.anskaffelser.eforms.sdk-$(EFORMS_MINOR)-nor-$(VERSION).asice target/
	@rm -rf target/validator-target

validator: target/dev.anskaffelser.eforms.sdk-nor.asice