#!/usr/bin/env bash

# Add more md pages names here
declare -a mdPagesNames=(
    "dialects"
    "vocabularies"
)

for name in "${mdPagesNames[@]}"
do
    menuMd="_includes/${name}_menu.md"
    markdown-toc "${name}.md" --no-firsth1 --bullets "*" > ${menuMd}
    # remove first line which contains anchor link to the page title
    tail -n +2 "${menuMd}" > "${menuMd}.tmp" && mv "${menuMd}.tmp" "${menuMd}"
    kramdown ${menuMd} > "_includes/${name}_menu.html"
    rm ${menuMd}
done
