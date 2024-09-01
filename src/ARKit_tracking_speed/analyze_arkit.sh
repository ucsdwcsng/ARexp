#!/bin/bash

cases=(0)

for i in "${cases[@]}"; do
    echo -e "$i" | python 00_extract_vive.py
    echo -e "$i\n15" | python 01_evaluate_arkit.py
done

echo "All scripts are done"
