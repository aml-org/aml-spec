#!/usr/bin/env bash

# Add more md pages names here
declare -a mdPagesNames=(
    "dialects"
    "vocabularies"
)

for name in "${mdPagesNames[@]}"
do
    markdown-toc "${name}.md" --no-firsth1 --bullets "*" > "_includes/${name}_menu.md"
    kramdown "_includes/${name}_menu.md" > "_includes/${name}_menu.html"
    rm "_includes/${name}_menu.md"
done
