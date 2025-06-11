#!/bin/bash

set -e
bag index.janet

echo 'minifying site...'

find site \( -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.svg' \) -type f -print0 | while IFS= read -r -d '' file; do
	echo 'minifying' "$file"
	minify -i "$file"
done
