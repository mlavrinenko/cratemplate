#!/usr/bin/env bash
# docs/generate-md.sh — render every docs/src/*.typ source to the Markdown its
# <docs-md> block declares.
#
# Each source names its own output, so adding a source touches this script not
# at all. `--check` renders into a temp tree and diffs the result against the
# committed output: a hand-edit or a stale render fails without writing.
set -eo pipefail

check=0
case "${1:-}" in
  "") ;;
  --check) check=1 ;;
  *) echo "usage: docs/generate-md.sh [--check]" >&2; exit 1 ;;
esac

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"
work="$(mktemp -d)"
tmp_out=""
cleanup() {
  [ -z "$tmp_out" ] || rm -f "$tmp_out"
  rm -rf "$work"
}
trap cleanup EXIT

out_root="$repo"
[ "$check" -eq 0 ] || out_root="$work"
cd "$repo"
shopt -s globstar nullglob

rendered=0
stale=0
err="$work/stderr"

for src in docs/src/**/*.typ; do
  [ "$(basename "$src")" = "lib.typ" ] && continue

  # typst eval, not the deprecated `typst query`; --target html --features html
  # is required because lib.typ's doc-title calls html.elem. stderr is held
  # back so typst's html-export warning stays out of a green run.
  if ! matches="$(typst eval 'query(<docs-md>).map(it => it.value)' --in "$src" \
      --root "$repo" --target html --features html 2>"$err")"; then
    echo "docs-md: typst eval failed on $src:" >&2
    cat "$err" >&2
    exit 1
  fi
  n="$(grep -o '"output"' <<<"$matches" | wc -l || true)"
  [ "$n" -eq 0 ] && continue
  if [ "$n" -ne 1 ]; then
    echo "docs-md: $src declares $n outputs, want exactly 1" >&2
    exit 1
  fi
  output="$(sed -n 's/.*"output":"\([^"]*\)".*/\1/p' <<<"$matches")"
  [ -n "$output" ] || { echo "docs-md: $src has no readable output path" >&2; exit 1; }

  body="$work/body"
  if ! typlite --root "$repo" "$src" "$body" 2>"$err"; then
    echo "docs-md: typlite failed on $src:" >&2
    cat "$err" >&2
    exit 1
  fi

  # doc-title renders as <h1>; demote the leading line to the ATX heading a
  # raw-text reader expects.
  sed -i -E '1s|^<h1>([^<>]*)</h1>$|# \1|' "$body"

  final="$work/final"
  printf '<!-- Generated from %s by just docs-md. Do not edit; edit the source. -->\n\n' "$src" >"$final"
  cat "$body" >>"$final"

  if [ "$check" -eq 1 ]; then
    if ! diff -u "$repo/$output" "$final"; then
      echo "docs-md-check: $output is stale; run just docs-md and commit it" >&2
      stale=1
    fi
  else
    dest="$out_root/$output"
    mkdir -p "$(dirname "$dest")"
    tmp_out="$(mktemp "$dest.XXXXXX")"
    cp "$final" "$tmp_out"
    chmod 644 "$tmp_out"
    mv -f "$tmp_out" "$dest"
    tmp_out=""
  fi
  rendered=$((rendered + 1))
done

if [ "$check" -eq 1 ]; then
  [ "$stale" -eq 0 ] || exit 1
  echo "docs-md-check: $rendered source(s) match the committed output"
else
  echo "docs-md: rendered $rendered source(s)"
fi
