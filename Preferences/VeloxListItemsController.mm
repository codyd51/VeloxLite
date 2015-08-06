#import <UIKit/UIKit.h>
#import <Preferences/PSListItemsController.h>
#import "TintColor.h"

@interface VeloxListItemsController : PSListItemsController {
    UIWindow *settingsView;
}
@end

@implementation VeloxListItemsController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    settingsView = [[UIApplication sharedApplication] keyWindow];
    settingsView.tintColor = kDarkerTintColor;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    settingsView.tintColor = nil;
}

@end