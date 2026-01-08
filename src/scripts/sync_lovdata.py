import argparse
import yaml
import requests
import tarfile
import io
import re
import os
import sys
import datetime
from lxml import etree

# --- HJELPEFUNKSJONER (TOPPNIVÅ) ---

def get_significant_depth(codes_in_division):
    """Finner nødvendig dybde per gruppe for å unngå overmatch."""
    if not codes_in_division: return 2
    max_depth = 0
    for code in codes_in_division:
        clean = code.rstrip('0')
        max_depth = max(max_depth, len(clean))
    return max(2, max_depth)

def get_hierarchical_prefixes(start_code, end_code):
    """Bryter ned intervaller til prefikser."""
    start = int(start_code[:8])
    end = int(end_code[:8])
    prefixes = []
    current = start
    while current <= end:
        for step in [1000000, 100000, 10000, 1000, 100, 10, 1]:
            if current % step == 0 and current + step - 1 <= end:
                code_str = str(current).zfill(8)
                if step == 1000000: p = code_str[:2]
                elif step == 100000: p = code_str[:3]
                elif step == 10000:  p = code_str[:4]
                elif step == 1000:   p = code_str[:5]
                elif step == 100:    p = code_str[:6]
                elif step == 10:     p = code_str[:7]
                else:                p = code_str
                prefixes.append(p.rstrip('0'))
                current += step
                break
    return prefixes

def extract_raw_codes(text):
    """Henter ut 8-sifrede koder og dekomponerer intervaller."""
    found = set()
    range_pattern = re.compile(r'(\d{8})[–-](\d{8})')
    single_pattern = re.compile(r'\b(\d{8})\b')
    for match in range_pattern.finditer(text):
        for p in get_hierarchical_prefixes(match.group(1), match.group(2)):
            found.add(p.ljust(8, '0')) # Fyll ut til 8 siffer for analyse
        text = text.replace(match.group(0), "")
    found.update(single_pattern.findall(text))
    return found

def process_hierarchically(raw_set):
    """Beregner kutt-dybde basert på naboer i divisjonen."""
    divisions = {}
    for code in raw_set:
        div = code[:2]
        if div not in divisions: divisions[div] = []
        divisions[div].append(code)
    final_prefixes = set()
    for div, codes in divisions.items():
        depth = get_significant_depth(codes)
        for c in codes:
            final_prefixes.add(c[:depth])
    return final_prefixes

# --- HOVEDJOBB ---

def run_job(job_config, sources_config, template_path=None):
    src_name = job_config['source_ref']
    src_info = sources_config[src_name]
    
    # Metadata og caching (som før)
    meta_resp = requests.get(src_info['api_list_url']).json()
    target_fn = job_config['source_params']['filename']
    meta = next(item for item in meta_resp if item['filename'] == target_fn)
    last_mod = meta['lastModified']
    state_path = job_config['state_file']
    
    if os.path.exists(state_path) and open(state_path).read().strip() == last_mod:
        print(f"✅ Up-to-date: {job_config['id']}")
        return

    resp = requests.get(f"{src_info['api_get_url']}/{target_fn}")
    with tarfile.open(fileobj=io.BytesIO(resp.content), mode='r:bz2') as tar:
        xml_data = tar.extractfile(job_config['source_params']['xml_path']).read()

    tree = etree.fromstring(xml_data)
    result = {}

    for key, xpath in job_config['mappings'].items():
        nodes = tree.xpath(xpath)
        all_inc_raw = set()
        all_exc_raw = set()

        for node in nodes:
            full_text = "".join(node.itertext())
            if "Unntatt" in full_text:
                parts = re.split(r'[Uu]nntatt:?', full_text, maxsplit=1)
                all_inc_raw.update(extract_raw_codes(parts[0]))
                all_exc_raw.update(extract_raw_codes(parts[1]))
            else:
                all_inc_raw.update(extract_raw_codes(full_text))

        # --- DEN DEFINITIVE JURIST-DREPEREN ---
        actual_exc_raw = set()
        for exc_code in all_exc_raw:
            # Sjekk om denne unntatte koden (f.eks. 45232000) 
            # starter med en av kodene vi har inkludert (f.eks. 4523)
            is_covered = False
            for inc_code in all_inc_raw:
                # inc_code kan være '4523' eller '45230000'
                # Vi stripper nuller på inkluderingen for å sjekke om det er et prefiks
                inc_prefix = inc_code.rstrip('0')
                if exc_code.startswith(inc_prefix):
                    is_covered = True
                    break
            
            # Hvis koden IKKE er dekket av en inkludering, DA kan den være et unntak
            if not is_covered:
                actual_exc_raw.add(exc_code)

        # Kjør hierarki-analyse på de rensede settene
        includes = process_hierarchically(all_inc_raw)
        excludes = process_hierarchically(actual_exc_raw)
        
        result[key] = {
            'include': sorted(list(includes), key=lambda x: (len(x), x)),
            'exclude': sorted(list(excludes), key=lambda x: (len(x), x))
        }

    # Lagring med Header Template
    os.makedirs(os.path.dirname(job_config['output_file']), exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    doc_name = job_config['source_params'].get('document_name', 'Ukjent')
    
    header = ""
    if template_path and os.path.exists(template_path):
        header = open(template_path, 'r', encoding='utf-8').read().format(
            timestamp=timestamp, document_name=doc_name
        ).strip() + "\n---\n"

    final_output = {
        'metadata': { 'document_name': doc_name, 'generated_at': timestamp, 'job_id': job_config['id'] },
        **result
    }

    with open(job_config['output_file'], 'w', encoding='utf-8') as f:
        if header: f.write(header)
        yaml.dump(final_output, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
    
    with open(state_path, 'w') as f: f.write(last_mod)
    print(f"✨ Fullført {job_config['id']}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--job-id', required=True)
    parser.add_argument('--config-file', default='config/lovdata_jobs.yaml')
    parser.add_argument('--header-template', help='Sti til header-fil')
    args = parser.parse_args()
    
    with open(args.config_file, 'r') as f:
        conf = yaml.safe_load(f)
    job = next((j for j in conf['jobs'] if j['id'] == args.job_id), None)
    if job: run_job(job, conf['sources'], args.header_template)
