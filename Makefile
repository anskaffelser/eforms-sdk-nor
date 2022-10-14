EFORMS_MINOR=1.2
EFORMS_PATCH=0
EFORMS_VERSION=$(EFORMS_MINOR).$(EFORMS_PATCH)

VERSION := $(shell echo -n $${PROJECT_VERSION:-dev-$$(date -u +%Y%m%d-%H%M%Sz)})

default: clean-light build

clean-light:
	@rm -rf target/eforms-sdk-nor

clean:
	@rm -rf target .bundle/vendor

build: target/eforms-sdk-nor
	@./bin/create-codelists
	@./bin/create-translations

extract: .bundle/vendor target/eforms-sdk
	@./bin/extract-codelists
	@./bin/extract-translations
	@rm src/translations/rule.yaml

update-code: .bundle/vendor
	@./bin/update-code

status: .bundle/vendor
	@./bin/translation-status src/codelists src/translations

package: package-tgz package-zip

package-tgz:
	@rm -f target/eforms-sdk-nor-*.tar.gz
	@cd target/eforms-sdk-nor && tar -czf ../eforms-sdk-nor-$(VERSION).tar.gz *

package-zip:
	@rm -f target/eforms-sdk-nor-*.zip
	@cd target/eforms-sdk-nor && zip -q9r ../eforms-sdk-nor-$(VERSION).zip *

target/eforms-sdk:
	@echo "* Downloading eForms SDK"
	@mkdir -p target
	@wget -q https://github.com/OP-TED/eForms-SDK/archive/refs/tags/$(EFORMS_VERSION).zip -O target/eforms-sdk.zip
	@unzip -qo target/eforms-sdk.zip -d target
	@mv target/eForms-SDK-$(EFORMS_VERSION) target/eforms-sdk
	@rm -rf target/eforms-sdk.zip

.bundle/vendor:
	@echo "* Install dependencies"
	@bundle install --path=.bundle/vendor

target/eforms-sdk-nor: \
	target/eforms-sdk-nor/efx-grammar \
	target/eforms-sdk-nor/fields \
	target/eforms-sdk-nor/notice-types \
	target/eforms-sdk-nor/schemas \
	target/eforms-sdk-nor/schematrons \
	target/eforms-sdk-nor/translations \
	target/eforms-sdk-nor/view-templates

target/eforms-sdk-nor/efx-grammar: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/efx-grammar target/eforms-sdk-nor/efx-grammar

target/eforms-sdk-nor/fields: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/fields target/eforms-sdk-nor/fields

target/eforms-sdk-nor/notice-types: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/notice-types target/eforms-sdk-nor/notice-types

target/eforms-sdk-nor/schemas: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/schemas target/eforms-sdk-nor/schemas

target/eforms-sdk-nor/schematrons: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/schematrons target/eforms-sdk-nor/schematrons

target/eforms-sdk-nor/translations: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/translations target/eforms-sdk-nor/translations

target/eforms-sdk-nor/view-templates: target/eforms-sdk
	@mkdir -p target/eforms-sdk-nor
	@cp -r target/eforms-sdk/view-templates target/eforms-sdk-nor/view-templates