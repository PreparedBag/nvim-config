# save as ~/scan-keys.sh, then: bash ~/scan-keys.sh
rg -N --no-heading -e "<leader>" lua/ | while IFS= read -r line; do
    key=$(echo "$line" | grep -oE "<leader>[^\"' ]+" | head -1)
    desc=$(echo "$line" | grep -oE "desc[[:space:]]*=[[:space:]]*[\"'][^\"']+" | sed -E "s/.*[\"'](.*)/\1/")
    [ -n "$key" ] && printf "%-18s %s\n" "$key" "$desc"
done | sort -u
