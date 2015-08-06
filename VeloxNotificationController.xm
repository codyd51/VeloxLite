//  
//  
//  $$\    $$\           $$\                           $$\       $$\   $$\               
//  $$ |   $$ |          $$ |                          $$ |      \__|  $$ |              
//  $$ |   $$ | $$$$$$\  $$ | $$$$$$\  $$\   $$\       $$ |      $$\ $$$$$$\    $$$$$$\  
//  \$$\  $$  |$$  __$$\ $$ |$$  __$$\ \$$\ $$  |      $$ |      $$ |\_$$  _|  $$  __$$\ 
//   \$$\$$  / $$$$$$$$ |$$ |$$ /  $$ | \$$$$  /       $$ |      $$ |  $$ |    $$$$$$$$ |
//    \$$$  /  $$   ____|$$ |$$ |  $$ | $$  $$<        $$ |      $$ |  $$ |$$\ $$   ____|
//     \$  /   \$$$$$$$\ $$ |\$$$$$$  |$$  /\$$\       $$$$$$$$\ $$ |  \$$$$  |\$$$$$$$\ 
//      \_/     \_______|\__| \______/ \__/  \__|      \________|\__|   \____/  \_______|
//                                                                                       
//        
//  Created by Phillip Tennen on 6/20/15
//  All rights reserved
//
//                                                                             


#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "Velox_Internal.h"
#import "VeloxProtocol.h"
#import "VeloxNotificationController.h"
#import "UIImage+AverageColor.h"
#import "UIImage+Color.h"

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

//Animation durations
#define kVLXAnimationDurationKeyboardShowHide 			0.5
#define kVLXAnimationDurationPasscodeUnlock 			0.5
#define kVLXAnimationDurationPasscodePresent 			0.5
#define kVLXAnimationDurationPasscodeDismiss 			0.25
#define kVLXAnimationDurationArrowBlurFadeIn 			0.275
#define kVLXAnimationDurationFakeIconViewDelay 			0.2
#define kVLXAnimationDurationFakeIconViewFade 			0.25
#define kVLXAnimationDurationMainAnimation 				0.325
#define kVLXAnimationDurationExpandView 				0.25
#define kVLXAnimationDurationIconsShift 				0.375
#define kVLXAnimationDurationArrowFadeOut 				0.275
#define kVLXAnimationDurationVeloxViewFadeOut 			0.425
#define kVLXAnimationDurationFakeIconViewFadeOutDelay 	0.2
#define kVLXAnimationDurationFakeIconViewFadeOut 	  	0.25
#define kVLXAnimationDurationClosePhaseOne 			  	0.3
#define kVLXAnimationDurationClosePhaseTwo 			  	0.375
#define kVLXAnimationDurationIconListViewLayout 	  	0.375

ArrowViewPosition arrowPosition = ArrowViewPositionTop;

int checkIconOriginY;

UIView *arrowView;
CGRect oldVeloxFrame;
CGRect oldArrowFrame;
CGRect newVeloxFrame;
CGRect intermediateVeloxFrame;
CGRect intermediateArrowFrame;

int verticalOffset;
CGFloat originToStartFrom;

SBIconView* iconView;

%ctor {
	verticalOffset = (SCREEN_HEIGHT/7);
	originToStartFrom = 0;
}

BOOL iconExistsInFolder;

static SBIconListView *IDWListViewForIcon(SBIcon *icon) {
	SBIconController *controller = [%c(SBIconController) sharedInstance];
	SBRootFolder *rootFolder = [controller valueForKeyPath:@"rootFolder"];
	NSIndexPath *indexPath = [rootFolder indexPathForIcon:icon];
	SBIconListView *listView = nil;
	[controller getListView:&listView folder:NULL relativePath:NULL forIndexPath:indexPath createIfNecessary:YES];
	return listView;
}

