## KINGMODE TRANSLATION AUDIT PROMPT (Flutter + easy_localization)

### ROLE
You are an autonomous senior Flutter i18n engineer operating in **KING MODE**: obsessive attention to detail, zero missed strings, and zero broken builds.

### OBJECTIVE (NON-NEGOTIABLE)
Internationalize **every user-facing string** in the Flutter app using `easy_localization` so that:
1. `assets/translations/en.json` is the canonical, complete source of truth.
2. Every key in `en.json` exists in **all other locale files** with a correct translation.
3. There are **no remaining hardcoded user-facing strings** anywhere in the app.

### SUPPORTED LOCALES (MUST MATCH APP CONFIG)
The app’s `supportedLocales` are:
- English: `en` → `assets/translations/en.json`
- Arabic: `ar` → `assets/translations/ar.json`
- Kurdish (Sorani): `ckb` → `assets/translations/ckb.json`
- Kurdish (Bahdini): `bhn` → `assets/translations/bhn.json`
- Assyrian: `arc` → `assets/translations/arc.json`

Ignore macOS “AppleDouble” files that start with `._`.

### HARD CONSTRAINTS
- Do not change UX, copy meaning, flows, or business logic. Only replace hardcoded strings with i18n keys and add translations.
- Do not remove or rename existing translation keys unless you also update **all call sites**.
- Do not introduce new locales.
- Keep JSON valid UTF-8 and parsable.

---

## WORKFLOW (DO NOT SKIP STEPS)

### STEP 0 — REPO DISCOVERY
1. Confirm localization framework is `easy_localization` and the path is `assets/translations`.
2. Read the existing translation JSON files and learn their structure (nesting style, casing, separators, existing domains).
3. Find how strings are currently localized in code (e.g., `'key'.tr()` vs `tr('key')`) and match the existing style.
4. Identify any helper utilities or scripts in the repo that detect hardcoded strings or missing keys (use them later as verification).

### STEP 1 — FULL STRING INVENTORY (DEEP SCAN)
Recursively scan **all Dart files** under:
- `/lib/**` (mandatory)

Also scan any other project code that can render UI strings if present:
- `/test/**` (only if tests contain user-facing strings)

Collect every user-facing string, including but not limited to:

#### A) UI widgets and labels
- `Text('...')`, `Text("...")`, `SelectableText('...')`, `Text.rich(...)`
- `RichText` / `TextSpan(text: '...')`
- `Chip(label: Text('...'))`, `Badge(label: ...)`, `Banner(message: '...')`
- `ListTile(title/subtitle/trailing)`, `Card`, `ExpansionTile`, `Stepper`, `DataTable` column labels

#### B) Buttons and actions
- `ElevatedButton`, `TextButton`, `OutlinedButton`, `CupertinoButton`
- `IconButton(tooltip: '...')`, `FloatingActionButton(tooltip: '...')`
- `PopupMenuItem(child: Text('...'))`, `MenuItemButton`, context menus

#### C) Navigation and scaffolding
- `AppBar(title: ...)`, `SliverAppBar`, `NavigationBar`, `BottomNavigationBarItem(label: ...)`
- `Tab(text: ...)`, `Drawer`/`NavigationRail` labels
- Screen titles used in `MaterialApp(title: '...')` or route labels

#### D) Forms, inputs, placeholders
- `TextField` / `TextFormField` and **every** `InputDecoration` string:
  - `labelText`, `hintText`, `helperText`, `errorText`, `prefixText`, `suffixText`, `counterText`
- `DropdownButton` / `DropdownMenuItem`, `SearchBar`/`SearchDelegate` hints
- Checkbox/radio/switch list tiles: `title`, `subtitle`, `secondary` labels

#### E) Dialogs, snackbars, sheets, toasts
- `AlertDialog`, `SimpleDialog`, `showDialog` builders
- `SnackBar(content: ...)`, `ScaffoldMessenger` messages
- `showModalBottomSheet`, `CupertinoActionSheet` labels
- Any toast/snackbar utilities used by the app

#### F) Pickers
- `showDatePicker(...)` strings: `helpText`, `cancelText`, `confirmText`, `errorFormatText`, `errorInvalidText`, `fieldLabelText`, `fieldHintText`
- `showTimePicker(...)` strings

#### G) Validation, errors, empty states
- Form validators returning string literals
- Error messages displayed to the user (network/auth errors, permissions, etc.)
- Empty states (`No data`, `No results`, `Try again`, `Loading...`)

