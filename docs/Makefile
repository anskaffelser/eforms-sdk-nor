# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026-present The Norwegian Agency for Finance and Public Management (DFØ)

ASCIIDOCTOR ?= bundle exec asciidoctor

PAGES_DIR := modules/ROOT/pages
OUT_DIR   := ../build/docs
ENTRY     := notice-identifiers.adoc

.PHONY: html clean open

html:
	@mkdir -p $(OUT_DIR)
	@$(ASCIIDOCTOR) \
	  -D $(OUT_DIR) \
	  $(PAGES_DIR)/$(ENTRY)
	@echo "Built: $(OUT_DIR)/$(ENTRY:.adoc=.html)"

clean:
	@rm -rf $(OUT_DIR)

open: html
	@xdg-open $(OUT_DIR)/$(ENTRY:.adoc=.html) >/dev/null 2>&1 || true

