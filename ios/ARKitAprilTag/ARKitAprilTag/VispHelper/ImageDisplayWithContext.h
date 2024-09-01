#import <UIKit/UIKit.h>
#ifdef __cplusplus
#import <visp3/visp.h>
#endif

#import "ImageDisplay.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageDisplay (withContext)

+ (void)displayLineWithContext:(CGContextRef)context :(std::vector<vpImagePoint>)polygon :(UIColor*)color :(int)tickness;

+ (void)displayFrameWithContext:(CGContextRef)context :(const vpHomogeneousMatrix &)cMo :(const vpCameraParameters &)cam :(double) size :(int)tickness;

+ (void)displayText:(NSString*)text :(double)x :(double)y :(int)width :(int)height :(UIColor*)color :(UIColor*)bgColor;

@end

NS_ASSUME_NONNULL_END