@implementation VeloxNotificationController
+ (id)sharedController {
	static dispatch_once_t p = 0;
	__strong static id _sharedObject = nil;
	 
	dispatch_once(&p, ^{
		_sharedObject = [self new];
	});
	 
	return _sharedObject;
}
- (id)init {
	if (self = [super init]) {
		self.iconsToMoveUp = [NSMutableArray new];
	}
	return self;
}
- (void)showGenericNotificationViewForBundleIdentifier:(NSString*)bundleIdentifier {
	self.dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
	self.dismissButton.frame = [[UIApplication sharedApplication] keyWindow].frame;
	[self.dismissButton addTarget:self action:@selector(removeVeloxViewsFromView:) forControlEvents:UIControlEventTouchUpInside]; 

	SBIconController *controller = [%c(SBIconController) sharedInstance];
	SBApplicationIcon *iconForOpeningApp = [controller.model expectedIconForDisplayIdentifier:bundleIdentifier];

	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
	SBIconView *appToOpen = [iconMap mappedIconViewForIcon:iconForOpeningApp];

	//add 20 to origin for the arrow view
	CGRect genericViewFrame = CGRectMake(0, originToStartFrom, SCREEN_WIDTH, (SCREEN_HEIGHT/3.5)-20);
	self.genericView = [[VeloxGenericNotificationView alloc] initWithFrame:genericViewFrame bundleIdentifier:bundleIdentifier];

	CGRect keyFrame = [[UIApplication sharedApplication] keyWindow].frame;

	arrowView = [[UIView alloc] initWithFrame:keyFrame];
	if (!darkMode) {
		//light mode
		UIImage *arrowImage = [UIImage imageWithColor:[UIColor whiteColor] andFrame:CGRectMake(0, 0, arrowView.frame.size.width, arrowView.frame.size.height)];
		UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
		[arrowView addSubview:[arrowImageView autorelease]];
	}
	else {
		//dark mode
		_UIBackdropView *blurView = [[_UIBackdropView alloc] initWithFrame:arrowView.frame autosizesToFitSuperview:YES settings:self.genericView.folderBlurBackSettings];
		[blurView setBlurQuality:@"default"];
		arrowView.alpha = 0.7;
		[arrowView addSubview:[blurView autorelease]];
	}

	#warning "Fix this autorelease."
	[[[UIApplication sharedApplication] keyWindow] addSubview:arrowView];

	CAShapeLayer *backShapeLayer = [CAShapeLayer new];
	[backShapeLayer setFrame:arrowView.frame];
	UIBezierPath *backBezierPath = [UIBezierPath bezierPath];

	if (![globalViewSender isInDock] && !iconExistsInFolder) {
		if (arrowPosition == ArrowViewPositionTop) {
			[backBezierPath moveToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)-12.5, self.genericView.frame.origin.y)];
			[backBezierPath addLineToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2), self.genericView.frame.origin.y-20)];
			[backBezierPath addLineToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)+12.5, self.genericView.frame.origin.y)];
			[backBezierPath closePath];
			[backShapeLayer setPath:backBezierPath.CGPath];
		}
		else {
			[backBezierPath moveToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)-12.5, self.genericView.frame.origin.y+self.genericView.frame.size.height)];
			[backBezierPath addLineToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2), self.genericView.frame.origin.y+self.genericView.frame.size.height+20)];
			[backBezierPath addLineToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)+12.5, self.genericView.frame.origin.y+self.genericView.frame.size.height)];
			[backBezierPath closePath];
			[backShapeLayer setPath:backBezierPath.CGPath];
		}
	}
	else if (iconExistsInFolder) {
		CGRect convertedFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:globalViewSender.frame fromView:[globalViewSender superview]];
		[backBezierPath moveToPoint:CGPointMake(convertedFrame.origin.x+(convertedFrame.size.width/2)-12.5, self.genericView.frame.origin.y)];
		[backBezierPath addLineToPoint:CGPointMake(convertedFrame.origin.x+(convertedFrame.size.width/2), self.genericView.frame.origin.y-20)];
		[backBezierPath addLineToPoint:CGPointMake(convertedFrame.origin.x+(convertedFrame.size.width/2)+12.5, self.genericView.frame.origin.y)];
		[backBezierPath closePath];
		[backShapeLayer setPath:backBezierPath.CGPath];
	}
	else {
		[backBezierPath moveToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)-2.5, self.genericView.frame.origin.y+self.genericView.frame.size.height)];
		[backBezierPath addLineToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)+7.5, self.genericView.frame.origin.y+self.genericView.frame.size.height+20)];
		[backBezierPath addLineToPoint:CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2)+17.5, self.genericView.frame.origin.y+self.genericView.frame.size.height)];
		[backBezierPath closePath];
		[backShapeLayer setPath:backBezierPath.CGPath];
	}
	arrowView.layer.mask = backShapeLayer;
	[backShapeLayer release];

	arrowView.tag = 1334;

	SBApplication* app;
	//iOS 8 
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
		app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
	}
	else {
		app = [[[%c(SBApplicationController) sharedInstance] applicationsWithBundleIdentifier:bundleIdentifier] objectAtIndex:0];
	}
	if (!app) return;

	SBApplicationIcon* appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:app];
	iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];
	[appIcon release];
	iconView.delegate = [%c(SBIconController) sharedInstance];
	if (![globalViewSender isInDock] && !iconExistsInFolder) {
		iconView.center = CGPointMake(globalViewSender.center.x, globalViewSender.center.y+(globalViewSender.frame.size.height/4));
	}
	else if (iconExistsInFolder) {
		CGRect viewSenderFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:globalViewSender.frame fromView:[globalViewSender superview]];
		iconView.center = CGPointMake(viewSenderFrame.origin.x+(viewSenderFrame.size.width/2), viewSenderFrame.origin.y+(viewSenderFrame.size.height/2)-8);
	}
	else {
		CGRect viewSenderFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:globalViewSender.frame fromView:[globalViewSender superview]];
		iconView.center = CGPointMake(viewSenderFrame.origin.x+(viewSenderFrame.size.width/2), viewSenderFrame.origin.y+(viewSenderFrame.size.height/2)-8);
	}
	iconView.iconLabelAlpha = 0.0;
	iconView.tag = 1333;

	[[[UIApplication sharedApplication] keyWindow] addSubview:[iconView autorelease]];
	[[[UIApplication sharedApplication] keyWindow] addSubview:self.dismissButton];
	#warning "Fix this with an autorelease."
	if ([globalViewSender isInDock])
		[[[UIApplication sharedApplication] keyWindow] insertSubview:self.genericView belowSubview:[globalViewSender superview]];
	else
		[[[UIApplication sharedApplication] keyWindow] addSubview:self.genericView];
	
}
- (void)registerLongHoldNotificationWithBundleIdentifier:(NSString *)bundleIdentifier {
	SBIconController *controller = [%c(SBIconController) sharedInstance];
	SBIcon* icon = [controller.model expectedIconForDisplayIdentifier:bundleIdentifier];
	SBIconView* iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];

	UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleIconHeldFromSender:)];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIconHeldFromSender:)];
	UILongPressGestureRecognizer *holdRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleIconHeldFromSender:)];

	switch (activationMethod) {
		case VLXActivationMethodSwipeUp:
			swipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
			[iconView addGestureRecognizer:swipeRecognizer];
			break;
		case VLXActivationMethodSwipeDown:
			swipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
			[iconView addGestureRecognizer:swipeRecognizer];
			break;
		case VLXActivationMethodDoubleTap:
			tapRecognizer.numberOfTapsRequired = 2;
			[iconView addGestureRecognizer:tapRecognizer];
			break;
		case VLXActivationMethodTripleTap:
			tapRecognizer.numberOfTapsRequired = 3;
			[iconView addGestureRecognizer:tapRecognizer];
			break;
		case VLXActivationMethodHold:
			holdRecognizer.numberOfTouchesRequired = 1;
			holdRecognizer.numberOfTapsRequired = 1;
			[iconView addGestureRecognizer:holdRecognizer];
			break;
		default:
			[[[[UIAlertView alloc] initWithTitle:@"Velox" message:@"Something has gone wrong! Please adjust your Activation method in Velox Settings." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
			break;
	}
	[swipeRecognizer release];
	[tapRecognizer release];
	[holdRecognizer release];
}
- (void)showVeloxForBundleIdentifier:(NSString*)identifier {
	//get the icon view from the bundle identifier
	SBIconController *controller = [%c(SBIconController) sharedInstance];
	SBApplicationIcon *icon = [controller.model expectedIconForDisplayIdentifier:identifier];
	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
	SBIconView *viewSender = [iconMap mappedIconViewForIcon:icon];

	globalViewSender = viewSender;

	[self.iconsToMoveUp removeAllObjects];

	iconExistsInFolder = NO;
	for (SBFolder *folder in folders) {
		for (SBIcon *icon in [folder allIcons]) {
			//Folder contains this icon
			if (icon == viewSender.icon) {
				iconExistsInFolder = YES;
				break;
			}
		}
	}

	if (!iconExistsInFolder && ![globalViewSender isInDock]) {
		//add 20 for the arrow view
		originToStartFrom = viewSender.frame.origin.y + 20;
	}
	else if (iconExistsInFolder) {
		CGRect viewSenderFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:viewSender.frame fromView:[viewSender superview]];
		originToStartFrom = viewSenderFrame.origin.y;
	}

	//NOTE: as the originToStartFrom for the dock requires the height of the invoked view, which doesnt exist at this point, the code for the dock has been moved elsewhere. (where?)
	//performOpeningAnimation maybe?
	//NOTE: stratos support also requires this, it has been moved elsewhere as well

	//show generic app notification view

	self.genericView.verticalOffset = 300;
	if (![viewSender isInDock]) {
		checkIconOriginY = viewSender.frame.origin.y;

		arrowPosition = ArrowViewPositionTop;
	}
	else if ([viewSender isInDock]) {
		CGRect viewSenderFrame = [[viewSender superview] convertRect:viewSender.frame toView:[[UIApplication sharedApplication] keyWindow]];
		checkIconOriginY = viewSenderFrame.origin.y;

		arrowPosition = ArrowViewPositionBottom;

		//height of generic view (right?)
		CGFloat	viewHeight = SCREEN_HEIGHT/3.5;
		//subtract 20 for the arrow view (we are going up)
		originToStartFrom = viewSenderFrame.origin.y - viewHeight - 20;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[self showGenericNotificationViewForBundleIdentifier:identifier];
		[self performOpeningAnimation];
	});
}
- (void)handleIconHeldFromSender:(UIGestureRecognizer *)sender {
	if ([[%c(SBIconController) sharedInstance] isEditing]) return;
	//juuust to be sure, experiencing bugs in -showSpecialized
	self.isLightMode = !darkMode;

	SBIconView *viewSender = (SBIconView *)sender.view;
	SBApplication *application = [viewSender.icon application];
	NSString *bundleIdentifier = [application bundleIdentifier];

	[self showVeloxForBundleIdentifier:bundleIdentifier];
}
-(void)performOpeningAnimation {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];

	UIView* handledView = self.genericView;

	//add in half of the size to make it look nicer
	//we add in half the width instead of the height because the height also includes the label

	//how far to move icons above the view up
	CGFloat displacementUpValue;
	if (![globalViewSender isInDock] && !iconExistsInFolder) 
		displacementUpValue = (globalViewSender.frame.origin.y + globalViewSender.frame.size.height + (globalViewSender.frame.size.width/2)) - handledView.frame.origin.y;
	else if (iconExistsInFolder) {
		CGRect adjustedFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:globalViewSender.frame fromView:[globalViewSender superview]];

		displacementUpValue = (adjustedFrame.origin.y + adjustedFrame.size.height + (adjustedFrame.size.width/2)) - handledView.frame.origin.y;
	}
	else {
		displacementUpValue = handledView.frame.size.height;
	}

	//add 20 for the arrow view
	if (!iconExistsInFolder) displacementUpValue += 20;

	//how far to move icons below the view down
	CGFloat displacementDownValue;
	if (![globalViewSender isInDock] && !iconExistsInFolder)
		displacementDownValue = (handledView.frame.origin.y + handledView.frame.size.height) - (globalViewSender.frame.origin.y + globalViewSender.frame.size.height + (globalViewSender.frame.size.width/2));
	else {
		CGRect adjustedFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:globalViewSender.frame fromView:[globalViewSender superview]];
		displacementDownValue = (handledView.frame.origin.y + handledView.frame.size.height) - (adjustedFrame.origin.y + adjustedFrame.size.height + (adjustedFrame.size.width/2));
	}
	//add 20 for the arrow view
	displacementDownValue += 20;

	handledView.alpha = 0.0;

	self.genericView.fullBackBlur.alpha = 0.0;
	self.genericView.whitenUpBackBlurImageView.alpha = 0.0;

	arrowView.alpha = 0.0;

	//NOTE: we subtract 5 because the designer wanted the view to be closer to the icon
	int extraDisplacement;
	if (![globalViewSender isInDock]) extraDisplacement = 5;
	else extraDisplacement = -5;
	oldVeloxFrame = CGRectMake(handledView.frame.origin.x, handledView.frame.origin.y - extraDisplacement, handledView.frame.size.width, handledView.frame.size.height);
	oldArrowFrame = CGRectMake(arrowView.frame.origin.x, arrowView.frame.origin.y - extraDisplacement, arrowView.frame.size.width, arrowView.frame.size.height);

	//10 is half the arrow view frame
	newVeloxFrame = CGRectMake(0, handledView.frame.origin.y+handledView.frame.size.height/2 + 10, SCREEN_WIDTH, SCREEN_HEIGHT/20);

	if (![globalViewSender isInDock]) {
		CGFloat difference = newVeloxFrame.origin.y - oldVeloxFrame.origin.y;
		intermediateArrowFrame = CGRectMake(oldArrowFrame.origin.x, oldArrowFrame.origin.y + difference, oldArrowFrame.size.width, oldArrowFrame.size.height);
	}
	else {
		intermediateArrowFrame = CGRectMake(oldArrowFrame.origin.x, oldArrowFrame.origin.y-newVeloxFrame.size.height, oldArrowFrame.size.width, oldArrowFrame.size.height);
	}

	handledView.frame = newVeloxFrame;
	arrowView.frame = intermediateArrowFrame;

	//we want the icon to fade in later in the animation so it isn't perceptible
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kVLXAnimationDurationFakeIconViewDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:kVLXAnimationDurationFakeIconViewFade animations:^{
			iconView.alpha = 1.0;
		}];
	});

	[UIView animateWithDuration:kVLXAnimationDurationMainAnimation animations:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.genericView updateForFrameChange];
		});	

		//subtract 20 for the arrow view
		if (![globalViewSender isInDock]) iconView.frame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y - displacementUpValue, iconView.frame.size.width, iconView.frame.size.height);

		handledView.alpha = 1.0;
		arrowView.alpha = 1.0;

		//thanks uroboro!
		//this doesnt work if the globalViewSender is in a folder, so fall back on the less efficient code
		NSMutableArray* affectedIcons = [[NSMutableArray alloc] init];
		if (iconExistsInFolder) {
			[affectedIcons addObjectsFromArray:[[[%c(SBIconController) sharedInstance] currentFolderIconList] visibleIcons]];
		}
		else {
			[affectedIcons addObjectsFromArray:[[[%c(SBIconController) sharedInstance] currentRootIconList] visibleIcons]];
		}

		for (SBIcon *icon in affectedIcons) {
			SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
			SBIconView *iconView = [iconMap mappedIconViewForIcon:icon];

			int pendingIconY = iconView.frame.origin.y;

			if (iconView != globalViewSender) {
				iconView.alpha = 0.50;
			}

			if (![iconView isInDock]) {
				if (pendingIconY <= checkIconOriginY) {
					//icon is higher than origin
					if (!iconExistsInFolder) {
						CGRect newFrame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y - displacementUpValue, iconView.frame.size.width, iconView.frame.size.height);
						iconView.frame = newFrame;
					}
					else {
						CGRect adjustedFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:iconView.frame fromView:[iconView superview]];
						CGRect newFrame = CGRectMake(adjustedFrame.origin.x, adjustedFrame.origin.y - displacementUpValue, adjustedFrame.size.width, adjustedFrame.size.height);
						CGRect convertedFrame = [[iconView superview] convertRect:newFrame fromView:[[UIApplication sharedApplication] keyWindow]];
						iconView.frame = convertedFrame;
					}
				}
				else {
					//icon is lower than origin
					if (!iconExistsInFolder) {
						CGRect newFrame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y + displacementDownValue, iconView.frame.size.width, iconView.frame.size.height);
						iconView.frame = newFrame;
					}
					else {
						CGRect adjustedFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:iconView.frame fromView:[iconView superview]];
						CGRect newFrame = CGRectMake(adjustedFrame.origin.x, adjustedFrame.origin.y + displacementDownValue, adjustedFrame.size.width, adjustedFrame.size.height);
						CGRect convertedFrame = [[iconView superview] convertRect:newFrame fromView:[[UIApplication sharedApplication] keyWindow]];
						iconView.frame = convertedFrame;
					}
				}
			}
		}

		intermediateVeloxFrame = CGRectMake(0, oldVeloxFrame.origin.y, newVeloxFrame.size.width, newVeloxFrame.size.height);

		CGRect newOpeningVeloxFrame = CGRectMake(0, oldVeloxFrame.origin.y, oldVeloxFrame.size.width, oldVeloxFrame.size.height);
		handledView.frame = newOpeningVeloxFrame;
		arrowView.frame = oldArrowFrame;

