GENERATORS_PATH ?= generators/lib
POLICY_PATH ?= policy/national
EU_CODELIST_PATH ?= codelists
INTERMEDIATE_PATH ?= generated/national
OUTPUT_PATH ?= fields/national.rules.yaml
MAPPING_FILE  = $(POLICY_PATH)/eforms_fields_mapping.yaml
REGISTRY_FILE = $(POLICY_PATH)/rule_id_registry.yaml
FRAGMENT_LICENSE_FILE  = $(POLICY_PATH)/templates/LICENSE_HEADER.fragment.txt
MONOLITH_LICENSE_FILE  = $(POLICY_PATH)/templates/LICENSE_HEADER.monolith.txt

FIELDS_PATH = $(POLICY_PATH)/fields
RULES_PATH = $(POLICY_PATH)/rules

FIELD_SOURCES = $(wildcard $(FIELDS_PATH)/*.yaml)
RULE_SOURCES = $(wildcard $(RULES_PATH)/*.yaml)

FIELD_FRAGMENTS = $(patsubst $(POLICY_PATH)/fields/%.yaml, \
					$(INTERMEDIATE_PATH)/%.fields.fragment.yaml, \
					$(FIELD_SOURCES))

RULE_FRAGMENTS = $(patsubst $(POLICY_PATH)/rules/%.yaml, \
					$(INTERMEDIATE_PATH)/%.rules.fragment.yaml, \
					$(RULE_SOURCES))

LOVDATA_SYNC_SCRIPT ?= scripts/sync_lovdata.py
LOVDATA_JOB_CONFIG ?= config/lovdata_jobs.yaml
LOVDATA_HEADER_TEMPLATE ?= config/lovdata_header_template.txt

EXTERNAL_API_DATA_PATH ?= data

.PHONY: all clean sync-cpv

all: 
	$(MAKE) clean
	$(MAKE) $(OUTPUT_PATH)

SYNC-LOVDATA-CPV:
	uv run $(LOVDATA_SYNC_SCRIPT) \
		--config-file $(LOVDATA_JOB_CONFIG) \
		--job-id lovdata_foa_cpv_parser \
		--header-template $(LOVDATA_HEADER_TEMPLATE)

$(OUTPUT_PATH): $(FIELD_FRAGMENTS) $(RULE_FRAGMENTS)
	@echo "Assembling final policy: $@"
	@ruby $(GENERATORS_PATH)/assemble_national_e_json.rb \
		--input $(INTERMEDIATE_PATH) \
		--output $(OUTPUT_PATH) \
		--template $(MONOLITH_LICENSE_FILE) \
		--notice_type $(RULES_PATH)/notice_type.yaml

$(INTERMEDIATE_PATH)/%.fields.fragment.yaml: $(FIELDS_PATH)/%.yaml
	@mkdir -p $(INTERMEDIATE_PATH)
	@echo "Fragmenting field: $*"
	@ruby $(GENERATORS_PATH)/generate_fragments.rb \
		--input $< \
		--output $@ \
		--mapping $(MAPPING_FILE) \
		--registry $(REGISTRY_FILE) \
		--license $(FRAGMENT_LICENSE_FILE) \
		--base $(POLICY_PATH) \
		--eu-codelists $(EU_CODELIST_PATH) \
		--external-data $(EXTERNAL_API_DATA_PATH)

$(INTERMEDIATE_PATH)/%.rules.fragment.yaml: $(RULES_PATH)/%.yaml $(EXTERNAL_API_DATA_PATH)/foa_cpv_registry.yaml
	@mkdir -p $(INTERMEDIATE_PATH)
	@echo "Fragmenting rule: $*"
	@ruby $(GENERATORS_PATH)/generate_fragments.rb \
		--input $< \
		--output $@ \
		--mapping $(MAPPING_FILE) \
		--registry $(REGISTRY_FILE) \
		--license $(FRAGMENT_LICENSE_FILE) \
		--base $(POLICY_PATH) \
		--eu-codelists $(EU_CODELIST_PATH) \
		--external-data $(EXTERNAL_API_DATA_PATH)

clean: 
	@rm -rf $(INTERMEDIATE_PATH)
	@rm -rf $(OUTPUT_PATH)
