#ifndef VELOX_INTERNAL_H
#define VELOX_INTERNAL_H

#import "Velox.h"
#import <UIKit/UIKit.h>

#ifdef DEBUG
#define DebugLog(s, ...) NSLog(@"[Velox] %@", [NSString stringWithFormat:(s), ##__VA_ARGS__]);
#else
#define DebugLog(s, ...)
#endif

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#ifdef __cplusplus
extern "C" {
#endif

void generateSupportedApps();


#ifdef __cplusplus
}
#endif  

typedef NS_ENUM(NSInteger, VLXActivationMethod) {
	VLXActivationMethodSwipeUp,
	VLXActivationMethodSwipeDown,
	VLXActivationMethodDoubleTap,
	VLXActivationMethodTripleTap,
	VLXActivationMethodHold
};

@interface SBIconView : UIView
@property (nonatomic, retain) id icon;
@property (nonatomic, assign) int location;
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) CGFloat iconLabelAlpha;
-(id)initWithDefaultSize;
- (BOOL)isInDock;
-(void)_setIcon:(id)icon animated:(BOOL)animated;
@end
/*
@interface SBFolder : NSObject
- (id)allIcons;
@end
@interface SBApplication : NSObject
- (id)bundleIdentifier;
-(id)applicationWithBundleIdentifier:(NSString*)bundleIdentifier;
@end
@interface SBIcon : NSObject
- (id)applicationBundleID;
@end
@interface SBApplicationIcon : SBIcon
- (id)application;
-(id)initWithApplication:(id)app;
@end

@interface SBBulletinViewController : UITableViewController
- (id)sectionAtIndex:(NSUInteger)sectionIndex;
@end
@interface SBIconController : NSObject
+ (id)sharedInstance;
- (void)handleHomeButtonTap;
- (void)getListView:(id *)view folder:(id *)folder relativePath:(id *)path forIndexPath:(id)indexPath createIfNecessary:(BOOL)necessary;
-(id)allApplications;
-(id)currentFolderIconList;
@end
@interface SBApplicationController : NSObject
+(id)sharedInstance;
-(id)applicationWithDisplayIdentifier:(NSString*)bundleIdentifier;
@end
*/

@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayIdentifier;
- (NSArray *)applicationsWithBundleIdentifier:(NSString *)displayIdentifier;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBIcon : NSObject
@property (nonatomic, assign) SBApplication *application;
- (id)initWithApplication:(SBApplication *)application;
- (NSString *)applicationBundleID;
@end

@interface SBApplicationIcon : SBIcon
- (SBApplication *)application;
@end

@interface SBFolder : NSObject
- (NSArray *)allIcons;
@end

@protocol SBIconModelDelegate;

@interface SBIconModel : NSObject
@property (nonatomic, retain) NSDictionary *leafIconsByIdentifier;
//@property (assign, nonatomic) id<SBIconModelDelegate> delegate;
-(id)expectedIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end
/*
@interface SBIconView : UIView
@property (nonatomic, retain) SBIcon *icon;
//@property (nonatomic, assign) int location;
@property (nonatomic, assign) id delegate;
//@property (nonatomic, assign) CGFloat iconLabelAlpha;
- (id)initWithDefaultSize;
- (BOOL)isInDock;
- (void)_setIcon:(SBIcon *)icon animated:(BOOL)animated; // iOS 7+
@end
*/
@interface SBIconViewMap : NSObject
+ (id)homescreenMap;
- (SBIconView *)iconViewForIcon:(id)arg1;
- (id)mappedIconViewForIcon:(id)icon;
@end

@interface SBIconListView : NSObject
- (NSArray *)visibleIcons;
- (SBIconViewMap *)viewMap;
- (NSUInteger)rowForIcon:(SBIcon *)icon;
- (void)setIconsNeedLayout;
- (void)layoutIconsIfNeeded:(CGFloat)duration domino:(BOOL)domino;
@end

@interface SBFolderIconListView : SBIconListView
@end

@interface SBDockIconListView : SBIconListView
@end
/*
@interface SBIconImageView : UIView
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (SBIconModel *)model;
- (SBDockIconListView *)dock;
- (SBIconListView *)currentRootIconList;
- (SBFolderIconListView *)currentFolderIconList;
- (NSArray *)allApplications;
- (void)getListView:(id *)view folder:(id *)folder relativePath:(id *)path forIndexPath:(id)indexPath createIfNecessary:(BOOL)necessary;
- (void)handleHomeButtonTap;
@end

@interface BBBulletin : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, retain) id modalAlertContent;
@property (nonatomic, retain) id starkBannerContent;
@property (assign, nonatomic) BOOL hasEventDate;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSDate *recencyDate;
@end
*/
@interface SBBulletinListSection : NSObject
@property (nonatomic, copy) NSString *sectionID;
// iOS 6
- (id)bulletinAtIndex:(NSUInteger)index;
- (NSUInteger)bulletinCount;
// iOS 7
@property (nonatomic, readonly) NSArray *bulletins;
@end

@interface SBBulletinListController : UIViewController
+ (id)sharedInstanceIfExists;
- (SBBulletinListSection *)_sectionAtIndex:(NSUInteger)index;
@end

@interface SBNotificationCenterSectionInfo : NSObject
- (SBBulletinListSection *)representedListSection;
@end

@interface SBBulletinViewController : UITableViewController
- (SBNotificationCenterSectionInfo *)sectionAtIndex:(NSUInteger)sectionIndex;
@end

@interface SBBulletinObserverViewController : UIViewController
@property (nonatomic,readonly) SBBulletinViewController *bulletinViewController;
@end

@interface SBNotificationsModeViewController : SBBulletinObserverViewController
@end

