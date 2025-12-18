GENERATORS_PATH ?= generators/lib
POLICY_PATH ?= policy/national
INTERMEDIATE_GENERATED_PATH ?= generated/national
FINAL_OUTPUT_PATH ?= fields/national.rules.yaml

# Standard mål
default: clean rules

clean: 
	@rm -rf generated
	@rm -rf $(FINAL_OUTPUT_PATH)

intermediate-folder:
	@mkdir -p $(INTERMEDIATE_GENERATED_PATH)

# Hovedmål som kjører alle stegene i Trinn 1, så Trinn 2 (assemble)
rules: intermediate-folder required-languages allowed-languages notice-type-rules mandatory-fields buyer-legal-type-rules
	@ruby $(GENERATORS_PATH)/assemble_complete_national_ruleset.rb

# --- TRINN 1: Generering av fragmenter ---

required-languages:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i constraints/required_languages_constraints.yaml -o required_languages.rules.fragment.yaml

mandatory-fields:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -t mandatory -i fields.yaml -o field-mandatory.rules.fragment.yaml

notice-type-rules:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -t notice_types -i notice_types.yaml -o notice-type.rules.fragment.yaml

allowed-languages:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i constraints/allowed_languages_constraints.yaml -o allowed_languages.rules.fragment.yaml

buyer-legal-type-rules:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -t codelist_rule -i buyer_legal_type.yaml -o buyer-legal-types.rules.fragment.yaml