#if !defined BLURTEST
		self.genericView.fullBackBlur.alpha = 1.0;
#endif

	} completion:^(BOOL finished){
		[UIView animateWithDuration:kVLXAnimationDurationExpandView animations:^{
			handledView.frame = oldVeloxFrame;
		} completion:^(BOOL finished){
			if (finished) {
				//check if it went off screen
				CGRect globalViewSenderFrame;
				//basically, 0 on the main window is below the status bar, so we subtract 15 to take that into account
				//for other windows, we dont need that
				NSInteger threshold;
				if (![globalViewSender isInDock] && !iconExistsInFolder) {
					globalViewSenderFrame = globalViewSender.frame;
					threshold = -15;
				}
				else {
					globalViewSenderFrame = [[globalViewSender superview] convertRect:globalViewSender.frame toView:[[UIApplication sharedApplication] keyWindow]];
					threshold = 0;
				}

				NSMutableArray* affectedIcons = [[NSMutableArray alloc] init];
				if (iconExistsInFolder) {
					[affectedIcons addObjectsFromArray:[[[%c(SBIconController) sharedInstance] currentFolderIconList] visibleIcons]];
				}
				else {
					[affectedIcons addObjectsFromArray:[[[%c(SBIconController) sharedInstance] currentRootIconList] visibleIcons]];
				}
				SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];

				if (globalViewSenderFrame.origin.y <= threshold) {
					//make the origin positive
					//add half the height to give some breathing room
					CGFloat displacementValue = handledView.frame.origin.y + globalViewSender.frame.size.height*1.5;

					[UIView animateWithDuration:kVLXAnimationDurationIconsShift animations:^{
						for (SBIcon* icon in affectedIcons) {
							SBIconView* currentIconView = [iconMap mappedIconViewForIcon:icon];
							currentIconView.frame = CGRectMake(currentIconView.frame.origin.x, currentIconView.frame.origin.y + displacementValue, currentIconView.frame.size.width, currentIconView.frame.size.height);
						}
						handledView.frame = CGRectMake(handledView.frame.origin.x, handledView.frame.origin.y + displacementValue, handledView.frame.size.width, handledView.frame.size.height);
						arrowView.frame = CGRectMake(arrowView.frame.origin.x, arrowView.frame.origin.y + displacementValue, arrowView.frame.size.width, arrowView.frame.size.height);
						if (![globalViewSender isInDock]) iconView.frame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y + displacementValue, iconView.frame.size.width, iconView.frame.size.height);
					}];
				}
				//that was for if it was too high
				//this is for if its too low
				else if (handledView.frame.origin.y+handledView.frame.size.height >= [[UIApplication sharedApplication] keyWindow].frame.size.height) {
					//add half the height to give some breathing room
					CGFloat displacementValue = ((handledView.frame.origin.y + handledView.frame.size.height) - [[UIApplication sharedApplication] keyWindow].frame.size.height) + globalViewSenderFrame.size.height/2;

					[UIView animateWithDuration:kVLXAnimationDurationIconsShift animations:^{
						for (SBIcon* icon in affectedIcons) {
							SBIconView* currentIconView = [iconMap mappedIconViewForIcon:icon];
							currentIconView.frame = CGRectMake(currentIconView.frame.origin.x, currentIconView.frame.origin.y - displacementValue, currentIconView.frame.size.width, currentIconView.frame.size.height);
						}
						handledView.frame = CGRectMake(handledView.frame.origin.x, handledView.frame.origin.y - displacementValue, handledView.frame.size.width, handledView.frame.size.height);
						arrowView.frame = CGRectMake(arrowView.frame.origin.x, arrowView.frame.origin.y - displacementValue, arrowView.frame.size.width, arrowView.frame.size.height);
						if (![globalViewSender isInDock]) iconView.frame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y - displacementValue, iconView.frame.size.width, iconView.frame.size.height);
					}];
				}
			}
		}];
	}];
}
- (BOOL)removeVeloxViewsFromView:(UIView *)view {
	//make sure this doesnt get called a million times
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

	UIView *viewToUse;
	if (view.class != [UIView class]) viewToUse = [[UIApplication sharedApplication] keyWindow];
	else viewToUse = view;

	[self.dismissButton removeFromSuperview];

	UIView* handledView = self.genericView;

	dispatch_async(dispatch_get_main_queue(), ^{
		[self performClosingAnimationOnView:viewToUse withHandledView:handledView];
	});

	return NO;
}
-(void)performClosingAnimationOnView:(UIView*)viewToUse withHandledView:(UIView*)handledView {
	[UIView animateWithDuration:kVLXAnimationDurationArrowFadeOut animations:^{
		arrowView.alpha = 0.0;
	}];
	[UIView animateWithDuration:kVLXAnimationDurationVeloxViewFadeOut animations:^{
		handledView.alpha = 0.0;
		arrowView.alpha = 0.0;
	}];

	//we want the icon to fade out later in the animation so it isn't perceptible
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kVLXAnimationDurationFakeIconViewDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:kVLXAnimationDurationFakeIconViewFadeOut animations:^{
			iconView.alpha = 0.0;
		}];
	});

	[UIView animateWithDuration:kVLXAnimationDurationClosePhaseOne animations:^{
		//Even though newVeloxFrame is the correct frame we need,
		//the animation takes too long
		//so it looks bad
		//So, we exagerate it
		CGFloat yOrigin = oldVeloxFrame.origin.y + globalViewSender.frame.size.height;
		handledView.frame = CGRectMake(oldVeloxFrame.origin.x, yOrigin, oldVeloxFrame.size.width, 0);

		//we add 5 because otherwise it fades into the icon view, which looks bad
		//5 stops this juuuust a little
		CGFloat arrowDifference = yOrigin - oldVeloxFrame.origin.y + 7.5;

		if (arrowPosition == ArrowViewPositionTop) {
			CGRect lowerArrowFrame = CGRectMake(intermediateArrowFrame.origin.x, arrowView.frame.origin.y + arrowDifference, intermediateArrowFrame.size.width, intermediateArrowFrame.size.height - handledView.frame.origin.y);
			arrowView.frame = lowerArrowFrame;
		}
		else {
			//add 12.5 to make it an even 20, the height of the arrow view
			//since we add 7.5 to arrowDifference
			//let's divide arrowDifference by 2
			//just to make the animation a little more clear
			//(currently the arrow flies really fast)
			CGRect lowerArrowFrame = CGRectMake(arrowView.frame.origin.x, arrowView.frame.origin.y - ((arrowDifference+ 12.5)/2), arrowView.frame.size.width, arrowView.frame.size.height);
			arrowView.frame = lowerArrowFrame;
		}

		handledView.alpha = 0.0;
		arrowView.alpha = 0.0;
	}];
	[UIView animateWithDuration:kVLXAnimationDurationClosePhaseTwo animations:^{
		for (SBIconView *iconView in iconViews) {
			iconView.alpha = 1.0;
		}

		self.genericView.fullBackBlur.alpha = 0.0;
		self.genericView.whitenUpBackBlurImageView.alpha = 0.0;

		if ([globalViewSender isInDock]) {
			CGRect currentArrowViewFrame = arrowView.frame;
			arrowView.frame = CGRectMake(currentArrowViewFrame.origin.x, currentArrowViewFrame.origin.y-oldVeloxFrame.size.height+intermediateVeloxFrame.size.height, currentArrowViewFrame.size.width, currentArrowViewFrame.size.height);
		}

		CGRect lowerVeloxFrame = CGRectMake(newVeloxFrame.origin.x, newVeloxFrame.origin.y, newVeloxFrame.size.width, 0);

		if (iconExistsInFolder || [globalViewSender isInDock]) {
			for (SBIconView* iconView in iconViews) {
				SBIconListView *listView = IDWListViewForIcon(iconView.icon);
				[listView setIconsNeedLayout];
				[listView layoutIconsIfNeeded:kVLXAnimationDurationIconListViewLayout domino:NO];
			}
		}
		else {
			SBIconListView *listView = IDWListViewForIcon(globalViewSender.icon);
			[listView setIconsNeedLayout];
			[listView layoutIconsIfNeeded:kVLXAnimationDurationIconListViewLayout domino:NO];
		}

		//set the fake icon view's frame to the real icon's
		if ([globalViewSender isInDock] || iconExistsInFolder) {
			CGRect adjustedFrame = [[[UIApplication sharedApplication] keyWindow] convertRect:globalViewSender.frame fromView:[globalViewSender superview]];
			iconView.frame = CGRectMake(adjustedFrame.origin.x, adjustedFrame.origin.y, adjustedFrame.origin.x+(adjustedFrame.size.width/2), adjustedFrame.origin.y+adjustedFrame.size.height-(adjustedFrame.size.height/3));
		}
		else iconView.center = CGPointMake(globalViewSender.frame.origin.x+(globalViewSender.frame.size.width/2), globalViewSender.frame.origin.y+globalViewSender.frame.size.height-(globalViewSender.frame.size.height/3));

	} completion:^(BOOL finished){
		//run this last!
		for (UIView *inView in [viewToUse subviews]) {
			if ([inView isKindOfClass:[VeloxGenericNotificationView class]]) {
				[inView removeFromSuperview];
				//return YES;
			}
			if ([inView isKindOfClass:[VeloxNotificationController class]]) {
				[inView removeFromSuperview];
				//return YES;
			}
			if (inView.tag == 1337) {
				[inView removeFromSuperview];
			}
			if (inView.tag == 1336) {
				[inView removeFromSuperview];
			}
			if (inView.tag == 1335) {
				[inView removeFromSuperview];
			}
			if (inView.tag == 1334) {
				[inView removeFromSuperview];
			}
			if (inView.tag == 1333) {
				[inView removeFromSuperview];
			}
			[iconView removeFromSuperview];

			iconView = nil;
		}
	}];
}

