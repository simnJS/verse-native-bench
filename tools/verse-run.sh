#!/usr/bin/env bash
# Runs a Verse program on Epic's new VerseVM and/or on the BPVM, the VM Fortnite ships.
#
#   verse [--vm=LIST] [--keep] <file.verse | bench-dir>
#
#   LIST: comma-separated among new (VerseCmd), bpvm (VerseCLR Development), ship (VerseCLR Shipping),
#         or both (= new,bpvm), all (every runtime installed). Default: new.
#
# A bench dir is concatenated in order lib/ harness/ cli/ (VerseCmd has no working --mount).
# The program must define Main(Args:[]string, Env:[string]string)<suspends>:void.
# It may call BenchRuntime.CommitPoint() between heavy phases: on the BPVM the whole run is one
# transaction that keeps every allocation until it ends, so this bounds memory (VerseCLR NextTick on
# the BPVM, VerseCmd Yield on the new VM).
set -euo pipefail

RUNTIMES="${VERSE_RUNTIMES:-$HOME/verse-bench}"
BPVM_ENTRY="BpvmEntry"

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
}

binary_of() {
    case "$1" in
        new) echo "$RUNTIMES/new/Engine/Binaries/Linux/verse" ;;
        bpvm) echo "$RUNTIMES/bpvm/Engine/Binaries/Linux/VerseCLR" ;;
        ship) echo "$RUNTIMES/ship/Engine/Binaries/Linux/VerseCLR-Linux-Shipping" ;;
        *) return 1 ;;
    esac
}

vm_list=new
keep=0
input=""
for arg in "$@"; do
    case "$arg" in
        --vm=*) vm_list="${arg#--vm=}" ;;
        --keep) keep=1 ;;
        -h|--help) usage ;;
        -*) echo "unknown option: $arg" >&2; usage ;;
        *) [ -z "$input" ] && input="$arg" || usage ;;
    esac
done
[ -n "$input" ] || usage

case "$vm_list" in
    both) vm_list=new,bpvm ;;
    all) vm_list=$(for vm in new bpvm ship; do [ -x "$(binary_of $vm)" ] && echo -n "$vm,"; done); vm_list=${vm_list%,} ;;
esac
IFS=, read -r -a vms <<< "$vm_list"
for vm in "${vms[@]}"; do
    bin=$(binary_of "$vm") || { echo "unknown vm: $vm" >&2; usage; }
    [ -x "$bin" ] || { echo "runtime not installed: $vm ($bin)" >&2; exit 2; }
done

# Accept Windows paths (C:\... or C:/...) as well as WSL paths.
if [[ "$input" =~ ^[A-Za-z]:[\\/] ]]; then
    input="$(wslpath -u "$input")"
fi
[ -e "$input" ] || { echo "not found: $input" >&2; exit 2; }

work="$(mktemp -d)"
cleanup() { [ "$keep" = 1 ] && echo "kept: $work" >&2 || rm -rf "$work"; }
trap cleanup EXIT

program="$work/program.verse"
if [ -d "$input" ]; then
    for part in lib harness cli; do
        for file in "$input/$part"/*.verse; do
            [ -e "$file" ] || continue
            printf '\n# ---- %s/%s\n' "$part" "$(basename "$file")" >> "$program"
            cat "$file" >> "$program"
        done
    done
else
    cp "$input" "$program"
fi

strip_noise() { grep -v -e 'xdg-user-dir' -e '^\s*$' || true; }

run_vm() {
    local vm="$1" bin
    bin=$(binary_of "$vm")
    local entry="$work/program_$vm.verse"
    cp "$program" "$entry"
    if [ "$vm" = new ]; then
        # VerseCmd's Yield suspends the script for one turn of its event loop.
        printf '\nBenchRuntime<public> := module:\n    CommitPoint<public>()<suspends>:void = Yield()\n' >> "$entry"
        "$bin" "$entry" 2>&1 | strip_noise
    else
        # NextTick suspends the task, which commits the transaction; VerseCLR's tick loop resumes it.
        printf '\nBenchRuntime<public> := module:\n    using { /Verse.org/VerseCLR }\n    CommitPoint<public>()<suspends>:void = NextTick()\n' >> "$entry"
        # VerseCLR cannot invoke a <suspends> target directly on the BPVM (coroutine resume state is left
        # uninitialized), so Main is started from Verse with spawn, exactly like game code starts a task.
        printf '\n%s():void = spawn{Main(array{}, map{})}\n' "$BPVM_ENTRY" >> "$entry"
        "$bin" --log=none --open="$entry" --target="$BPVM_ENTRY" 2>&1 | strip_noise
    fi
}

# Median of each PROFILE tag per VM (robust to the warm-up pass), then "Native X" vs every other "<Variant> X".
compare() {
    python3 - "$work" "$@" <<'PY'
import re, statistics, sys
work, vms = sys.argv[1], sys.argv[2:]
runs = {}
for vm in vms:
    for line in open(f'{work}/{vm}.out', encoding='utf-8', errors='replace'):
        m = re.match(r'PROFILE (.+): ([0-9.]+) ms$', line.strip())
        if m:
            runs.setdefault(m.group(1), {}).setdefault(vm, []).append(float(m.group(2)))
median = {tag: {vm: statistics.median(v) for vm, v in by_vm.items()} for tag, by_vm in runs.items()}
header = lambda title: print(f'{title:<36}' + ''.join(f' {vm:>10}' for vm in vms))
cell = lambda x: f' {x:10.3f}' if x is not None else f' {"-":>10}'
header('tag (median ms)')
for tag, by_vm in median.items():
    print(f'{tag:<36}' + ''.join(cell(by_vm.get(vm)) for vm in vms))
pairs = [(tag, other) for tag in median if tag.startswith('Native ')
         for other in median if other != tag and other.split(' ', 1)[-1] == tag.split(' ', 1)[1]]
if pairs:
    print()
    header('native vs rewrite (x faster)')
    for native, rewrite in pairs:
        row = ''
        for vm in vms:
            n, r = median[native].get(vm), median[rewrite].get(vm)
            row += f' {n / r:9.2f}x' if n and r else f' {"-":>10}'
        print(f'{rewrite + " / " + native.split(" ", 1)[0]:<36}{row}')
PY
}

if [ "${#vms[@]}" = 1 ]; then
    run_vm "${vms[0]}"
else
    for vm in "${vms[@]}"; do
        echo "== $vm"
        run_vm "$vm" | tee "$work/$vm.out"
    done
    echo "== comparison"
    compare "${vms[@]}"
fi
