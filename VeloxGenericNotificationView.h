#import <UIKit/UIView.h>
#import "VeloxProtocol.h"
#import "Velox_Internal.h"

@interface VeloxGenericNotificationView : UIView <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) NSString *bundleIdentifier;
@property (nonatomic, retain) _UIBackdropViewSettings *folderBlurBackSettings;
@property (nonatomic, retain) UIView *folderBlurBack;
@property (nonatomic, retain) _UIBackdropView *folderBlurArrowBackground;
@property (nonatomic, retain) UIView *folderBlurArrowView;
@property (nonatomic, retain) _UIBackdropViewSettings *fullBackBlurSettings;
@property (nonatomic, retain) _UIBackdropView *fullBackBlur;
@property (nonatomic, retain) UITableView *notificationTable;
@property (nonatomic, retain) UIBezierPath *backBezierPath;
@property (nonatomic, retain) UIImage *whitenUpBackBlurImage;
@property (nonatomic, retain) UIView *whitenUpBackBlurImageView;
@property (nonatomic, retain) NSArray *bulletins;
@property (nonatomic) CGFloat verticalOffset;
@property (nonatomic) CGFloat arrowOffset;
-(id)initWithFrame:(CGRect)frame bundleIdentifier:(NSString*)bundleIdentifier;
-(void)layoutSubviews;
-(void)updateForFrameChange;
@end