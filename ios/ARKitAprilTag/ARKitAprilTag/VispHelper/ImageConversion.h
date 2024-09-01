#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <visp3/visp.h>
#endif

#ifndef DOXYGEN_SHOULD_SKIP_THIS

@interface ImageConversion : NSObject

+ (vpImage<vpRGBa>)vpImageColorFromUIImage:(UIImage *)image;
+ (vpImage<unsigned char>)vpImageGrayFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromVpImageColor:(const vpImage<vpRGBa> &)I;
+ (UIImage *)UIImageFromVpImageGray:(const vpImage<unsigned char> &)I;

@end

#endif

