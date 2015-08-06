#import "Velox_Internal.h"
#import "VeloxNotificationController.h"
#import "VeloxGenericNotificationView.h"
#import "UIImage+AverageColor.h"
#import "UIImage+Color.h"

#include <substrate.h>

@implementation VeloxGenericNotificationView
- (id)initWithFrame:(CGRect)frame bundleIdentifier:(NSString *)bundleIdentifier {
	//adjust frame for arrow
	self = [super initWithFrame:frame];

	if (self) {
		self.bundleIdentifier = bundleIdentifier;

		self.clipsToBounds = YES;

		self.arrowOffset = SCREEN_HEIGHT * 0.02248875562;

		SBIconImageView *iconImageView = MSHookIvar<SBIconImageView*>(globalViewSender, "_iconImageView");

		UIGraphicsBeginImageContextWithOptions(iconImageView.bounds.size, iconImageView.opaque, 0.0);
    	[iconImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    	UIGraphicsEndImageContext();

		self.folderBlurBackSettings = [_UIBackdropViewSettings settingsForPrivateStyle:1];

		self.folderBlurBack = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)] autorelease];
		_UIBackdropView *darkModeBlurView;

		if (!darkMode) {
			//light mode
			UIImage *backgroundColorImage = [UIImage imageWithColor:[UIColor whiteColor] andFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
			UIImageView *backgroundColorImageView = [[UIImageView alloc] initWithImage:backgroundColorImage];
			[self.folderBlurBack addSubview:[backgroundColorImageView autorelease]];
		}
		else {
			//dark mode
			darkModeBlurView = [[_UIBackdropView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height-20) autosizesToFitSuperview:YES settings:self.folderBlurBackSettings];
			[darkModeBlurView setBlurQuality:@"default"];
			[self.folderBlurBack addSubview:[darkModeBlurView autorelease]];
		}

		self.folderBlurArrowBackground = [[_UIBackdropView alloc] initWithFrame:CGRectMake(0, self.folderBlurBack.frame.size.height, self.frame.size.width, self.arrowOffset) autosizesToFitSuperview:YES settings:self.folderBlurBackSettings];
		[self.folderBlurArrowBackground setBlurQuality:@"default"];
		self.folderBlurArrowView = [[[UIView alloc] initWithFrame:CGRectMake(0, self.folderBlurBack.frame.size.height, self.frame.size.width, self.arrowOffset)] autorelease];

		self.folderBlurBack.tag = 1337;
		self.folderBlurArrowBackground.tag = 1334;

		self.fullBackBlurSettings = [_UIBackdropViewSettings settingsForPrivateStyle:2];
		self.fullBackBlur = [[[_UIBackdropView alloc] initWithFrame:frame autosizesToFitSuperview:YES settings:self.fullBackBlurSettings] autorelease];
		[self.fullBackBlur setBlurQuality:@"default"];

		self.fullBackBlur.tag = 1335;

		self.whitenUpBackBlurImage = [UIImage imageWithColor:[UIColor whiteColor] andFrame:[[UIApplication sharedApplication] keyWindow].frame];
		self.whitenUpBackBlurImageView = [[[UIImageView alloc] initWithImage:self.whitenUpBackBlurImage] autorelease];
		self.whitenUpBackBlurImageView.tag = 1337;
	}
	return self;
}

- (void)updateForFrameChange {
	self.fullBackBlur.alpha = 0.0;

	[[self superview] insertSubview:self.fullBackBlur belowSubview:arrowView];
	if (!darkMode) {
		//light mode
		[[[UIApplication sharedApplication] keyWindow] insertSubview:self.whitenUpBackBlurImageView atIndex:0];
	}

	int index = 0;
	SBNotificationCenterSectionInfo *sectionInfo = nil;
	SBBulletinListSection *listSection = nil;

	while (!listSection) {
		sectionInfo = [bulletinViewController sectionAtIndex:index];
		if ([sectionInfo.representedListSection.sectionID isEqualToString:self.bundleIdentifier]) {
			//found the app we need
			listSection = sectionInfo.representedListSection;
			self.bulletins = listSection.bulletins;

			CGFloat notificationHeight = self.frame.size.height/2;

			UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
			scrollView.showsHorizontalScrollIndicator = NO;
			scrollView.showsVerticalScrollIndicator = YES;
			scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, notificationHeight*3*self.bulletins.count);

			self.notificationTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, self.frame.size.height) style:UITableViewStyleGrouped];
			self.notificationTable.backgroundView = self.folderBlurBack;
			self.notificationTable.rowHeight = notificationHeight;
			self.notificationTable.scrollEnabled = YES;
			self.notificationTable.showsVerticalScrollIndicator = YES;
			self.notificationTable.userInteractionEnabled = YES;
			self.notificationTable.bounces = YES;
			self.notificationTable.delegate = self;
			self.notificationTable.dataSource = self;

			[self.notificationTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"notificationCell"];
			[self addSubview:[self.notificationTable autorelease]];

			break;
		}

		index++;
		if (sectionInfo == nil) {
			//Display no notifications view
			UILabel *noNotificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH*0.8, self.frame.size.height)];
			noNotificationsLabel.center = CGPointMake(SCREEN_WIDTH/2, self.frame.size.height/2);
			noNotificationsLabel.text = @"No new notifications";
			noNotificationsLabel.textColor = [UIColor whiteColor];
			noNotificationsLabel.font = [UIFont systemFontOfSize:36];
			noNotificationsLabel.enabled = NO;
			noNotificationsLabel.numberOfLines = 1;
			noNotificationsLabel.adjustsFontSizeToFitWidth = YES;
			noNotificationsLabel.alpha = 0.8;
			[self addSubview:[noNotificationsLabel autorelease]];

			break;
		}
	}
