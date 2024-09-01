# UWB_localization (Python)

## Objective
+ Measure the localization error using UWB

## Directory (default example)
+ input
    + case0 (our experimental dataset in `dataset/UWB_localization`)
        + localization_0.csv
        + ...
        + localization_4.csv
+ 00_average_error.py

## Usage
+ Acquire tracking data with the app: `app/DWLoc`
    + As much as you want to average the localization distance
+ Change each file name sequentially by the number of files
    + localization.csv -> localization_0.csv
    + localization.csv -> localization_1.csv
    + ...
+ Fold the files per case and name each folder sequentially by the number of cases
    + caseW
        + localization_0.csv
        + ...
        + localization_4.csv
+ Execute python codes in order
    + `python 00_average_error.py`
    + Input the case number: `W`
    + Input x [m] of UWB tag: `X` # coordinates are defined below
    + Input y [m] of UWB tag: `Y` # coordinates are defined below
    + Average Error for Case W: ...
    + Results saved to output/caseW/error.csv
+ Or batch is available with the command `./analyze_uwb.sh`
    + Edit the number of cases in line 3
+ Check each result in generated `output` directory
    + caseX
        + error.csv

## Our Experimental Dataset
+ The localization data at different coordinates are
    + `dataset/UWB_localization`
+ `cases.csv` shows 2D coordinates of the phone location
+ The coordinates of each case are
```
  x  -5    -3    -1     1     3     5
y  ----------------------------------
0 |   5     4     3  *  2     1     0
  |                                
2 |  11    10     9     8     7     6
  |                                
4 |  17    16    15    14    13    12
  |                                
6 |  23    22    21    20    19    18
```
+ *: UWB Anchor (DW3000)
+ For example, the location of case 7 is (3, 2)
