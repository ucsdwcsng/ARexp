# Experience: Practical Challenges for Indoor AR Applications
This project shows evaluation systems and datasets in our paper accepted for publication at ACM MobiCom 2024. 

## Our Findings
This paper shares the challenges facing today's augmented reality (AR) smartphone applications, particularly in the realm of localization and tracking failure. 
Our research identifies limitations in current vision-based localization, such as the reliance on close-range landmark detection using QR codes and AprilTags, and the drawbacks of LiDAR integration in variable lighting conditions, compromising AR's accuracy and functionality. 
Additionally, this paper examines the constraints of Inertial Measurement Units (IMU) on movement speed, highlighting its impact on the dynamic performance of AR applications. 
To overcome these challenges, we discuss the possibility of integrating Radio Frequency (RF)-based localization (WiFi, UWB, et al.) with existing vision-based methods. 
We show this hybrid approach mitigates the limitations of each localization, particularly in indoor settings, offering a robust solution for immersive and accurate AR experiences across diverse environments. 
Based on our extensive 312 experimental cases for 109 hours, this paper contributes to the field by presenting a nuanced analysis of the failure modes inherent in smartphone-based AR localization and proposing a novel solution that marries RF technology with vision-based systems. 
Our approach addresses the immediate challenges of AR localization and opens avenues for future research and development in creating more spatially aware and interactive digital worlds. 

If you get interested in our study in detail, please check [our paper](https://doi.org/10.1145/3636534.3690676). 

## Demonstration video
We are publishing our demonstration video [here](https://youtube.com/playlist?list=PLXtStszKB5d3WeKZdv8Ifx3XZBCN89M4X&si=7LwOoW8OP5Ly6CLe). 
The playlist above includes our 15-subject case study in Sec. 2 to highlight the challenges of current AR systems. 

## Directories
```
.
├── README.md (me)
├── android
├── firmware
├── ios
├── src
├── truth
└── dataset.zip
```
+ android: Android apps to localize and track the smartphone
+ firmware: Binaries and C++ code to setup the specific hardware: DW3000 for UWB communication and the xy-stage
+ ios: iOS apps to localize and track the smartphone
+ src: Python codes to analyze the localization and tracking data
+ truth: Python codes to acquire the ground truth of localization and tracking
+ dataset.zip: recorded localization and tracking data through our experiments
+ Each directory includes README.md so that please also refer to each file

## Citation
If you use the dataset or evaluation system in your work, please consider citing the following paper:
```
@INPROCEEDINGS{yamaguchi24:mobicom,
  title     = "Experience: Practical Challenges for Indoor AR Applications",
  author    = "Shunpei Yamaguchi and Aditya Arun and Takuya Fujiwara and Misaki Sakuta and Ryotaro Hada and Takuya Fujihashi and Takashi Watanabe and Dinesh Bharadia and Shunsuke Saruwatari",
  Booktitle = "ACM MobiCom '24: 30th Annual International Conference on Mobile Computing and Networking",
  pages   = "1--15",
  year    =  2024
}
```

## Article Author
Shunpei Yamaguchi

Graduate School of Information Science and Technology, Osaka University, Japan
