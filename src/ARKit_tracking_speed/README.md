# ARKit_tracking_speed (Python)

## Objective
+ Measure the tracking error in walk and swing cases

## Directory (default example)
+ input
    + case0 (our experimental dataset in `dataset/ARKit_tracking_speed`)
        + ARKitData.csv
        + VIVE.log
+ 00_extract_vive.py
+ 01_evaluate_arkit.py
+ analyze_arkit.sh

## Usage
+ Acquire tracking data with the app: `app/ARKitQR`
    + The file name is ARKitData.csv
+ Acquire the ground truth with HTC VIVE CE 99HALN011-00 on SteamVR: `truth/VIVE/collect_vr.py`
    + Please edit the file name to VIVE.log
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseX
        + ARKitData.csv
        + VIVE.log
+ Execute python codes in order
    + `python 00_extract_vive.py`
    + Please enter the case number (ex. 0 for case0): `X`
    + `python 01_evaluate_arkit.py`
    + Please enter the case number (ex. 1 for case1): `X`
    + Please input the ready time after start both devices with float [s]: `15` # please edit the time per case
+ Or batch is available with the command `./analyze_arkit.sh`
    + Edit the number of cases in line 3
    + Please edit the time per case in line 7
+ Check each result in generated `output` directory
    + caseX
        + trajectory.png: the 2D trajectory with ARKit and HTC VIVE
        + velocity_and_error.csv: the tracking error and its velocity
        + velocity_error.png: the graph of velocity_and_error.csv

## Our Experimental Dataset
+ The walk and swing cases are in
    + `dataset/ARKit_tracking_speed`
+ The directory includes `cases.csv` to show settings of each case
