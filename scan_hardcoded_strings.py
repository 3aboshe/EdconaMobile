import os
import re

def scan_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    found_issues = []
    
    # Regex patterns
    # 1. Text('...') or Text("...")
    text_pattern = re.compile(r"Text\s*\(\s*(['\"])(.*?)\1")
    
    # 2. .text = "..." (common in controllers, but often hardcoded initial values)
    # Filtered out to avoid false positives in logic, but useful if meticulously checking.
    # text_assign_pattern = re.compile(r"\.text\s*=\s*(['\"])(.*?)\1")

    # 3. Parameters like hintText: '...', labelText: '...', tooltip: '...'
    param_pattern = re.compile(r"\b(hintText|labelText|helperText|errorText|tooltip|label|title|subtitle|prefixText|suffixText|counterText|message|helpText|cancelText|confirmText|semanticsLabel)\s*:\s*(['\"])(.*?)\2")

    # 4. Strings in lists which might be options e.g. ['Yes', 'No'] or {'Male', 'Female'}
    # This is hard to regex reliably without parsing.

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()
        
        # Skip comments and imports
        if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('export '):
            continue
        if stripped.startswith('package:'):
            continue

        # Check Text(...)
        for match in text_pattern.finditer(line):
            quote = match.group(1)
            content = match.group(2)
            full_match = match.group(0)
            
            # Heuristic: check if .tr() follows the closing quote immediately (or with whitespace)
            # Find the end of this string in the line
            end_idx = match.end()
            remainder = line[end_idx:]
            remainder_stripped = remainder.lstrip()
            if (
                remainder_stripped.startswith('.tr(')
                or remainder_stripped.startswith('.tr()')
                or remainder_stripped.startswith('.plural(')
            ):
                continue
            
            # Skip empty strings
            if not content.strip():
                continue
                
            # Skip probable formatting strings like "${...}" only
            if content.startswith('$') and ' ' not in content:
                continue

            found_issues.append({
                'file': filepath,
                'line': line_num,
                'type': 'Text Widget',
                'content': content,
                'context': stripped
            })

        # Check parameters
        for match in param_pattern.finditer(line):
            param = match.group(1)
            quote = match.group(2)
            content = match.group(3)
            
            end_idx = match.end()
            remainder = line[end_idx:]
            remainder_stripped = remainder.lstrip()
            if (
                remainder_stripped.startswith('.tr(')
                or remainder_stripped.startswith('.tr()')
                or remainder_stripped.startswith('.plural(')
            ):
                continue

            if not content.strip():
                continue

             # Skip paths
            if '/' in content and ' ' not in content:
                continue
            
            found_issues.append({
                'file': filepath,
                'line': line_num,
                'type': f'Parameter ({param})',
                'content': content,
                'context': stripped
            })

    return found_issues

def scan_directory(root_dir):
    all_issues = []
    print(f"Scanning {root_dir}...")
    
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                issues = scan_file(filepath)
                all_issues.extend(issues)
    
    return all_issues

def report(issues):
    print(f"\nFound {len(issues)} potential hardcoded strings:\n")
    
    by_file = {}
    for issue in issues:
        f = issue['file']
        if f not in by_file:
            by_file[f] = []
        by_file[f].append(issue)
        
    for f, f_issues in by_file.items():
        rel_path = os.path.relpath(f, os.getcwd())
        print(f"=== {rel_path} ===")
        for issue in f_issues:
            print(f"  Line {issue['line']} [{issue['type']}]: \"{issue['content']}\"")
            # print(f"    Context: {issue['context']}")
        print("")

if __name__ == '__main__':
    issues = scan_directory(os.path.join(os.getcwd(), 'lib'))
    report(issues)