@interface SBNotificationsAllModeViewController : SBNotificationsModeViewController
@end

@interface SBNotificationCenterViewController : UIViewController
- (SBBulletinObserverViewController *)_allModeViewControllerCreateIfNecessary:(BOOL)necessary;
@end

@interface SBNotificationCenterController : NSObject
@property (nonatomic, retain, readonly) SBNotificationCenterViewController *viewController;
+ (id)sharedInstanceIfExists;
@end

@interface _UIBackdropViewSettings : NSObject
+ (id)settingsForPrivateStyle:(int)style;
@end

@interface _UIBackdropView : UIView
- (id)initWithFrame:(CGRect)frame autosizesToFitSuperview:(BOOL)fits settings:(_UIBackdropViewSettings *)settings;
- (void)setBlurQuality:(id)quality;
@end

@interface UIApplication (Asos)
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
@end

@interface SBIconImageView : UIView
@end 

@interface BBulletin : NSObject
@property (nonatomic,copy) NSString * title; 
@property (nonatomic,copy) NSString * subtitle; 
@property (nonatomic,copy) NSString * message; 
@property (nonatomic,retain) id modalAlertContent;
@property (nonatomic,retain) id starkBannerContent;
@property (assign,nonatomic) BOOL hasEventDate;
@property (nonatomic,retain) NSDate * date;
@property (nonatomic,retain) NSDate * endDate;
@property (nonatomic,retain) NSDate * recencyDate;
@end

@protocol CityUpdaterDelegate
@end

@interface UIView (Velox)
@property (nonatomic) CGFloat suggestedHeight;
- (void)setUpWithFrame:(CGRect)frame bundleIdentifier:(NSString*)bundleIdentifier;
- (void)removeSelfFromVeloxView;
@end

@interface SBRootFolder : NSObject
- (id)indexPathForIcon:(id)icon;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (SBIconModel *)model;
- (id)allApplications;
- (BOOL)isEditing;
- (id)currentRootIconList;
- (id)currentFolderIconList;
- (NSArray*)visibleIcons;
- (void)getListView:(id *)view folder:(id *)folder relativePath:(id *)path forIndexPath:(id)indexPath createIfNecessary:(BOOL)necessary;
@end
@interface UIApplication ()
-(void)launchApplicationWithIdentifier:(id)ident suspended:(BOOL)suspended;
@end

@interface PKGlyphView : UIView {
    unsigned int _transitionIndex;
    BOOL _transitioning;
    int _priorState;
    NSMutableArray *_transitionCompletionHandlers;
    double _lastAnimationWillFinish;
    BOOL _phoneWiggling;
    NSString *_phoneWiggleAnimationKey;
    struct {
        unsigned int showingPhone:1;
        unsigned int phoneRotated:1;
    } _layoutFlags;
    UIView *_fingerprintView;
    float _phoneAspectRatio;
    UIImageView *_customImageView;
    UIColor *_primaryColor;
    UIColor *_secondaryColor;
    UIImage *_customImage;
    int _state;
    id _delegate;
}

@property(assign, nonatomic) id delegate; // @synthesize delegate=_delegate;
@property(readonly, nonatomic) int state; // @synthesize state=_state;
@property(retain, nonatomic) UIImage *customImage; // @synthesize customImage=_customImage;
@property(copy, nonatomic) UIColor *secondaryColor; // @synthesize secondaryColor=_secondaryColor;
@property(copy, nonatomic) UIColor *primaryColor; // @synthesize primaryColor=_primaryColor;
- (void)setSecondaryColor:(id)arg1 animated:(BOOL)arg2;
- (void)setPrimaryColor:(id)arg1 animated:(BOOL)arg2;
- (void)_updateCheckViewStateAnimated:(BOOL)arg1;
- (void)_updateCustomImageViewOpacityAnimated:(BOOL)arg1;
- (void)_endPhoneWiggle;
- (void)_startPhoneWiggle;
- (void)_updatePhoneWiggleIfNecessary;
- (void)_updatePhoneLayoutWithTransitionIndex:(unsigned int)arg1 animated:(BOOL)arg2;
- (void)_performTransitionWithTransitionIndex:(unsigned int)arg1 animated:(BOOL)arg2;
- (void)_finishTransitionForIndex:(unsigned int)arg1;
- (void)_executeTransitionCompletionHandlers:(BOOL)arg1;
- (void)setState:(int)arg1 animated:(BOOL)arg2 completionHandler:(void (^)())arg3;
- (void)setState:(int)arg1;
- (void)_executeAfterMinimumAnimationDurationForStateTransition:(void (^)())arg1;
- (double)_minimumAnimationDurationForStateTransition;
- (void)_updateLastAnimationTimeWithAnimationOfDuration:(double)arg1;
- (void)layoutSubviews;
- (void)dealloc;
//- (id)initWithStyle:(int)arg1;
- (id)initWithFrame:(struct CGRect)arg1;

@end

//@class SBFolderIconListView;

VLX_EXTERN SBBulletinViewController *bulletinViewController;

VLX_EXTERN SBIconView *globalViewSender;

VLX_EXTERN UIView* arrowView;

VLX_EXTERN BOOL darkMode;
VLX_EXTERN VLXActivationMethod activationMethod;

VLX_EXTERN NSMutableDictionary *supportedApps;
VLX_EXTERN NSMutableArray *iconViews;
VLX_EXTERN NSMutableArray *folders;
VLX_EXTERN NSMutableArray *lockedApps;
VLX_EXTERN NSMutableDictionary* folderIcons;

VLX_EXTERN int pass;
VLX_EXTERN BOOL touchIDFirst;
VLX_EXTERN BOOL clearPass;
VLX_EXTERN BOOL autoclose;

#endif /* VELOX_INTERNAL_H */