import json
import os
import glob
import re

def load_json(path):
    with open(path, 'r') as f:
        return json.load(f)

def flatten_json(y):
    out = {}
    def flatten(x, name=''):
        if type(x) is dict:
            for a in x:
                flatten(x[a], name + a + '.')
        elif type(x) is list:
            i = 0
            for a in x:
                flatten(a, name + str(i) + '.')
                i += 1
        else:
            out[name[:-1]] = x
    flatten(y)
    return out

def get_dart_keys(root_dir):
    keys = set()
    # Regex to find tr('key') or .tr("key") or json['key']
    # This is a heuristic and might miss some or find false positives
    # common pattern in Flutter formatting:
    # tr('login.welcome')
    # "login.welcome".tr()
    patterns = [
        r"['\"]([\w\._]+)['\"]\s*\.tr\(\)",
        r"tr\(['\"]([\w\._]+)['\"]\)",
        r"json\['([\w\._]+)'\]",
    ]
    
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                try:
                    with open(os.path.join(root, file), 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        for p in patterns:
                            matches = re.finditer(p, content)
                            for m in matches:
                                keys.add(m.group(1))
                except Exception as e:
                    print(f"Skipping file {file}: {e}")
    return keys

def audit_reverse():
    base_path = '/Users/abdalrahmanmajed/Desktop/edconamobile/assets/translations'
    src_path = '/Users/abdalrahmanmajed/Desktop/edconamobile/lib'
    
    en_data = load_json(os.path.join(base_path, 'en.json'))
    ar_data = load_json(os.path.join(base_path, 'ar.json'))
    
    en_flat = flatten_json(en_data)
    ar_flat = flatten_json(ar_data)
    
    # 1. Check keys in AR but not in EN
    extra_in_ar = []
    for key in ar_flat:
        if key not in en_flat:
            extra_in_ar.append(key)
            
    # 2. Check keys in Code but not in EN
    dart_keys = get_dart_keys(src_path)
    missing_in_en_from_code = []
    
    # Filter out keys that clearly aren't translation keys (too short, no dots, etc - heuristic)
    # We only care about keys that look like translation keys e.g. "section.key"
    potential_keys = [k for k in dart_keys if '.' in k and ' ' not in k]
    
    for key in potential_keys:
        if key not in en_flat:
             # Double check if it matches a partial path (e.g. parent for json access)
             # But here we assume full keys
             missing_in_en_from_code.append(key)

    print("--- KEYS IN ARABIC BUT MISSING IN ENGLISH ---")
    for k in sorted(extra_in_ar):
        print(f"Key: {k} | Ar Value: {ar_flat[k]}")
        
    print("\n--- KEYS IN CODE BUT MISSING IN ENGLISH ---")
    for k in sorted(missing_in_en_from_code):
        print(f"Key: {k}")

if __name__ == '__main__':
    audit_reverse()
