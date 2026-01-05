import json
import os

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

def audit():
    base_path = '/Users/abdalrahmanmajed/Desktop/edconamobile/assets/translations'
    files = {
        'en': 'en.json',
        'ar': 'ar.json',
        'ckb': 'ckb.json',
        'bhn': 'bhn.json',
        'arc': 'arc.json'
    }

    data = {}
    for lang, filename in files.items():
        data[lang] = load_json(os.path.join(base_path, filename))

    en_flat = flatten_json(data['en'])
    
    missing_report = []
    english_value_report = []

    languages = ['ar', 'ckb', 'bhn', 'arc']

    for lang in languages:
        lang_flat = flatten_json(data[lang])
        
        # Check for missing keys
        for key, val in en_flat.items():
            if key not in lang_flat:
                missing_report.append({
                    'lang': lang,
                    'key': key,
                    'en_text': val
                })
            else:
                # Check for English values (potentially untranslated)
                # Ignore numbers or very short strings like "OK" if they are same?
                # User specifically asked for this, so I will be strict but maybe ignore "EdCona"
                lang_val = lang_flat[key]
                if lang_val == val and len(str(val)) > 2: # Ignore short matches potentially
                     english_value_report.append({
                        'lang': lang,
                        'key': key,
                        'en_text': val,
                        'current_text': lang_val
                    })

    print("--- MISSING KEYS ---")
    for item in missing_report:
        print(f"Language: {item['lang']}")
        print(f"Key: {item['key']}")
        print(f"English: {item['en_text']}")
        print("Translation: ")
        print("-" * 20)

    print("\n--- ENGLISH VALUES (UNTRANSLATED) ---")
    for item in english_value_report:
        print(f"Language: {item['lang']}")
        print(f"Key: {item['key']}")
        print(f"English: {item['en_text']}")
        print(f"Current: {item['current_text']}")
        print("Translation: ")
        print("-" * 20)

if __name__ == '__main__':
    audit()
