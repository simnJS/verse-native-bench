"""Builds the per-function comparison (median ms and native/rewrite speed-up) across runtimes.

usage: py bench-table.py <out.json> <name>=<file> [<name>=<file> ...] [--uefn-since=<timestamp>]

A file is either the launcher output (lines "PROFILE <tag>: <ms> ms") or the UEFN editor log
(lines "LogVerse: VerseProfile: <tag> <ms> ms"). For the UEFN log, --uefn-since keeps only lines
whose [YYYY.MM.DD-HH.MM.SS:mmm] stamp is at or after the given one (one play session).
"""
import json, re, statistics, sys

LAUNCHER = re.compile(r'^PROFILE (.+): ([0-9.]+) ms$')
UEFN = re.compile(r'^\[([0-9.\-:]+)\]\[\s*\d+\]LogVerse: VerseProfile: (.+) ([0-9.]+) ms$')


def read_samples(path, since):
    samples = {}
    for line in open(path, encoding='utf-8', errors='replace'):
        line = line.strip()
        if m := LAUNCHER.match(line):
            tag, ms = m.group(1), float(m.group(2))
        elif (m := UEFN.match(line)) and (since is None or m.group(1) >= since):
            tag, ms = m.group(2), float(m.group(3))
        else:
            continue
        samples.setdefault(tag, []).append(ms)
    return samples


def main():
    out, *specs = sys.argv[1:]
    since = next((s.split('=', 1)[1] for s in specs if s.startswith('--uefn-since=')), None)
    runtimes = [s.split('=', 1) for s in specs if not s.startswith('--')]
    medians = {}
    for name, path in runtimes:
        for tag, values in read_samples(path, since).items():
            medians.setdefault(tag, {})[name] = statistics.median(values)

    # "Native X" pairs with every other "<Variant> X".
    rows = []
    for native in medians:
        if not native.startswith('Native '):
            continue
        subject = native.split(' ', 1)[1]
        for rewrite in medians:
            if rewrite != native and rewrite.split(' ', 1)[-1] == subject:
                cells = {}
                for name, _ in runtimes:
                    n, r = medians[native].get(name), medians[rewrite].get(name)
                    cells[name] = {'native': n, 'rewrite': r, 'speedup': n / r if n and r else None}
                rows.append({'function': subject, 'variant': rewrite.split(' ', 1)[0], 'cells': cells})
    json.dump({'runtimes': [n for n, _ in runtimes], 'rows': rows}, open(out, 'w', encoding='utf-8'), indent=1)
    print(f'{len(rows)} pairs, runtimes: {", ".join(n for n, _ in runtimes)}')
    for row in sorted(rows, key=lambda r: -(r['cells'][runtimes[-1][0]]['speedup'] or 0))[:12]:
        print(f"{row['variant']:>9} {row['function']:<40}" + ''.join(
            f"  {name}={c['speedup']:.2f}x" if c['speedup'] else f'  {name}=-' for name, c in row['cells'].items()))


main()
