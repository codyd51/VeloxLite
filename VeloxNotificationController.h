#import <UIKit/UIKit.h>
#import "VeloxProtocol.h"
#import "VeloxGenericNotificationView.h"

@interface VeloxNotificationController : NSObject
@property (nonatomic) NSArray* bulletins;
@property (nonatomic, retain) NSString *heldIconIdentifier;
@property (nonatomic, retain) NSMutableArray *iconsToMoveUp;
@property (nonatomic, retain) UIButton *dismissButton;
@property (nonatomic, retain) VeloxGenericNotificationView *genericView;
@property (nonatomic, retain) UIView<VeloxView> *specializedView;
@property (nonatomic, retain) _UIBackdropView* specializedFullBackBlur;
@property (nonatomic, assign) BOOL isLightMode;
+(id)sharedController;
-(void)showSpecializedNotificationViewForBundleIdentifier:(NSString *)bundleIdentifier;
-(void)showGenericNotificationViewForBundleIdentifier:(NSString *)bundleIdentifier;
-(void)registerLongHoldNotificationWithBundleIdentifier:(NSString *)bundleIdentifier;
-(void)handleIconHeldFromSender:(UILongPressGestureRecognizer *)sender;
-(BOOL)removeVeloxViewsFromView:(UIView *)view;
-(void)performGenericOpeningAnimation;
@end