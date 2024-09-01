#import <UIKit/UIKit.h>

// VispDetector.h

@interface VispDetector : NSObject

/**
 Detects AprilTag markers in the given image and returns information about them.

 @param image The image in which to detect AprilTag markers.
 @param px The x-coordinate of the camera's principal point, typically the image width divided by 2.
 @param py The y-coordinate of the camera's principal point, typically the image height divided by 2.
 @return A dictionary containing the processed image with detected tags drawn on it, the number of detected tags, and an array of dictionaries for each detected tag with its ID and 3D position (x, y, z).
 */
- (NSDictionary *)detectAprilTag: (UIImage*)image px:(float)px py:(float)py;

@end
