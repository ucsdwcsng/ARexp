# ARCoreQR

## Objective
+ Track self　position using ARCore with a QR code as the origin

## Our environment
+ Hardware
    + Google Pixel 8 Pro
    + Intel(R) Core(TM) i9-13900K 32 GB RAM
+ Software
    + Android 14.0
    + Windows 11
    + Android Studio Koala | 2024.1.1 Patch 1

## Preparation
+ Print the QR code
    + Example: `Anchor1.svg`
+ Install ARCore app on your Android device
    + Install [this](https://play.google.com/store/apps/details?id=com.google.ar.core&hl=en)
+ Install the app on your device using Android Studio
    + You must use ARCore compatible models

## How to use the app
+ Launch the app
    + Automatically start scanning a QR code
+ Read the code with the camera
    + If the QR code is scanned as an anchor, coordinates and a mark of the anchor is displayed on the screen
    + Coordinates example: `x: 1.00, y: -0.01, z: 2.00`
    + The mark is like a square pillar
+ Press the "START" button to start tracking
+ Press the "STOP" button to finish tracking
+ Connect the device to the computer including Android Studio
+ Open the device explorer on Android Studio
    + In the menu bar, go to View -> Tool Windows -> Device Explorer
+ Access to `/storage/emulated/0/Android/data/com.shibiwilliam.arcoremeasurement/files`
    + You can find the .csv data with the recorded time: `experiment_yymmdd_hhmmss.csv`
    + Ex. `experiment_240901_083030.csv`
+ Pick up the file and rename the file as `ARCoreData.csv`
