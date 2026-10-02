"""Renders the comparison page from bench-table.py's JSON, with the timed code and the rewrite's source.

usage: py bench-page.py <table.json> <bench-dir> <out.html>
"""
import json, pathlib, re, sys

RUNTIMES = {
    'new': ('New VM', "Epic's new VerseVM (VerseCmd), local."),
    'ship': ('BPVM local', "Fortnite's backend, Shipping build (VerseCLR), local."),
    'uefn': ('BPVM UEFN', 'Same backend, on the server of a UEFN play session.'),
}

TRANSCENDENTAL = {'Sin', 'Cos', 'Tan', 'Exp', 'Ln', 'ArcTan', 'ArcTan2', 'ArcSin', 'ArcCos', 'Sinh', 'Cosh', 'Tanh',
                  'ArSinh', 'ArCosh', 'ArTanh', 'PowCube'}
ARRAYS = {'Find', 'RemoveFirstElement', 'ReplaceFirstElement', 'RemoveElement', 'Slice', 'Insert', 'Concatenate',
          'ReplaceAll', 'ToString (int)'}
VERSE_MATH = {'Sqrt', 'Clamp', 'Min', 'Max', 'Sgn', 'Abs', 'Lerp (float)', 'Floor', 'Round', 'Abs (int)', 'Min (int)',
              'Clamp (int)', 'Quotient', 'Mod'}

DEFINITION = re.compile(r'^(\s*)(?:\(.*?\)\.(?=[A-Z]))?([A-Z]\w*)(?:<\w+>)*\(.*\).*=')
CALL = re.compile(r'(?:\b|\.)([A-Z]\w*)\s*[\[(]')
PROFILE = re.compile(r'^(\s*)profile\("(.+)"\):\s*$')

# The representation benches time the same Verse code on three vector types; only the native side of
# HomingStep is Verse code too, so "Native" only resolves to those definitions.
TUPLE_FILES = {'bench_tuple_math.verse', 'fast_tuple_math.verse'}
REPRESENTATION_TYPES = {'Native': 'temp_vector3', 'VerseOrg': 'verse_vector3', 'Tuple': 'vec3', 'Scalar': 'temp_vector3'}


def group_of(function):
    if function.endswith('[repr]') or function == 'HomingStep':
        return 'Vector representations'
    if function.endswith('[Verse.org]'):
        return '/Verse.org/SpatialMath'
    if function in TRANSCENDENTAL:
        return 'Transcendental'
    if function in ARRAYS:
        return 'Arrays'
    if function == 'SortBy':
        return 'Sorting'
    if function in ('EaseInOut', 'CubicBezier'):
        return 'Easing (experimental)'
    if function in VERSE_MATH:
        return '/Verse.org/Verse'
    return '/UnrealEngine.com/Temporary/SpatialMath'


def indent_of(line):
    return len(line) - len(line.lstrip())


def block_at(lines, start):
    """The line at start plus every following line indented deeper, minus trailing blank lines."""
    base = indent_of(lines[start])
    end = start + 1
    while end < len(lines) and (not lines[end].strip() or indent_of(lines[end]) > base):
        end += 1
    while end > start + 1 and not lines[end - 1].strip():
        end -= 1
    first = start
    while first > 0 and lines[first - 1].strip().startswith('#') and indent_of(lines[first - 1]) == base:
        first -= 1
    return '\n'.join(line[base:] if line.strip() else '' for line in lines[first:end])


def read_profiles(harness):
    blocks = {}
    for path in sorted(harness.glob('*.verse')):
        lines = path.read_text(encoding='utf-8').splitlines()
        for i, line in enumerate(lines):
            if m := PROFILE.match(line):
                blocks[m.group(2)] = block_at(lines, i)
    return blocks


def read_definitions(paths):
    definitions = []
    for path in paths:
        lines = path.read_text(encoding='utf-8').splitlines()
        for i, line in enumerate(lines):
            if m := DEFINITION.match(line):
                definitions.append({'name': m.group(2), 'file': path.name, 'signature': line, 'text': block_at(lines, i)})
    return definitions


