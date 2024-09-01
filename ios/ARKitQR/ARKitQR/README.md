# ARKitQR

## Objective
+ Track self　position using ARKit with a QR code as the origin

## Our environment
+ Hardware
    + iPhone 12 Pro
    + iPhone 15 Pro
    + Mac mini
+ Software
    + iOS 17.2
    + macOS 14.2
    + Xcode 15.0

## Preparation
+ Print the QR code
    + Example: `Anchor1.svg`
+ Set the email address for data submission
    + Modify line 12 in `ARKitQR/MailHandler.swift`
    + `mailController.setToRecipients([""]) // Please input an e-mail address to which you send the data.`
    + Add the recipient's email address inside the quotation marks
+ Install the app on your iPhone using Apple's Xcode

## How to use the app
+ Launch the app
+ Press the "Reset Anchor Point" button to clear the cache
+ Scan the QR code with the camera to start tracking
+ Press the "Send Email" button to send the data via email
