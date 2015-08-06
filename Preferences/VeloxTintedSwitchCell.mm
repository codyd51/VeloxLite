#import <UIKit/UIKit.h>
#import <Preferences/PSSwitchTableCell.h>
#import "TintColor.h"

@interface VeloxTintedSwitchCell : PSSwitchTableCell { }
@end

@implementation VeloxTintedSwitchCell

-(id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        if ([(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.gmoran.eclipse"))) boolValue]) //Eclipse Compatibility
        	    [((UISwitch *)[self control]) setTintColor:kTintColor];
        [((UISwitch *)[self control]) setOnTintColor:kTintColor]; //change the switch color
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.textColor = kDarkerTintColor;
}

@end
