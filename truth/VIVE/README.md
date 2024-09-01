# VIVE

## Objective
+ Collect the ground truth with HTC VIVE CE 99HALN011-00

## Our environment
+ Hardware
    + Intel(R) Core(TM) i9-10850K 128 GB RAM, NVIDIA GeForce RTX 3080
+ Software
    + Windows 11
    + Python 3.10.9

## Procedure
+ Setup HTC VIVE
    + [Official webpage](https://www.vive.com/au/support/vive/category_howto/setting-up-for-the-first-time.html)
+ While running SteamVR, execute `collect_vive.py`
+ The data is saved as `data/vr_date_time.log`
    + Ex. vr_20240805_143025.log (vr_yymmdd_hhmmss.log)
