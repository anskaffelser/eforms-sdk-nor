GENERATORS_PATH ?= generators/lib
POLICY_PATH ?= policy/national
EU_CODELIST_PATH ?= codelists
INTERMEDIATE_PATH ?= generated/national
OUTPUT_PATH ?= fields/national.rules.yaml
MAPPING_FILE  = $(POLICY_PATH)/eforms_fields_mapping.yaml
REGISTRY_FILE = $(POLICY_PATH)/rule_id_registry.yaml
FRAGMENT_LICENSE_FILE  = $(POLICY_PATH)/templates/LICENSE_HEADER.fragment.txt
MONOLITH_LICENSE_FILE  = $(POLICY_PATH)/templates/LICENSE_HEADER.monolith.txt

FIELD_SOURCES = $(wildcard $(POLICY_PATH)/fields/*.yaml)
RULE_SOURCES = $(wildcard $(POLICY_PATH)/rules/*.yaml)

FIELD_FRAGMENTS = $(patsubst $(POLICY_PATH)/fields/%.yaml, \
					$(INTERMEDIATE_PATH)/%.fields.fragment.yaml, \
					$(FIELD_SOURCES))

RULE_FRAGMENTS = $(patsubst $(POLICY_PATH)/rules/%.yaml, \
					$(INTERMEDIATE_PATH)/%.rules.fragment.yaml, \
					$(RULE_SOURCES))

.PHONY: all clean

all: 
	$(MAKE) clean
	$(MAKE) $(OUTPUT_PATH)

$(OUTPUT_PATH): $(FIELD_FRAGMENTS) $(RULE_FRAGMENTS)
	@echo "Assembling final policy: $@"
	@ruby $(GENERATORS_PATH)/assemble_national_e_json.rb \
		--input $(INTERMEDIATE_PATH) \
		--output $(OUTPUT_PATH) \
		--template $(MONOLITH_LICENSE_FILE)

$(INTERMEDIATE_PATH)/%.fields.fragment.yaml: $(POLICY_PATH)/fields/%.yaml
	@mkdir -p $(INTERMEDIATE_PATH)
	@echo "Fragmenting field: $*"
	@ruby $(GENERATORS_PATH)/generate_fragments.rb \
		--input $< \
		--output $@ \
		--mapping $(MAPPING_FILE) \
		--registry $(REGISTRY_FILE) \
		--license $(FRAGMENT_LICENSE_FILE) \
		--base $(POLICY_PATH) --eu-codelists $(EU_CODELIST_PATH)

$(INTERMEDIATE_PATH)/%.rules.fragment.yaml: $(POLICY_PATH)/rules/%.yaml
	@mkdir -p $(INTERMEDIATE_PATH)
	@echo "Fragmenting rule: $*"
	@ruby $(GENERATORS_PATH)/generate_fragments.rb \
		--input $< \
		--output $@ \
		--mapping $(MAPPING_FILE) \
		--registry $(REGISTRY_FILE) \
		--license $(FRAGMENT_LICENSE_FILE) \
		--base $(POLICY_PATH) \
		--eu-codelists $(EU_CODELIST_PATH)

clean: 
	@rm -rf $(INTERMEDIATE_PATH)
	@rm -rf $(OUTPUT_PATH)
