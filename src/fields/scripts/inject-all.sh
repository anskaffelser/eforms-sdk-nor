#!/bin/bash

INPUT_YAML="national-e2.yaml"
CODELIST_DIR="code-lists"

yaml_text=$(<"$INPUT_YAML")

# Finn alle {{ ... }} placeholders
placeholders=$(echo "$yaml_text" | grep -o '{{[^}]\+}}' | sort -u)

for placeholder in $placeholders; do
  key=$(echo "$placeholder" | sed 's/^{{\s*//;s/\s*}}$//')
  filepath="$CODELIST_DIR/$key.yaml"

  if [[ -f "$filepath" ]]; then
    regex=$(uv run scripts/generate_regex.py "$filepath" | tr -d '\r\n')

    # Escape spesialtegn for Perl, men IKKE doble fnutter
    escaped=$(printf "%s" "$regex" | perl -pe 's/([\\\/\$\@\%\&\#\!\|\(\)])/\\$1/g')

    # Bruk doble fnutter i YAML
    yaml_text=$(printf "%s" "$yaml_text" | perl -pe "s/\{\{\s*$key\s*\}\}/\"$escaped\"/g")
  else
    echo "Warning: Codelist file '$filepath' not found" >&2
  fi
done

echo "$yaml_text"
