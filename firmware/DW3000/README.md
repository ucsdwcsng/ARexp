# DW3000

## Objective
+ Setup Qorvo's DWM3000EVB as an anchor for UWB measurement

## Our environment
+ Hardware
    + DWM3000EVB
    + Intel(R) Core(TM) i7-1185G7 32 GB RAM
+ Software
    + Windows 11
    + SEGGER J-Flash Lite V7.88c

## Procedure
+ Install J-Flash Lite [here](https://www.segger.com/downloads/jlink/)
    + We used V7.88c
    + Multiple software is installed but we use only J-Flash Lite this time
+ Open J-Flash Lite
+ Find and select `nRF52840_xxAA` in the field of "Device"
+ Select `./nRF52840DK-QANI-FreeRTOS_full_QNI_3_0_0.hex` in the field of "Data File"
+ Select the target nRF52840 from 'Program Device'
    + Start to install the firmware to DWM3000EVB