CGFloat realKeyboardDisplacement;
-(void)keyboardWillShowOrHide:(NSNotification*)n {
	NSDictionary* userInfo = [n userInfo];

	UIView* handledView = self.genericView;

	CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

	CGFloat displacementValue = (handledView.frame.origin.y+handledView.frame.size.height) - keyboardFrame.origin.y;

	NSMutableArray* affectedIcons = [[NSMutableArray alloc] init];
	if (iconExistsInFolder) {
		[affectedIcons addObjectsFromArray:[[[%c(SBIconController) sharedInstance] currentFolderIconList] visibleIcons]];
	}
	else {
		[affectedIcons addObjectsFromArray:[[[%c(SBIconController) sharedInstance] currentRootIconList] visibleIcons]];
	}
	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];

	//move up if keyboard is showing, move down if keyboard is hiding
	if ([n.name isEqualToString:@"UIKeyboardWillShowNotification"]) {
		//only move if they need to be displaced
		if (displacementValue > 0) {
			realKeyboardDisplacement = displacementValue;
			[UIView animateWithDuration:kVLXAnimationDurationKeyboardShowHide animations:^{
				for (SBIcon* icon in affectedIcons) {
					SBIconView* currentIconView = [iconMap mappedIconViewForIcon:icon];
					currentIconView.frame = CGRectMake(currentIconView.frame.origin.x, currentIconView.frame.origin.y - displacementValue, currentIconView.frame.size.width, currentIconView.frame.size.height);
				}
				handledView.frame = CGRectMake(handledView.frame.origin.x, handledView.frame.origin.y - displacementValue, handledView.frame.size.width, handledView.frame.size.height);
				arrowView.frame = CGRectMake(arrowView.frame.origin.x, arrowView.frame.origin.y - displacementValue, arrowView.frame.size.width, arrowView.frame.size.height);
				if (![globalViewSender isInDock]) iconView.frame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y - displacementValue, iconView.frame.size.width, iconView.frame.size.height);
			}];
		}
	}
	else {
		//we use realKeyboardDisplacement because the displacementValue is different when the keyboard is showing/hiding (?!???)
		//so, we use the value from when it was showing
		//to ensure we move the same amount

		//only move if they need to be displaced
		if (realKeyboardDisplacement > 0 && displacementValue < 0) {
			[UIView animateWithDuration:kVLXAnimationDurationKeyboardShowHide animations:^{
				for (SBIcon* icon in affectedIcons) {
					SBIconView* currentIconView = [iconMap mappedIconViewForIcon:icon];
					currentIconView.frame = CGRectMake(currentIconView.frame.origin.x, currentIconView.frame.origin.y + realKeyboardDisplacement, currentIconView.frame.size.width, currentIconView.frame.size.height);
				}
				handledView.frame = CGRectMake(handledView.frame.origin.x, handledView.frame.origin.y + realKeyboardDisplacement, handledView.frame.size.width, handledView.frame.size.height);
				arrowView.frame = CGRectMake(arrowView.frame.origin.x, arrowView.frame.origin.y + realKeyboardDisplacement, arrowView.frame.size.width, arrowView.frame.size.height);
				if (![globalViewSender isInDock]) iconView.frame = CGRectMake(iconView.frame.origin.x, iconView.frame.origin.y + realKeyboardDisplacement, iconView.frame.size.width, iconView.frame.size.height);
			}];
		}
	}
}