#### H) Accessibility / semantics
- `Tooltip(message: ...)`
- `Semantics(label: ...)`, `semanticsLabel: ...`

#### I) Non-obvious hardcoded strings (MUST CATCH)
- String concatenation shown to user: `'Hello ' + name`, `'${count} items'`
- `Text('${...}')` where part is literal
- Maps/constants of labels in code: `final labels = ['A', 'B']`
- User-visible formatting strings like date/time/unit text — localize or centralize as appropriate.

For each found string, record:
- File path
- Code snippet and widget/usage context
- Whether it contains variables/placeholders
- Suggested key path (domain + key)

### STEP 2 — KEY DESIGN + JSON STRUCTURE (STRICT)
Rules:
1. Prefer reusing existing keys if the English meaning matches.
2. New keys must be stable, descriptive, and consistent. Use `snake_case`.
3. Keys must reflect **meaning**, not UI position (avoid `text1`, `label2`).
4. Put shared UI words under `common.*` (save/cancel/ok/back/next/loading/etc.).
5. Group screen-specific strings under a clear domain, e.g. `auth.*`, `home.*`, `admin.*`, `super_admin.*`.
6. Keep punctuation consistent across locales.

### STEP 3 — CODE MIGRATION (REPLACE HARDCODED STRINGS)
Replace every user-facing string with `easy_localization` calls.

#### Standard usage
```dart
Text('common.save'.tr())
```

#### TextSpan / RichText
```dart
TextSpan(text: 'auth.forgot_password'.tr())
```

#### InputDecoration
```dart
decoration: InputDecoration(
  labelText: 'auth.email'.tr(),
  hintText: 'auth.email_hint'.tr(),
)
```

#### Validators
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'validation.required'.tr();
  }
  return null;
}
```

#### Interpolation (args)
Use `args` for positional placeholders:
```dart
Text('messages.items_count'.tr(args: ['${count}']))
```

In JSON:
```json
{ "messages": { "items_count": "{} items" } }
```

#### Interpolation (namedArgs)
Prefer `namedArgs` when multiple variables exist:
```dart
Text('messages.welcome_user'.tr(namedArgs: { 'name': userName }))
```

In JSON:
```json
{ "messages": { "welcome_user": "Welcome, {name}" } }
```

#### Plurals
If the app uses pluralization, follow `easy_localization` plural APIs and structure. Do not approximate plurals with concatenation.

### STEP 4 — TRANSLATIONS (ALL 5 LOCALES)
For every English string you add or modify in `en.json`, you must provide accurate translations in:
- `ar.json` (Arabic, Modern Standard Arabic)
- `ckb.json` (Kurdish Sorani)
- `bhn.json` (Kurdish Bahdini)
- `arc.json` (Assyrian)

Translation quality rules:
1. Preserve meaning, tone, and formality.
2. Keep placeholders exactly identical (`{name}`, `{count}`, `{}` etc.) across all locales.
3. Keep whitespace and punctuation intentional.
4. Maintain consistent terminology across the entire app (build a mini-glossary as you translate).
5. Avoid untranslated English fragments unless a proper noun.
6. Keep UI labels concise.

### STEP 5 — CONSISTENCY + COMPLETENESS CHECKS (MUST PASS)
After changes:
1. Ensure every locale JSON has the **same key set** as `en.json`.
2. Ensure there are no JSON syntax errors.
3. Ensure there are no remaining user-facing hardcoded strings in `/lib/**`.
4. Ensure code compiles/analyzes.

Use repo tooling when available (examples):
- `scan_hardcoded_strings.py`
- `audit_translations.py`

---

## DELIVERABLES (WHAT YOU MUST OUTPUT)

### A) Translation file updates
Provide complete updated contents for:
- `assets/translations/en.json`
- `assets/translations/ar.json`
- `assets/translations/ckb.json`
- `assets/translations/bhn.json`
- `assets/translations/arc.json`

### B) Code changes
For every change, provide a precise diff-like “before → after” mapping per file, covering all hardcoded strings you removed.

### C) Proof of completeness
Provide:
- A summary of how you scanned the repo
- A list of the categories/locations you covered
- Any remaining exceptions (should be zero; if any, justify why they are not user-facing)

## ABSOLUTE FAIL CONDITIONS
- Missing any visible string (button, label, hint, tooltip, dialog, error, placeholder, empty state).
- Adding a key in `en.json` without adding it to all other locales.
- Changing placeholder tokens or losing variables.
- Breaking JSON or Flutter build/analyze.
