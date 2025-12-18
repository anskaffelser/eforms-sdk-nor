GENERATORS_PATH ?= generators/lib
POLICY_PATH ?= policy/national
INTERMEDIATE_GENERATED_PATH ?= generated/national
FINAL_OUTPUT_PATH ?= fields/national.rules.yaml

# Standard mål
default: clean national-e.json

clean: 
	@rm -rf generated
	@rm -rf $(FINAL_OUTPUT_PATH)

intermediate-folder:
	@mkdir -p $(INTERMEDIATE_GENERATED_PATH)

national-e.json: intermediate-folder fields rules
	@ruby $(GENERATORS_PATH)/assemble_national_e_json.rb

# --- TRINN 1: Generering av fragmenter ---
fields: fields/legal-basis-no-id fields/buyer-legal-type

fields/legal-basis-no-id:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i requirements/legal_basis_noid.yaml -o legal-basis-noid.fields.fragment.yaml

fields/buyer-legal-type:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i requirements/buyer_legal_type.yaml -o buyer-legal-type.fields.fragment.yaml

rules: rules/required-languages rules/notice-type rules/allowed-languages rules/buyer-legal-type

rules/required-languages:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i constraints/required_languages_constraints.yaml -o required_languages.rules.fragment.yaml


rules/notice-type:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i constraints/notice_type_constraints.yaml -o notice-type.rules.fragment.yaml

rules/allowed-languages:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -i constraints/allowed_languages_constraints.yaml -o allowed_languages.rules.fragment.yaml

rules/buyer-legal-type:
	@ruby $(GENERATORS_PATH)/generate_fragments.rb -t codelist_rule -i buyer_legal_type.yaml -o buyer-legal-types.rules.fragment.yaml
