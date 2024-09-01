#import <UIKit/UIKit.h>
#ifdef __cplusplus
#import <visp3/visp.h>
#endif


#include <fstream>
#ifndef DOXYGEN_SHOULD_SKIP_THIS

@interface ImageDisplay : NSObject

+ (UIImage *)displayLine:(UIImage *)image :(vpImagePoint &)ip1 :(vpImagePoint &)ip2 :(UIColor*)color :(int)tickness;
+ (UIImage *)displayFrame:(UIImage *)image :(const vpHomogeneousMatrix &)cMo :(const vpCameraParameters &)cam
                         :(double) size :(int)tickness;

@end

#endif

