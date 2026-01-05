import json
import os
from typing import Any, Tuple

BASE_DIR = os.path.join(os.path.dirname(__file__), "assets", "translations")
CANONICAL_LANG = "en"
TARGET_LANGS = ["ar", "ckb", "bhn", "arc"]


def _load(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _save(path: str, data: Any) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def _merge_missing_keys(base: Any, target: Any) -> Tuple[Any, int]:
    added = 0

    if isinstance(base, dict):
        if not isinstance(target, dict):
            target = {}
        for key, base_value in base.items():
            if key not in target:
                target[key] = base_value
                added += 1
            else:
                merged_value, merged_added = _merge_missing_keys(base_value, target[key])
                target[key] = merged_value
                added += merged_added
        return target, added

    if isinstance(base, list):
        if not isinstance(target, list):
            target = []
        for i, base_item in enumerate(base):
            if i >= len(target):
                target.append(base_item)
                added += 1
            else:
                merged_value, merged_added = _merge_missing_keys(base_item, target[i])
                target[i] = merged_value
                added += merged_added
        return target, added

    return target, 0


def main() -> None:
    canonical_path = os.path.join(BASE_DIR, f"{CANONICAL_LANG}.json")
    canonical = _load(canonical_path)

    total_added = 0
    for lang in TARGET_LANGS:
        path = os.path.join(BASE_DIR, f"{lang}.json")
        current = _load(path)
        merged, added = _merge_missing_keys(canonical, current)
        if added:
            _save(path, merged)
        print(f"{lang}: added {added} missing keys")
        total_added += added

    print(f"Total added keys: {total_added}")


if __name__ == "__main__":
    main()
