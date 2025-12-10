# SPDX-License-Identifier: Apache-2.0
#
# This file is part of the eforms-sdk-nor project.
# Copyright © 2025 DFØ – The Norwegian Agency for Public and Financial
#                        Management
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissinos and
# limitations under the License

#!/usr/bin/env python3

import yaml
import re
from bs4 import BeautifulSoup, Tag
from pathlib import Path
from collections.abc import Mapping, Sequence

# --- KONFIGURASJON ---
PROJECT_ROOT = Path(__file__).resolve().parent

CPV_YAML_PATH = PROJECT_ROOT / 'src' / 'codelists' / 'cpv.yaml'
XML_INPUT_PATH = PROJECT_ROOT / 'src'/ 'fields' /  'national-legal-specifics' / 'sf-20160812-0974.xml'
OUTPUT_DIR = PROJECT_ROOT / 'src' / 'fields' / 'national-legal-specifics' 

# Mapping av vedleggsnummer til filnavn og metadata
ANNEX_CONFIG = {
    '1': {
        'filename': 'annex-1-works.yaml',
        'name': 'Bygge- og anleggsaktiviteter',
        'source': 'FOA Vedlegg 1',
        'type': 'works'
    },
    '2': {
        'filename': 'annex-2-services.yaml',
        'name': 'Særlige tjenester',
        'source': 'FOA Vedlegg 2',
        'type': 'services'
    },
    '3': {
        'filename': 'annex-3-services.yaml',
        'name': 'Helse- og sosialtjenester',
        'source': 'FOA Vedlegg 3',
        'type': 'services'
    },
    '4': {
        'filename': 'annex-4-services.yaml',
        'name': 'Helse- og sosialtjenester som er omfattet av § 30-2',
        'source': 'FOA Vedlegg 4',
        'type': 'services'
    }
}
# --------------------


# --- HJELPEKLASSE & FUNKSJONER FOR TVUNGEN SITERING AV VERDIER (UENDRET) ---

class QuotedString(str):
    """En streng-underklasse som tvinger PyYAML til å bruke dobbeltfnutter."""
    pass

def represent_quoted_string(dumper, data):
    """Representerer en QuotedString med tvungen dobbeltfnutt-stil."""
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')

yaml.add_representer(QuotedString, represent_quoted_string)


def quote_values_recursively(data):
    """Rekursiv funksjon for å konvertere strengverdier til QuotedString, men lar nøkler være vanlige strenger."""
    if isinstance(data, Mapping):
        return {k: quote_values_recursively(v) for k, v in data.items()}
    elif isinstance(data, Sequence) and not isinstance(data, str):
        return [quote_values_recursively(elem) for elem in data]
    elif isinstance(data, str):
        return QuotedString(data)
    return data

# ------------------------------------------------------------------

def parse_table_rows(table: Tag, cpv_lookup_map: dict, annex_number: str) -> list:
    """
    Henter og behandler rader fra en gitt BeautifulSoup-tabell-tag.
    Håndterer den spesielle 5-kolonners strukturen i Vedlegg 1.
    """
    tbody = table.find('tbody')
    if not tbody:
         print("FEIL: Fant ingen <tbody>-tag inne i tabellen.")
         return []
         
    rows = tbody.find_all('tr')
    services = []
    
    is_annex_1 = annex_number == '1'
    
    for row in rows:
        cols = row.find_all('td')
        
        # Filtrerer bort tomme rader. Vi trenger minst én CPV-kolonne.
        if is_annex_1 and len(cols) < 5:
            # Vedlegg 1 har typisk 5 kolonner, men kan ha færre på aggregerte rader
            # For Vedlegg 1: Vi må sjekke at vi har en kolonne for CPV-kode/intervall
            cpv_col_text = cols[4].get_text(strip=True) if len(cols) > 4 else cols[0].get_text(strip=True)
            if not cpv_col_text:
                 continue
        elif not is_annex_1 and len(cols) < 2:
            continue
            
        service_item = {}
        lookup_code = None

        if is_annex_1:
            # For Vedlegg 1: CPV-kode og unntak er i den Siste kolonnen (indeks 4)
            cpv_and_exclusion_col = cols[4].get_text('\n', strip=True)
            
            # Bruk regex for å splitte opp i CPV-koder og unntakstekst
            cpv_codes = re.findall(r'\b\d{8}\b', cpv_and_exclusion_col)
            exclusion_codes = re.findall(r'Unntatt:.*?((?:-\s*\d{8}\s*)+)', cpv_and_exclusion_col, re.DOTALL | re.IGNORECASE)
            
            # Henter den første koden som hovedkode for oppslag (typisk den som står først)
            if not cpv_codes:
                 continue
                 
            primary_code = cpv_codes[0]
            
            # Sjekk for intervall (ikke vanlig i Vedlegg 1, men sikrer robusthet)
            # Vi må behandle intervall fra en separat kilde siden den fysiske koden mangler. 
            # Vi antar her at det enten er enkeltkode eller at intervall-informasjon finnes 
            # i en av de andre kolonnene (f.eks. i 45,3-rader)
            # Siden Vedlegg 1 har en "Kode" i kolonne 3 (NACE-kode), bruker vi primary_code
            # for oppslag mot cpv.yaml og lagrer som enkeltkode.
            
            service_item['cpv_code'] = primary_code
            lookup_code = primary_code
            
            # Håndter unntak (fra regex-resultatet)
            if exclusion_codes:
                # Plukk ut CPV-kodene fra unntaksteksten (fjerner - eller lignende)
                flat_exclusions = re.findall(r'\d{8}', "".join(exclusion_codes))
                if flat_exclusions:
                    service_item['exclusions'] = flat_exclusions


        else: 
            # Vedlegg 2, 3 og 4: Standard 2-kolonners layout (eller lignende kompakt)
            cpv_text = cols[0].get_text(strip=True)
            
            # Håndter intervall (Uendret logikk)
            if re.search(r'–|-', cpv_text):
                try:
                    start, end = re.split(r'[–-]', cpv_text)
                except ValueError:
                    print(f"Advarsel: Klarte ikke splitte intervall '{cpv_text}'. Hopper over.")
                    continue

                service_item['cpv_start'] = start.strip()
                service_item['cpv_end'] = end.strip()
                lookup_code = service_item['cpv_start']
                
            else:
                lookup_code = cpv_text.strip()
                service_item['cpv_code'] = lookup_code
        
        
        # Felles: Hent beskrivelser (Basert på lookup_code)
        if not lookup_code:
            continue
            
        descriptions = cpv_lookup_map.get(lookup_code)
        
        if not descriptions:
            print(f"ADVARSEL: Fant ikke beskrivelse for '{lookup_code}' i cpv.yaml. Sjekk kodelisten. Hopper over.")
            continue

        service_item['description'] = {
            'name': descriptions.get('name', 'N/A'),
            'nob': descriptions.get('nob', 'N/A')
        }
        
        services.append(service_item)
        
    return services


