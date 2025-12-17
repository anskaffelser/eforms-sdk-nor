GENERATORS_PATH ?= generators/lib
POLICY_PATH ?= policy/national
RULESET_SOURCES_PATH ?= ruleset_sources/national

INTERMEDIATE_GENERATED_PATH ?= generated/national
FINAL_OUTPUT_PATH ?= fields/national.rules.yaml

default: clean rules

clean: 
	@rm -rf generated
	@rm -rf $(FINAL_OUTPUT_PATH)

intermediate-folder:
	@mkdir -p $(INTERMEDIATE_GENERATED_PATH)

rules: intermediate-folder document-rules language-rules legal_basis_rules notice_type_rules
	ruby generators/lib/assemble_complete_national_ruleset.rb

document-rules: policy/national/document_rules.yaml
	ruby generators/lib/document_rules.rb

language-rules: codelists/eu-official-language.yaml policy/national/languages.yaml
	ruby generators/lib/language_rules.rb

legal_basis_intermediate: ruleset_sources/national/national-procedure-legal-basis-ssot.yaml ruleset_sources/national/national-procurement-regulations-codelist.yaml ruleset_sources/national/texts/national-procedure-legal-basis-text-template.yaml
	ruby generators/lib/legal_basis.rb


legal_basis_rules: legal_basis_intermediate
	ruby generators/lib/legal_basis_rules.rb

notice_type_rules: policy/national/notice_types.yaml
	ruby generators/lib/notice_type_rules.rb

profile_rules: policy/national/profiles.yaml
	ruby generators/lib/profile_rules.rb
