# ARKit_tracking_dynamic (Python)

## Objective
+ Measure the tracking error in dynamic cases on an XY-stage

## Directory (default example)
+ input
    + case0 (our experimental dataset in `dataset/ARCore_tracking_smartphone_pixel8pro`)
        + ARCoreData.csv
        + output.csv
+ 00_interpolate_ground_truth_from_xy_stage.py
+ 01_resample_arcore_data.py
+ 02_draw_error_timeline.py

## Usage
+ Acquire tracking data with the app: `app/ARCoreQR`
    + Please rename the file name as ARCoreData.csv
+ Acquire the ground truth with an xy-stage: `truth/stage/dynamic.py`
    + The file name is output.csv
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseX
        + ARCoreData.csv
        + output.csv
    + caseY
        + ARCoreData.csv
        + output.csv
+ Execute python codes in order
    + `python 00_interpolate_ground_truth_from_xy_stage.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Input the offset [m] between QR and initial phone position: `0.2`
    + Processing case X
    + Processing case Y
    + `python 01_resample_arcore_data.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
    + `python 02_draw_error_timeline.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
+ Or batch is available with the command `./analyze_arcore.sh`
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
+ The acquired cases are in `dataset/ARCore_tracking_smartphone_pixel8pro`
+ Each directory includes `cases.csv` to show settings of each case
