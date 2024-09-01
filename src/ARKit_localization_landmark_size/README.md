# ARKit_localization_landmark_size (Python)

## Objective
+ Measure the localization distance from a QR code or AprilTag at different angles using ARKit

## Directory (default example)
+ input
    + case0 (our experimental dataset in `dataset/ARKit_localization_QR_size_S`)
        + ARKitData_0.csv
        + ...
        + ARKitData_9.csv
    + cases.csv
+ 00_extract_error.py

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
+ Modify the condition in `input/cases.csv` for the reference to each case
+ Execute python codes in order
    + `python 00_extract_error.py`
    + Input start index of the case number: `X`
    + Input end index of the case number: `Y`
    + Processing case X
    + Processing case Y
    + ...
+ Check each result in generated `output` directory
    + caseX
        + result.csv
    + caseY
        + result.csv
+ Retrieve the average localization error in each case
    + Unit: meter

## Our Experimental Dataset
+ As for cases with AprilTags, please refer to
    + `dataset/ARKit_localization_AprilTag_size_S` with 3 x 3 cm AprilTags
        + `dataset/ARKit_localization_AprilTag_size_S/cases.csv `includes settings of each case
    + `dataset/ARKit_localization_AprilTag_size_M` with 6 x 6 cm AprilTags
        + `dataset/ARKit_localization_AprilTag_size_M/cases.csv `includes settings of each case
    + `dataset/ARKit_localization_AprilTag_size_L` with 9 x 9 cm AprilTags
        + `dataset/ARKit_localization_AprilTag_size_L/cases.csv `includes settings of each case
+ As for cases with QR codes, please refer to
    + `dataset/ARKit_localization_QR_size_S` with 3 x 3 cm QR codes
        + `dataset/ARKit_localization_QR_size_S/cases.csv `includes settings of each case
    + `dataset/ARKit_localization_QR_size_M` with 6 x 6 cm QR codes
        + `dataset/ARKit_localization_QR_size_M/cases.csv `includes settings of each case
    + `dataset/ARKit_localization_QR_size_L` with 9 x 9 cm QR codes
        + `dataset/ARKit_localization_QR_size_L/cases.csv `includes settings of each case
+ Empty directory indicates that the app could not detect the marker
