#!/usr/bin/env bash
# Copies bench/ into a UEFN project as one Verse folder (= one module).
#
#   uefn-sync.sh <uefn-project-dir>
#
# UEFN compiles a folder's files in name order and a type alias cannot be used before its file,
# so the lib/ files get an "a_" prefix to come before harness/ (the CLI concatenates lib/ first too).
# cli/ is left out: its Main only exists for the command-line runtimes.
set -euo pipefail

project="${1:?usage: uefn-sync.sh <uefn-project-dir>}"
bench="$(cd "$(dirname "$0")/../bench" && pwd)"
target="$project/Content/NativeBench"

mkdir -p "$target"
rm -f "$target"/*.verse
for file in "$bench"/lib/*.verse; do
    cp "$file" "$target/a_$(basename "$file")"
done
cp "$bench"/harness/*.verse "$bench"/uefn/*.verse "$target/"
echo "$(ls "$target"/*.verse | wc -l) files -> $target"
