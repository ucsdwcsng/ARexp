# ARKitDisplayFeature

## Objective
+ Measure the number of feature points acquired by ARKit

## Our environment
+ Hardware
    + iPhone 12 Pro
    + Mac mini
+ Software
    + iOS 17.2
    + macOS 14.2
    + Xcode 15.0

## Preparation
+ Set the email address for data submission
    + Modify line 137 in `ARKitDisplayFeature/ContentView.swift`
    + `mailComposer.setToRecipients([""]) // Please input an e-mail address to which you send the data.`
    + Add the recipient's email address inside the quotation marks
+ Install the app on your iPhone using Apple's Xcode

## How to use the app
+ Launch the app
+ Press the shutter button to send the data
    + Open the mailer and attach the number of feature points, an original picture, and a picture with the feature points
+ Send the data via e-mail
