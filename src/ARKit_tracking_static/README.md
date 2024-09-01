# ARKit_tracking_static (Python)

## Objective
+ Measure the tracking error in static cases on a tripod

## Directory (default example)
+ input
    + case12 (our experimental dataset in `dataset/ARKit_tracking_crowded`)
        + ARKitData.csv
    + case13 (our experimental dataset in `dataset/ARKit_tracking_crowded`)
        + ARKitData.csv
    + case14 (our experimental dataset in `dataset/ARKit_tracking_crowded`)
        + ARKitData.csv
+ 00_generate_ground_truth_on_xy_stage.py
+ 01_resample_arkit_data.py
+ 02_trim_data_for_static.py
+ 03_draw_error_timeline.py
+ analyze_arkit.sh

## Usage
+ Acquire tracking data with the app: `app/ARKitQR`
    + The file name is ARKitData.csv
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseX
        + ARKitData.csv
    + caseY
        + ARKitData.csv
+ Execute python codes in order
    + `python 00_generate_ground_truth_on_xy_stage.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
    + `python 01_resample_arkit_data.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
    + `python 02_trim_data_for_static.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
    + `python 03_draw_error_timeline.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
+ Or batch is available with the command `./analyze_arkit.sh`
    + Edit the number of cases in line 3
+ Check each result in generated `output` directory
    + caseX
        + error_statistics.csv (Max, Min, Mean, Variance, Standard Deviation, 99th Percentile of the tracking error)
        + error_timeline.png (the graph of the time-series tracking error)
        + error_timeline.csv (the data of the time-series tracking error)
    + caseY
        + error_statistics.csv (Max, Min, Mean, Variance, Standard Deviation, 99th Percentile of the tracking error)
        + error_timeline.png (the graph of the time-series tracking error)
        + error_timeline.csv (the data of the time-series tracking error)

## Our Experimental Dataset
+ The static cases with a tripod vary in
    + `dataset/ARKit_tracking_crowded`
    + `dataset/ARKit_tracking_crowded_drift`
    + `dataset/ARKit_tracking_shelf`
    + `dataset/ARKit_tracking_shelf_drift`
    + `dataset/ARKit_tracking_wall`
    + `dataset/ARKit_tracking_wall_drift`
+ Each directory includes `cases.csv` to show settings of each case
+ To check whether the case is static, please refer to the second row: Move
