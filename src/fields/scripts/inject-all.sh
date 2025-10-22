#!/bin/bash
set -euo pipefail

INPUT_YAML="national-e2.yaml"
CODELIST_DIR="code-lists"

yaml_text=$(<"$INPUT_YAML")

# Plukk ut placeholders robust: match ALT frem til siste dobbel-lukk
while IFS= read -r placeholder; do
  # Fjern {{ og }} + trim whitespace
  raw=$(sed -E 's/^\{\{\s*//; s/\s*\}\}$//' <<< "$placeholder" | xargs)

  # key = alt før evt. :except:
  key=$(sed -E 's/:.*$//' <<< "$raw" | xargs)

  # except = alt etter :except:
  except=$(sed -nE 's/.*:except:\s*(.*)$/\1/p' <<< "$raw" | xargs)

  # Fjern hermetegn, krøllparenteser, klammer, skråstreker og annet søppel
  except=$(sed -E 's/["'\'']//g; s/[][]//g; s/[}/]//g' <<< "$except" | xargs)

  filepath="$CODELIST_DIR/$key.yaml"

  if [[ -f "$filepath" ]]; then
    regex=$(uv run scripts/generate_regex.py "$filepath" "$except"| tr -d '\r\n')

    # Escape spesialtegn for Perl, men IKKE doble fnutter
    escaped=$(printf "%s" "$regex" | perl -pe 's/([\\\/\$\@\%\&\#\!\|\(\)])/\\$1/g')

    # Bruk doble fnutter i YAML
	yaml_text=$(printf "%s" "$yaml_text" | perl -pe "s/\{\{\s*$key[^}]*\}\}/\"$escaped\"/g")
  else
    echo "Warning: Codelist file '$filepath' not found" >&2
  fi
done < <(grep -oP '\{\{[^}]*\}\}' <<< "$yaml_text" | sort -u)

echo "$yaml_text"