#if !defined BLURTEST
	[UIView animateWithDuration:0.5 animations:^{
		self.fullBackBlur.alpha = 1.0;
		self.whitenUpBackBlurImageView.alpha = 0.3;
	}];
#endif
	
}
- (void)layoutSubviews {
	BOOL shouldAddView = YES;
	for (UIView *view in [[[UIApplication sharedApplication] keyWindow] subviews]) {
		if (view.tag == 1337 || [view isKindOfClass:[_UIBackdropView class]]) shouldAddView = NO;
	}
	if (shouldAddView) {
		CGRect r2 = CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.frame.size.height);

		self.folderBlurArrowView.frame = CGRectMake(0, self.folderBlurBack.frame.size.height, self.frame.size.width, self.arrowOffset);
		[[self superview] addSubview:self.folderBlurArrowView];

		[self.fullBackBlur removeFromSuperview];

		[self addSubview:self.folderBlurBack];

		UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.folderBlurBack.frame.origin.x, self.folderBlurBack.frame.origin.y)];
		backView.backgroundColor = [UIColor blackColor];
		[[[UIApplication sharedApplication] keyWindow] addSubview:[backView autorelease]];
	}
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString *cellIdentifier = @"notificationCell";

	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];

	cell.backgroundView = [[UIView new] autorelease];
	cell.backgroundColor = [UIColor clearColor];

	BBulletin *bulletin = [self.bulletins objectAtIndex:indexPath.row];

	cell.textLabel.text = bulletin.title;
	cell.textLabel.font = [UIFont systemFontOfSize:16];
	if (!darkMode) {
		//light mode
		cell.textLabel.textColor = [UIColor blackColor];
	}
	else {
		cell.textLabel.textColor = [UIColor whiteColor];
	}

	cell.detailTextLabel.text = [NSString stringWithFormat:@"    %@", bulletin.message];
	if (!darkMode) {
		//light mode
		cell.detailTextLabel.textColor = [UIColor colorWithRed:100/255.0f green:100/255.0f blue:100/255.0f alpha:1.0f];
	}
	else {
		//dark mode
		cell.detailTextLabel.textColor = [UIColor colorWithRed:200/255.0f green:200/255.0f blue:200/255.0f alpha:1.0f];
	}
	cell.detailTextLabel.alpha = 1.0;
	cell.detailTextLabel.font = [UIFont systemFontOfSize:14];

	NSDate *publishDate = bulletin.date;
	NSDate *currentDate = [NSDate date];
	NSTimeInterval diffTime = [currentDate timeIntervalSinceDate:publishDate];

	int diff = (int)diffTime;

	NSUInteger h = diff / 3600;
	NSUInteger m = (diff / 60) % 60;
	NSUInteger s = diff % 60;
	NSString *formattedTime;

	//check if its over one day
	if (h > 24.0) {
		if (h >= 48.0) {
			formattedTime = [NSString stringWithFormat:@"%i days ago", (int)h/24];
		}
		else {
			formattedTime = [NSString stringWithFormat:@"%i day ago", (int)h/24];
		}
	}
	//check if its over one hour
	else if (h > 1.0) {
		formattedTime = [NSString stringWithFormat:@"%i hours ago", (int)h];
	}
	//check if its over one minute
	else if (m > 1.0) {
		formattedTime = [NSString stringWithFormat:@"%i minutes ago", int(m)];
	}
	//its in seconds
	else {
		formattedTime = [NSString stringWithFormat:@"%i seconds ago", (int)s];
	}

	UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, cell.frame.size.height/2)];
	timeLabel.center = CGPointMake(SCREEN_WIDTH*0.9, cell.frame.size.height/3);
	timeLabel.text = [NSString stringWithFormat:@"%@", formattedTime];
	if (!darkMode) {
		//light mode
		timeLabel.textColor = [UIColor colorWithRed:180/255.0f green:180/255.0f blue:180/255.0f alpha:1.0f];
	}
	else {
		//dark mode
		timeLabel.textColor = [UIColor grayColor];
	}
	timeLabel.font = [UIFont systemFontOfSize:12];
	timeLabel.numberOfLines = 1;
	timeLabel.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:[timeLabel autorelease]];

	return cell;
}
- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[[VeloxNotificationController sharedController] removeVeloxViewsFromView:nil];
	[[UIApplication sharedApplication] launchApplicationWithIdentifier:self.bundleIdentifier suspended:NO];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.bulletins.count;
}
@end