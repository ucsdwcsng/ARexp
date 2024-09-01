# ARKit_localization_landmark_direction (Python)

## Objective
+ Measure the localization error with a QR code or AprilTag using ARKit

## Directory (default example)
+ input
    + case7 (our experimental dataset in `dataset/ARKit_localization_AprilTag_direction`)
        + ARKitData_0.csv
        + ...
        + ARKitData_9.csv
+ 00_average_distance.py

## Usage
+ Acquire localization data with the app: `app/ARKitQR` or `app/ARKitAprilTag`
    + As much as you want to average the localization distance
+ Change each file name sequentially by the number of files
    + ARKitData.csv -> ARKitData_0.csv
    + ARKitData.csv -> ARKitData_1.csv
    + ...
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseX
        + ARKitData_0.csv
        + ARKitData_1.csv
        + ...
    + caseY
        + ARKitData_0.csv
        + ARKitData_1.csv
        + ...
+ Execute python codes in order
    + `python 00_average_distance.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + ...
    + Average distance: ...
    + Processing case Y
    + ...
    + Average distance: ...
+ Check each result in generated `output` directory
    + caseX
        + result.csv
    + caseY
        + result.csv
+ Retrieve the average distance in each case
    + Unit: meter

## Our Experimental Dataset
+ As for cases with AprilTags, please refer to
    + `dataset/ARKit_localization_AprilTag_direction`
    + `dataset/ARKit_localization_AprilTag_direction/cases.csv `includes settings of each case
+ As for cases with QR codes, please refer to
    + `dataset/ARKit_localization_QR_direction`
    + `dataset/ARKit_localization_QR_direction/cases.csv` includes settings of each case
+ Empty directory indicates that the app could not detect the marker
