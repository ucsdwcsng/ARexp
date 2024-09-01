#!/bin/bash

cases_dynamic=(12 13 14) # input the number of cases

for i in "${cases_dynamic[@]}"; do
    echo -e "$i\n$i" | python 00_generate_ground_truth_on_xy_stage.py
    echo -e "$i\n$i" | python 01_resample_arkit_data.py
    echo -e "$i\n$i" | python 02_trim_data_for_static.py
    echo -e "$i\n$i" | python 03_draw_error_timeline.py
done

echo "All scripts are done"
