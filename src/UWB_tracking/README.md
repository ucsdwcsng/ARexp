# UWB_tracking (Python)

## Objective
+ Measure the tracking error using UWB

## Directory (default example)
+ input
    + case0 (our experimental dataset in `dataset/UWB_tracking`)
        + localization.csv
        + output.csv
+ 00_interpolate_ground_truth_from_xy_stage.py
+ 01_uwb_classify_sensor.py
+ 02_uwb_extract_uwb.py
+ 03_uwb_extract_imu.py
+ 04_uwb_resample_data.py
+ 05_draw_error_timeline.py

## Usage
+ Acquire tracking data with the app: `app/DWLoc`
    + The file name is localization.csv
+ Acquire the ground truth with an xy-stage: `truth/stage/dynamic.py`
    + The file name is output.csv
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseX
        + localization.csv
        + output.csv
+ Execute python codes in order
    + `python 00_interpolate_ground_truth_from_xy_stage.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `X`
    + Input the offset [m] between QR and initial phone position: `0.2`
    + Processing case X
    + `python 01_uwb_classify_sensor.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `X`
    + Processing case X
    + `python 02_uwb_extract_uwb.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `X`
    + Processing case X
    + `python 03_uwb_extract_imu.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `X`
    + Processing case X
    + `python 04_uwb_resample_data.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `X`
    + Processing case X
    + `python 05_draw_error_timeline.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `X`
    + Processing case X
+ Or batch is available with the command `./analyze_uwb.sh`
    + Edit the number of cases in line 3
+ Check each result in generated `output` directory
    + caseX
        + error_statistics.csv (Max, Min, Mean, Variance, Standard Deviation, 99th Percentile of the tracking error)
        + error_timeline.png (the graph of the time-series tracking error)
        + error_timeline.csv (the data of the time-series tracking error)

## Our Experimental Dataset
+ The cases are in `dataset/UWB_tracking`
+ The directory includes `cases.csv` to show settings of each case
