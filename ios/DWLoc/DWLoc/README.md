# DWLoc

## Objective
+ Track self　position using Apple's Nearby Interaction with Qorvo's DW3000 as the origin

## Our environment
+ Hardware
    + iPhone 12 Pro
    + Mac mini
+ Software
    + iOS 17.2
    + macOS 14.2
    + Xcode 15.0

## Preparation
+ Setup Qorvo's DW3000
    + Please follow the instruction in `firmware/dw3000/README.md`
+ Set the email address for data submission
    + Modify line 581 in `NINearbyAccessorySample/QorvoDemoViewController.swift`
    + `mailComposerVC.setToRecipients([""]) // Please input an e-mail address to which you send the data`
    + Add the recipient's email address inside the quotation marks
+ Install the app on your iPhone using Apple's Xcode

## How to use the app
+ Install Qorvo's DW3000 in the environment
+ Launch the app
    + Automatically start to scan the neighbor DW3000
+ Press "Connect" button of the target DW3000
    + Automatically start to localize DW3000
+ Press the "Send CSV" button to send the data via email
