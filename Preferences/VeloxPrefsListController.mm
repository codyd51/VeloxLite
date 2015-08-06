#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCellType.h>
#import <Social/SLComposeViewController.h>
#import <Social/SLServiceTypes.h>
#import "../DebugLog.h"
#import "TintColor.h"
#import "images/conman.h"
#import "ducky.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import "AFNetworking/AFNetworking.h"

extern "C" {
    CFStringRef MGCopyAnswer(CFStringRef property);
    CFNotificationCenterRef CFNotificationCenterGetDarwinNotifyCenter();
}

static int exist(const char *name)
{
  struct stat   buffer;
  return (stat (name, &buffer) == 0);
}

static AVAudioPlayer *audioPlayer;
static NSString *const kTweakPreferencePath = @"/User/Library/Preferences/com.phillipt.veloxlite.plist";
#define localized(a, b) [[self bundle] localizedStringForKey:(a) value:(b) table:nil]

@interface VeloxPrefsListController: PSListController {
    UIWindow *settingsView;
    UIBarButtonItem *composeTweet;
    UILabel *tweakName;
    UILabel *devName;
    UIImageView *conMan;
}
@property(nonatomic, strong) NSMutableArray *hiddenSpecifiers;
@end

@implementation VeloxPrefsListController
@synthesize hiddenSpecifiers;
- (id)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray new];
        hiddenSpecifiers = [NSMutableArray new];
        PSSpecifier *spec = [PSSpecifier emptyGroupSpecifier];

        [spec setProperty:@60 forKey:@"spacerHeight"];
        [spec setProperty:@"VeloxCustomCell" forKey:@"footerCellClass"];
        [specifiers addObject:spec];

        spec = [PSSpecifier emptyGroupSpecifier];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Upgrade to Velox 2"
            target:self 
            set:NULL 
            get:NULL
            detail:Nil 
            cell:PSButtonCell
            edit:Nil];
            spec->action = @selector(upgrade);
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Respring for this change to take effect" forKey:@"footerText"];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:localized(@"ENABLED", @"Enabled")
            target:self
            set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:)
            detail:Nil
            cell:PSSwitchCell
            edit:Nil ];
        [spec setProperty:@YES forKey:@"default"];
        [spec setProperty:@"enabled" forKey:@"key"];
        [spec setProperty:NSClassFromString(@"VeloxTintedSwitchCell") forKey:@"cellClass"];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier emptyGroupSpecifier];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:localized(@"DARK_MODE", @"Dark Mode")
            target:self
            set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:)
            detail:Nil
            cell:PSSwitchCell
            edit:Nil ];
        [spec setProperty:@YES forKey:@"default"];
        [spec setProperty:@"darkMode" forKey:@"key"];
        [spec setProperty:NSClassFromString(@"VeloxTintedSwitchCell") forKey:@"cellClass"];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier emptyGroupSpecifier];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:localized(@"ACTIVATION_METHOD", @"Activation Method")
            target:self
            set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:)
            detail:objc_getClass("VeloxListItemsController")
            cell:PSLinkListCell
            edit:Nil ];
        [spec setProperty:@0 forKey:@"default"];
        [spec setProperty:@"activationMethodsTitles" forKey:@"titlesDataSource"];
        [spec setProperty:@"activationMethodsValues" forKey:@"valuesDataSource"];
        [spec setProperty:@"activationMethod" forKey:@"key"];
        [spec setProperty:NSClassFromString(@"VeloxTintedCell") forKey:@"cellClass"];
        [hiddenSpecifiers addObject:spec];

        spec = [PSSpecifier emptyGroupSpecifier];
        [hiddenSpecifiers addObject:spec];

        DebugLog(@"Hidden Specifiers: %@", hiddenSpecifiers);
        NSNumber *obj = [[NSDictionary dictionaryWithContentsOfFile:kTweakPreferencePath] objectForKey:@"enabled"];

        //if (!obj || [obj boolValue]) {
            DebugLog(@"Showing specifiers");
            for (PSSpecifier *extraSpec in hiddenSpecifiers) {
                [specifiers addObject:extraSpec];
            }
        //}

        spec = [PSSpecifier preferenceSpecifierNamed:localized(@"MORE", @"More")
            target:self
            set:NULL
            get:NULL
            detail:objc_getClass("VeloxCreditsListController")
            cell:PSLinkCell
            edit:Nil ];
        [spec setProperty:NSClassFromString(@"VeloxTintedCell") forKey:@"cellClass"];
        [specifiers addObject:spec];

        _specifiers = [specifiers copy];
        //_specifiers = [self loadSpecifiersFromPlistName:@"VeloxPrefs" target:self];
    }
    return _specifiers;
}

