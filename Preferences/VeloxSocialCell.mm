#import <UIKit/UIKit.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import "../DebugLog.h"
#import "TintColor.h"

@interface VeloxSocialCell : PSTableCell { }
@end

@implementation VeloxSocialCell

-(void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.textColor = kDarkerTintColor;
    self.detailTextLabel.text = self.specifier.properties[@"handle"];
    self.detailTextLabel.textColor = [UIColor colorWithRed:151.0f/255.0f green:151.0f/255.0f blue:163.0f/255.0f alpha:1.0];
}

@end