-(void)dismissVelox {
	[self removeVeloxViewsFromView:nil];
}

#pragma mark - Helpers

- (NSArray *)bulletinsForBundleIdentifier:(NSString *)bundleIdentifier {
	NSArray *bulletins = nil;
	if (kCFCoreFoundationVersionNumber <= 800) {
		SBBulletinListSection *listSection = nil;
		for (int i = 0; (listSection = [[%c(SBBulletinListController) sharedInstanceIfExists] _sectionAtIndex:i]); i++) {
			if ([listSection.sectionID isEqualToString:bundleIdentifier]) {
				break;
			}
		}
		if (!listSection) {
			return bulletins;
		}
		bulletins = [NSMutableArray new];
		for (int i = 0; i < [listSection bulletinCount]; i++) {
			[(NSMutableArray *)bulletins addObject:[listSection bulletinAtIndex:i]];
		}
	}
	else {
		int index = 0;
		SBNotificationCenterSectionInfo *sectionInfo = nil;
		SBBulletinListSection *listSection = nil;

		while (!listSection) {
			sectionInfo = [bulletinViewController sectionAtIndex:index];
			if ([sectionInfo.representedListSection.sectionID isEqualToString:bundleIdentifier]) {
				//found the app we need
				listSection = sectionInfo.representedListSection;
				bulletins = listSection.bulletins;
				break;
			}

			index++;
			if (sectionInfo == nil) {
				bulletins = nil;
				break;
			}
		}
	}
	return bulletins;
}

@end