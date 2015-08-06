#import <UIKit/UIKit.h>
#import <notify.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import "Velox_Internal.h"
#import "VeloxNotificationController.h"

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

static NSString *const kTweakPreferencePath = @"/User/Library/Preferences/com.phillipt.veloxlite.plist";

@interface SBFolder ()
@property (nonatomic, retain) NSString* displayName;
@end
@interface SBFolderIcon : NSObject
@property (nonatomic, retain) SBFolder* folder;
-(id)veloxIdentifier;
@end

SBBulletinViewController *bulletinViewController;

SBIconView *globalViewSender;

BOOL darkMode;
VLXActivationMethod activationMethod;

NSMutableArray *iconViews;
NSMutableArray *folders;

static BOOL enabled;

%group Main

// Hooks n' stuff
%hook SBIconView
- (void)layoutSubviews {
	if (![iconViews containsObject:self]) {
		[iconViews addObject:self];
	}

	//newsstand has no chill
	//web bookmark icons
	if (![self.icon isKindOfClass:[%c(SBNewsstandApplicationIcon) class]] && ![self.icon isKindOfClass:[%c(SBNewsstandItemIconView) class]] && ![self.icon isKindOfClass:[%c(SBWebApplicationIcon) class]]) {
		if ([self.icon isKindOfClass:[%c(SBApplicationIcon) class]]) {
			SBApplicationIcon *icon = self.icon;
			if ([icon respondsToSelector:@selector(application)]) {
				SBApplication *application = [icon application];
				if ([application respondsToSelector:@selector(bundleIdentifier)]) {
					NSString *bundleIdentifier = [application bundleIdentifier];
					if (bundleIdentifier) {
						[[VeloxNotificationController sharedController] registerLongHoldNotificationWithBundleIdentifier:bundleIdentifier];
					}
				}
			}
		}
	}
	%orig;
}
%end

%hook SBBulletinViewController
- (id)initWithNibName:(id)nib bundle:(id)bundle {
	id r = %orig;
	if (r && !bulletinViewController && ![self isKindOfClass:[%c(SBWidgetHandlingBulletinViewController) class]]) {
		bulletinViewController = r;
	}
	return r;
}
%end

%hook SBFolder
- (id)initWithMaxListCount:(NSUInteger)arg1 maxIconCountInLists:(NSUInteger)arg2 {
	id r = %orig;
	if (r && [self respondsToSelector:@selector(allIcons)] && !(self.class == [%c(SBRootFolderWithDock) class])) {
		[folders addObject:self];
	}
	return r;
}
%end

BOOL hasUnlockedOnce;
%hook SBLockScreenManager
-(void)unlockUIFromSource:(int)source withOptions:(id)options {
	%orig;

	if (!hasUnlockedOnce) {
		NSArray* appArray = [[%c(SBIconController) sharedInstance] allApplications];
		for (SBApplication* app in appArray) {
			[[VeloxNotificationController sharedController] registerLongHoldNotificationWithBundleIdentifier:[app bundleIdentifier]];
		}
	}
	hasUnlockedOnce = YES;

	//remove velox just in case
	[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
}

%end

%hook SBApplicationIcon
- (void)launchFromLocation:(int)location {
	%orig;

	[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
}
%end

%hook SBAppSwitcherController
- (void)switcherScroller:(id)scroller1 itemTapped:(id)tapped {
	%orig;

	[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
}
- (void)launchAppWithIdentifier:(id)arg1 url:(id)arg2 actions:(id)arg3 {
	%orig;

	[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
}

%end

%hook SBUIController
- (BOOL)clickedMenuButton {
	BOOL r = %orig;
	if (r) {
		[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
	}
	return r;
}
- (BOOL)handleMenuDoubleTap {
	BOOL r = %orig;
	if (r) {
		[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
	}
	return r;
}
- (void)_deviceLockStateChanged:(NSInteger)changed {
	%orig;

	[[%c(VeloxNotificationController) sharedController] removeVeloxViewsFromView:nil];
}
%end

%end

static void loadPreferencesForStartup() {
	DebugLog(@"loadPreferencesForStartup()");

	NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kTweakPreferencePath];

	NSNumber *darkModeKey = tweakSettings[@"darkMode"];
	darkMode = darkModeKey ? [darkModeKey boolValue] : YES;

	NSNumber *activationMethodKey = tweakSettings[@"activationMethod"];
	activationMethod = activationMethodKey ? [activationMethodKey intValue] : VLXActivationMethodSwipeUp;

	enabled = tweakSettings[@"enabled"] ? [tweakSettings[@"enabled"] boolValue] : YES;
}

static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	DebugLog(@"loadPreferences()");
	
	loadPreferencesForStartup();

	//TODO: find a way to only trigger this code if activationMethod was changed
	//if this code isn't expensive, don't bother
	NSArray* appArray = [[%c(SBIconController) sharedInstance] allApplications];
	for (SBApplication* app in appArray) {
		[[VeloxNotificationController sharedController] registerLongHoldNotificationWithBundleIdentifier:[app bundleIdentifier]];
	}

}

%ctor {
	iconViews = [NSMutableArray new];
	folders = [NSMutableArray new];

	loadPreferencesForStartup();

	if (!enabled) return;

	%init(Main);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), 
									NULL, 
									loadPreferences, 
									CFSTR("com.phillipt.velox/preferencesChanged"), 
									NULL, 
									CFNotificationSuspensionBehaviorCoalesce);

	//for iOS 7 support
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
		//dlopen("/System/Library/Frameworks/WebKit.framework", RTLD_NOW);
		[[NSBundle bundleWithPath:@"/System/Library/Frameworks/WebKit.framework"] load];
	}
}
