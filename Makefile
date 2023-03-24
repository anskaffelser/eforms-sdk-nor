EFORMS_MINOR ?= $$(./bin/property -p sdk_minor)
EFORMS_PATCH ?= $$(./bin/property -p sdk_patch)
EFORMS_VERSION = $(EFORMS_MINOR).$(EFORMS_PATCH)

VERSION := $(shell echo -n $${PROJECT_VERSION:-dev-$$(date -u +%Y%m%d-%H%M%Sz)})

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
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/create-codelists
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/create-translations
	@EFORMS_VERSION=$(EFORMS_VERSION) ./bin/create-translations --complete

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

target/eforms-sdk: .bundle/vendor
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

target/eforms-sdk-nor/efx-grammar: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/efx-grammar target/eforms-sdk-nor/efx-grammar

target/eforms-sdk-nor/fields: \
	target/eforms-sdk-nor/fields/above.json \
	target/eforms-sdk-nor/fields/below.json

target/eforms-sdk-nor/fields/above.json: target/eforms-sdk bin/process-fields
	@mkdir -p target/eforms-sdk-nor/fields
	@ruby bin/process-fields \
		-i target/eforms-sdk/fields/fields.json \
		-c src/fields/above.yaml \
		-o target/eforms-sdk-nor/fields/above.json

target/eforms-sdk-nor/fields/below.json: target/eforms-sdk bin/process-fields
	@mkdir -p target/eforms-sdk-nor/fields
	@ruby bin/process-fields \
		-i target/eforms-sdk/fields/fields.json \
		-c src/fields/below.yaml \
		-o target/eforms-sdk-nor/fields/below.json

target/eforms-sdk-nor/notice-types: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/notice-types target/eforms-sdk-nor/notice-types

target/eforms-sdk-nor/schemas: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/schemas target/eforms-sdk-nor/schemas

target/eforms-sdk-nor/schematrons: \
	target/eforms-sdk-nor/schematrons/eforms-dynamic.sch \
	target/eforms-sdk-nor/schematrons/eforms-static.sch

target/eforms-sdk-nor/schematrons/eforms-dynamic.sch: target/eforms-sdk target/saxon src/xslt/sch-cleanup.xslt
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon-he-12.1.jar -s:target/eforms-sdk/schematrons/dynamic/complete-validation.sch -xsl:bin/xslt/sch-include.xslt \
	| java -jar target/saxon/saxon-he-12.1.jar -s:- -xsl:src/xslt/sch-cleanup.xslt -o:target/eforms-sdk-nor/schematrons/eforms-dynamic.sch

target/eforms-sdk-nor/schematrons/eforms-static.sch: target/eforms-sdk target/saxon src/xslt/sch-cleanup.xslt
	@mkdir -p target/eforms-sdk-nor/schematrons
	@java -jar target/saxon/saxon-he-12.1.jar -s:target/eforms-sdk/schematrons/static/complete-validation.sch -xsl:bin/xslt/sch-include.xslt \
	| java -jar target/saxon/saxon-he-12.1.jar -s:- -xsl:src/xslt/sch-cleanup.xslt -o:target/eforms-sdk-nor/schematrons/eforms-static.sch

target/eforms-sdk-nor/translations: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/translations target/eforms-sdk-nor/translations

target/eforms-sdk-nor/view-templates: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/view-templates target/eforms-sdk-nor/view-templates

target/eforms-sdk-nor/xslt: \
	target/eforms-sdk-nor/xslt/nor-to-eforms.xslt

target/eforms-sdk-nor/xslt/nor-to-eforms.xslt:
	@mkdir -p target/eforms-sdk-nor/xslt
	@cp src/xslt/nor-to-eforms.xslt target/eforms-sdk-nor/xslt/nor-to-eforms.xslt

target/eforms-sdk-nor/README.md: src/template/README.md
	@mkdir -p target/eforms-sdk-nor
	@cat src/template/README.md | VERSION="$(VERSION)" EFORMS_VERSION="$(EFORMS_VERSION)" envsubst > target/eforms-sdk-nor/README.md

target/eforms-sdk-nor/LICENSE-eForms-SDK: target/eforms-sdk/LICENSE
	@mkdir -p target/eforms-sdk-nor
	@cp target/eforms-sdk/LICENSE target/eforms-sdk-nor/LICENSE-eForms-SDK

target/eforms-sdk-nor/LICENSE-eForms-SDK-NOR: src/template/LICENSE
	@mkdir -p target/eforms-sdk-nor
	@cp src/template/LICENSE target/eforms-sdk-nor/LICENSE-eForms-SDK-NOR

target/saxon:
	@echo "Download Saxon"
	@mkdir -p target
	@wget -q "https://github.com/Saxonica/Saxon-HE/raw/main/12/Java/SaxonHE12-1J.zip" -O target/saxon.zip
	@unzip target/saxon.zip -d target/saxon
	@rm target/saxon.zip
