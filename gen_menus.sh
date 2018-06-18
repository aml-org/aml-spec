#!/usr/bin/env bash

# Add more md pages names here
declare -a mdPagesNames=(
    "dialects"
    "vocabularies"
)

for name in "${mdPagesNames[@]}"
do
    menuMd="_includes/${name}_menu.md"
    markdown-toc "${name}.md" --no-firsth1 --maxdepth "1" --bullets "*" > ${menuMd}
    # remove the first line (anchor link)
    tail -n +2 "${menuMd}" > "${menuMd}.tmp" && mv "${menuMd}.tmp" "${menuMd}"
    kramdown ${menuMd} > "_includes/${name}_menu.html"
    rm ${menuMd}
done
