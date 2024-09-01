#!/bin/bash

cases=(0)

for i in "${cases[@]}"; do
    echo -e "$i\n$i\n0.2" | python 00_interpolate_ground_truth_from_xy_stage.py
    echo -e "$i\n$i" | python 01_uwb_classify_sensor.py
    echo -e "$i\n$i" | python 02_uwb_extract_uwb.py
    echo -e "$i\n$i" | python 03_uwb_extract_imu.py
    echo -e "$i\n$i" | python 04_uwb_resample_data.py
    echo -e "$i\n$i" | python 05_draw_error_timeline.py
done

echo "All scripts are done"