def wanted(definition, tag):
    """Picks the overload and the module that match the timed variant."""
    variant, signature = tag.split()[0], definition['signature']
    if variant in REPRESENTATION_TYPES:
        return definition['file'] in TUPLE_FILES and re.search(rf'\b{REPRESENTATION_TYPES[variant]}\b', signature) is not None
    if definition['file'] in TUPLE_FILES:
        return False
    if ('[Verse.org]' in tag) != (definition['file'] == 'fast_verse_spatial.verse'):
        return False
    if '(vector2i)' in tag:
        return 'vector2i' in signature
    if '(vector2)' in tag:
        return 'vector2' in signature and 'vector2i' not in signature
    return 'vector2' not in signature


def sources_for(block, tag, definitions):
    found, queue = [], [block]
    while queue:
        text = queue.pop(0)
        for name in dict.fromkeys(CALL.findall(text)):
            for definition in definitions:
                if definition['name'] == name and definition not in found and wanted(definition, tag):
                    found.append(definition)
                    queue.append(definition['text'])
    return [{'file': d['file'], 'text': d['text']} for d in found]


def main():
    table_path, bench_dir, out = sys.argv[1:]
    bench = pathlib.Path(bench_dir)
    table = json.load(open(table_path, encoding='utf-8'))
    profiles = read_profiles(bench / 'harness')
    definitions = read_definitions(sorted((bench / 'lib').glob('*.verse')) + [bench / 'harness' / 'bench_tuple_math.verse'])
    rows = []
    for row in table['rows']:
        native_tag, rewrite_tag = f"Native {row['function']}", f"{row['variant']} {row['function']}"
        native_block, rewrite_block = profiles.get(native_tag, ''), profiles.get(rewrite_tag, '')
        rows.append({
            'function': row['function'].replace(' [repr]', ''),
            'variant': row['variant'],
            'group': group_of(row['function']),
            'cells': row['cells'],
            'code': {'native': native_block, 'rewrite': rewrite_block,
                     'native_sources': sources_for(native_block, native_tag, definitions),
                     'sources': sources_for(rewrite_block, rewrite_tag, definitions)},
        })
    same = sum(1 for r in table['rows'] if verdict(r['cells']['ship']['speedup']) == verdict(r['cells']['uefn']['speedup']))
    payload = {
        'lede': f'{len(rows)} comparisons between a native function that Fortnite exposes to Verse and a hand-written '
                'Verse replacement, timed on the new VerseVM, on the BPVM locally, and on the BPVM of a UEFN server. '
                'Click a row to see the timed code and the rewrite.',
        'method': 'Each profile block calls the function 10,000 times, except arrays (100 operations on 1,000-element '
                  'arrays, 25 for Concatenate and ReplaceAll) and sorting (50 sorts of 200 floats). Measured on '
                  'October 2–3, 2026, with identical code on every runtime.',
        'agreement': f'{same} of {len(rows)} comparisons get the same verdict in UEFN as on the local BPVM; the rest '
                     'are borderline cases. Large gains are slightly smaller in UEFN, losses are the same.',
        'runtimes': [{'key': key, 'label': RUNTIMES[key][0], 'detail': RUNTIMES[key][1]} for key in table['runtimes']],
        'rows': rows,
    }
    template = pathlib.Path(__file__).with_name('bench-page.template.html').read_text(encoding='utf-8')
    data = json.dumps(payload, ensure_ascii=False).replace('</', '<\\/')
    pathlib.Path(out).write_text(template.replace('__BENCH_DATA__', data), encoding='utf-8')
    without_source = [f"{r['variant']} {r['function']}" for r in rows if not r['code']['sources']]
    print(f'{len(rows)} rows -> {out}; rows without rewrite source: {without_source}')


def verdict(x):
    return None if x is None else 'win' if x >= 1.15 else 'even' if x >= 0.9 else 'loss'


main()
