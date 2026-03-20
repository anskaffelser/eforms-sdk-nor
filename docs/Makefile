# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026-present The Norwegian Agency for Finance and Public Management (DFØ)

ASCIIDOCTOR ?= bundle exec asciidoctor
PANDOC      ?= pandoc

PAGES_DIR := modules/ROOT/pages
OUT_DIR   := ../build/docs
ENTRY     := notice-identifiers.adoc

.PHONY: html md clean open

html:
	@mkdir -p $(OUT_DIR)
	@$(ASCIIDOCTOR) \
	-D $(OUT_DIR) \
	$(PAGES_DIR)/$(ENTRY)
	@echo "Built HTML: $(OUT_DIR)/$(ENTRY:.adoc=.html)"

md:
	@mkdir -p $(OUT_DIR)
	@$(ASCIIDOCTOR) -b docbook \
	  -D $(OUT_DIR) \
	  $(PAGES_DIR)/$(ENTRY)
	@$(PANDOC) -f docbook -t gfm \
	  -o $(OUT_DIR)/$(ENTRY:.adoc=.md) \
	  $(OUT_DIR)/$(ENTRY:.adoc=.xml)
	@rm $(OUT_DIR)/$(ENTRY:.adoc=.xml)
	@awk -f scripts/number-headings.awk $(OUT_DIR)/$(ENTRY:.adoc=.md) \
	  > /tmp/_numbered.md \
	  && mv /tmp/_numbered.md $(OUT_DIR)/$(ENTRY:.adoc=.md)
	@sed -i '/^<!-- -->$$/d' $(OUT_DIR)/$(ENTRY:.adoc=.md)
	@echo "Built Markdown: $(OUT_DIR)/$(ENTRY:.adoc=.md)"

clean:
	@rm -rf $(OUT_DIR)

open: html
	@xdg-open $(OUT_DIR)/$(ENTRY:.adoc=.html) >/dev/null 2>&1 || true
