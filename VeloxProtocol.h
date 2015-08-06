#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ArrowViewPosition){
	ArrowViewPositionTop,
	ArrowViewPositionBottom
};

@class VeloxNotificationController;

@protocol VeloxView
@property (nonatomic, assign) NSArray* bulletins;
@property (nonatomic, assign) VeloxNotificationController *controller;
- (id)initWithBundleIdentifier:(NSString *)bundleIdentifier;
- (CGFloat)viewHeight;

@optional
- (UIColor*)preferredArrowColorForArrowPosition:(ArrowViewPosition)position isDarkMode:(BOOL)darkMode;
- (UIColor*)backgroundColorForDarkMode:(BOOL)darkMode;
- (BOOL)needsNotifications;
- (BOOL)includeArrowView;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;
@end