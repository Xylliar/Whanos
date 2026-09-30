#!/bin/bash
set -euo pipefail

matches=()
[ -f Makefile ] && matches+=(c)
[ -f app/pom.xml ] && matches+=(java)
[ -f package.json ] && matches+=(javascript)
[ -f requirements.txt ] && matches+=(python)
[ -f app/main.bf ] && matches+=(befunge)

if [ "${#matches[@]}" -eq 0 ]; then
    echo "error: this repository is not Whanos-compatible: no supported language detected" >&2
    exit 1
fi

if [ "${#matches[@]}" -gt 1 ]; then
    echo "error: this repository is not Whanos-compatible: it matches several languages (${matches[*]})" >&2
    exit 1
fi

echo "${matches[0]}"
