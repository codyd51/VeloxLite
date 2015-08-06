#import "UIImage+Color.h"

@implementation UIImage (Color)
+(UIImage *)imageWithColor:(UIColor *)color andFrame:(CGRect)frame {
	UIGraphicsBeginImageContext(frame.size);
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, frame);

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return image;
}
@end