def extract_services_for_annex(soup: BeautifulSoup, annex_number: str, cpv_lookup_map: dict) -> dict | None:
    """
    Finner seksjonen for et gitt vedlegg (f.eks. '1', '2', '3', '4') og ekstraherer tjenestene.
    (Uendret logikk)
    """
    annex_identifier = f'Vedlegg {annex_number}'
    
    # 1. Finn seksjonen/artikkelen
    annex_section = soup.find(lambda tag: tag.name in ['section', 'article'] and annex_identifier in tag.get_text())
    
    if not annex_section:
        # Fallback: Prøv å finne via lenke/ID
        vedlegg_link = soup.find('a', string=re.compile(rf'{re.escape(annex_identifier)}\.'))
        if vedlegg_link and vedlegg_link.get('href'):
            target_id = vedlegg_link['href'].lstrip('#')
            annex_section = soup.find(id=target_id)
            
    if not annex_section:
        print(f"FEIL: Klarte ikke å finne HTML-seksjonen for '{annex_identifier}'. Hopper over dette vedlegget.")
        return None

    # 2. Finn tabellen inne i seksjonen
    table = annex_section.find('table')
    
    if not table:
        print(f"FEIL: Fant ingen <table>-tag inne i {annex_identifier}-seksjonen. Hopper over dette vedlegget.")
        return None
        
    # 3. Pars tabellrader
    final_services = parse_table_rows(table, cpv_lookup_map, annex_number)
    
    # 4. Bygg og returner data-strukturen
    metadata = ANNEX_CONFIG.get(annex_number, {})
    return {
        'annex': {
            'name': metadata.get('name', annex_identifier),
            'source': metadata.get('source', 'FOA'),
            'type': metadata.get('type', 'generic'),
            'services': final_services
        }
    }


def parse_html_and_generate_yaml():
    """Hovedfunksjon: Koordinerer parsing av alle vedlegg og dumper til separate filer."""
    
    # 1. Last inn autoritativ CPV-data
    try:
        with open(CPV_YAML_PATH, 'r', encoding='utf-8') as f:
            CPV_LOOKUP_MAP = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"FEIL: Fant ikke CPV-kodelistefilen på {CPV_YAML_PATH}")
        return
    except yaml.YAMLError as e:
        print(f"FEIL: Kunne ikke parse CPV YAML-filen: {e}")
        return
        
    print(f"Lest inn {len(CPV_LOOKUP_MAP)} CPV-koder fra {CPV_YAML_PATH}.")

    # 2. Les inn HTML-snippeten
    try:
        with open(XML_INPUT_PATH, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except FileNotFoundError:
        print(f"FEIL: Fant ikke HTML-filen på {XML_INPUT_PATH}")
        return

    soup = BeautifulSoup(html_content, 'html.parser')
    
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    print("\n----------------------------------------------------")
    
    # 3. Iterer over alle ønskede vedlegg og ekstraher/dump data
    # Vi bruker sorted(ANNEX_CONFIG.items()) for å behandle i rekkefølge 1, 2, 3, 4.
    for annex_num, config in sorted(ANNEX_CONFIG.items()):
        filename = config['filename']
        output_path = OUTPUT_DIR / filename
        
        print(f"Behandler Vedlegg {annex_num} ({filename})...")
        
        annex_data = extract_services_for_annex(soup, annex_num, CPV_LOOKUP_MAP)
        
        if annex_data and annex_data['annex']['services']:
            # 3.1 Bruk funksjon for å sitere kun verdier
            quoted_output_structure = quote_values_recursively(annex_data)

            with open(output_path, 'w', encoding='utf-8') as f:
                yaml.dump(quoted_output_structure, f, indent=4, sort_keys=False, allow_unicode=True)
            
            num_services = len(annex_data['annex']['services'])
            print(f"✅ Vellykket generert {num_services} tjenester til: {output_path.name}")
        
        elif annex_data:
             print(f"⚠️ Vedlegg {annex_num} funnet, men inneholdt ingen koder. Filen ble ikke generert.")
        
    print("----------------------------------------------------")
    print("Fullført dumping av alle vedlegg til separate YAML-filer.")
    
if __name__ == '__main__':
    parse_html_and_generate_yaml()
