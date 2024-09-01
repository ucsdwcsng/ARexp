#!/bin/bash

cases_dynamic=(0) # input the number of cases

for i in "${cases_dynamic[@]}"; do
    echo -e "$i\n$i\n0.2" | python 00_interpolate_ground_truth_from_xy_stage.py
    echo -e "$i\n$i" | python 01_resample_arcore_data.py
    echo -e "$i\n$i" | python 02_draw_error_timeline.py
done

echo "All scripts are done"
