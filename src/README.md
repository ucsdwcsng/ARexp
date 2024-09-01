# src (Python)

## Objective
+ Analyze sensor data acquired by the app

## Our environment
+ Hardware
    + Intel(R) Core(TM) i7-1185G7 32 GB RAM
+ Software
    + Ubuntu 22.04
    + Python 3.12.5

## Directory
+ ARKit_localization_landmark_direction
    + Measure the localization error with a QR code or AprilTag using ARKit
    + Correspond to Sec. 3.3
+ ARKit_localization_landmark_size
    + Measure the localization distance from a QR code or AprilTag at different angles using ARKit
    + Correspond to Sec. 3.2
+ ARKit_tracking_dynamic
    + Measure the tracking error of ARKit in dynamic cases on an XY-stage
    + Correspond to Sec. 3.4, 3.5, and 3.7
+ ARKit_tracking_speed
    + Measure the tracking error of ARKit in walk and swing cases
    + Correspond to Sec. 3.6
+ ARKit_tracking_static
    + Measure the tracking error of ARKit in static cases on a tripod
    + Correspond to Sec. 3.4, 3.5, and 3.7
+ ARCore_tracking
    + Measure the tracking error of ARCore in dynamic cases on an XY-stage
    + Correspond to Sec. 3.8
+ GTSAM_tracking
    + Fuse VIO and UWB data with GTSAM
    + Correspond to Sec. 4.3
+ UWB_localization
    + Measure the localization error using UWB
    + Correspond to Sec. 4.2
+ UWB_tracking
    + Measure the tracking error using UWB
    + Correspond to Sec. 4.3

## Note
+ Each directory includes README.md so that please read it how to use in detail
