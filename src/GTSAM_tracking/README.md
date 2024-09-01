# GTSAM_tracking (Python)

## Objective
+ Fuse VIO and UWB data with GTSAM

## Directory (default example)
+ input
    + case0 (our experimental dataset in `dataset/GTSAM_tracking`)
        + resampled_arkit.csv
        + resampled_truth.csv
        + resampled_uwb.csv
        + resampled_uwb_truth.csv
    + cases.csv
+ 00_interpolate_ground_truth_from_xy_stage.py
+ 01_uwb_classify_sensor.py
+ 02_uwb_extract_uwb.py
+ 03_uwb_extract_imu.py
+ 04_uwb_resample_data.py
+ 05_draw_error_timeline.py

## Usage
+ Acquire ARKit and UWB tracking data with the apps: `app/ARKitQR` and `app/DWLoc`
+ Execute ARKit and UWB tracking algorithms
    + ARKit-based tracking with `ARKit_tracking_*`
    + UWB-based tracking with `UWB_tracking`
+ Move the four files below in `ARKit_tracking_*/.temp` and `UWB_tracking_*/.temp` to `input`
    + resampled_arkit.csv
    + resampled_truth.csv
    + resampled_uwb.csv
    + resampled_uwb_truth.csv
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseX
        + resampled_arkit.csv
        + resampled_truth.csv
        + resampled_uwb.csv
        + resampled_uwb_truth.csv
+ Modify the condition in `input/cases.csv` for the reference to each case
+ Execute python codes in order
    + `python 00_fuse_ARKit_and_UWB.py`
    + Input the index of the case number: `X`
    + ...
+ Check each result in generated `output` directory
    + caseX
        + error_cdf.png (CDF of the time-series tracking error)
        + error_timeline.csv (the time-series tracking error)
        + error_timeline.png (the graph of the time-series tracking error)
        
## Our Experimental Dataset
+ The cases are in `dataset/GTSAM_tracking`
+ The directory includes `cases.csv` to show settings of each case