-(void)upgrade {
    //when button is pressed
    NSURL *myURL = [NSURL URLWithString:@"cydia://package/com.phillipt.velox"];
    [[UIApplication sharedApplication] openURL:myURL];
}

-(NSArray *)activationMethodsTitles
{
    return @[
        localized(@"SWIPE_UP", @"Swipe Up on icon"),
        localized(@"SWIPE_DOWN", @"Swipe Down on icon"),
        localized(@"DOUBLE_TAP", @"Double Tap on icon"),
        localized(@"TRIPLE_TAP", @"Triple Tap on icon"),
        localized(@"HOLD_ON_ICON", @"Hold on icon")
    ];
}

-(NSArray *)activationMethodsValues
{
    return @[ @0, @1, @2, @3, @4 ];
}

-(void)tweetSweetNothings {
    SLComposeViewController *composeController = [SLComposeViewController
                                                  composeViewControllerForServiceType:SLServiceTypeTwitter];
    [composeController setInitialText:[NSString stringWithFormat:@"I'm trying #VeloxLite by @phillipten and using my phone faster than ever!"]];
    [self presentViewController:composeController
                       animated:YES completion:nil];
}
 
-(id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:kTweakPreferencePath];
    if (!tweakSettings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return tweakSettings[specifier.properties[@"key"]];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    DebugLog(@"setPreferenceValue:%@ specifier:%@", value, specifier);
    if ([specifier respondsToSelector:@selector(propertyForKey:)]) {
        DebugLog(@"Spec responds to -propertyForKey");

        NSString *key = [specifier propertyForKey:@"key"];
        NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
        [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kTweakPreferencePath]];
        [defaults setObject:value forKey:key];
        [defaults writeToFile:kTweakPreferencePath atomically:YES];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), 
                                             CFSTR("com.phillipt.velox/preferencesChanged"), 
                                             NULL, 
                                             NULL, 
                                             YES);
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    int width = [[UIScreen mainScreen] bounds].size.width;
    CGRect frame1 = CGRectMake(0, 5, width, 60);
    CGRect frame2 = CGRectMake(0, 40, width, 60);
    tweakName = [[UILabel alloc] initWithFrame:frame1];
    [tweakName setNumberOfLines:1];
    tweakName.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:40];
    [tweakName setText:@"Velox 2"];
    [tweakName setBackgroundColor:[UIColor clearColor]];
    tweakName.textColor = [UIColor blackColor];
    tweakName.textAlignment = NSTextAlignmentCenter;
    devName = [[UILabel alloc] initWithFrame:frame2];
    [devName setNumberOfLines:1];
    devName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    [devName setText:localized(@"BY_PHILLIP_TENNEN", @"By Phillip Tennen")];
    [devName setBackgroundColor:[UIColor clearColor]];
    devName.textColor = [UIColor grayColor];
    devName.textAlignment = NSTextAlignmentCenter;
    [self.table addSubview:tweakName];
    [self.table addSubview:devName];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    settingsView = [[UIApplication sharedApplication] keyWindow];
    settingsView.tintColor = kDarkerTintColor;
    composeTweet = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(tweetSweetNothings:)];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(duckShow:)];
    UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/VeloxPrefs.bundle/heart.png"];
    CGRect frameimg = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:image forState:UIControlStateNormal];
    [someButton addTarget:self action:@selector(tweetSweetNothings) forControlEvents:UIControlEventTouchUpInside];
    [someButton setShowsTouchWhenHighlighted:YES];
    [someButton addGestureRecognizer:longPress];
    UIBarButtonItem *tweetButton = [[UIBarButtonItem alloc] initWithCustomView:someButton];
    self.navigationItem.rightBarButtonItem = tweetButton;
}

-(void)duckShow:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSError *soundError = nil;
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:ducky options:0];
        audioPlayer = [[AVAudioPlayer alloc] initWithData:decodedData error:&soundError];
        if (soundError && !audioPlayer) {
            DebugLogC(@"sound error: %@", soundError);
        }
        [audioPlayer prepareToPlay];
        [audioPlayer play];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    settingsView.tintColor = nil;
}

-(void)setTitle:(id)title {
    [super setTitle:nil];
}

@end


// vim:ft=objc
