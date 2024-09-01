# ARKitAprilTag

## Objective
+ Track self　position using ARKit with an AprilTag as the origin

## Our environment
+ Hardware
    + iPhone 12 Pro
    + Mac mini
+ Software
    + iOS 17.2
    + macOS 14.2
    + Xcode 15.0

## Preparation
+ Print the AprilTag
    + Example: `tag36_11_00001.svg` created here: [AprilTag Generator](https://chaitanyantr.github.io/apriltag.html)
+ Set the actual size of the AprilTag
    + Modify line 26 in `AprilTagLiveCamera/VispDetector.mm`
    + `double tagSize = 0.03; // meter`
    + Change this value to the actual size in meters
+ Set the email address for data submission
    + Modify line 12 in `AprilTagLiveCamera/MailHandler.swift`
    + `mailController.setToRecipients([""]) // Please input an e-mail address to which you send the data.`
    + Add the recipient's email address inside the quotation marks
+ Install necessary frameworks
    + Install `opencv2` and `visp3`
    + Download `visp3.framework-2022-04-07.zip` from [ViSP for iOS](https://visp.inria.fr/download/)
    + Add `opencv2.framework` and `visp3.framework` to `ARKitAprilTag/Frameworks`
+ Install the app on your iPhone using Apple's Xcode

## How to use the app
+ Launch the app
+ Press the "Reset Anchor Point" button to clear the cache
+ Scan the AprilTag with the camera to start tracking
+ Press the "Send Email" button to send the data via email
