#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import "images/stratos.h"

@interface VeloxStratosListController : PSListController {

}
@end

@implementation VeloxStratosListController

-(id)specifiers {
	if (_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"stratos" target:self];
	}
	return _specifiers;
}

-(void)openStratos {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.cortexdevteam.stratos"]];
}

@end

@interface VeloxCustomStratosCell : PSTableCell{
    UIImageView *stratosScreen;
}
@end

@implementation VeloxCustomStratosCell

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    if (self) {
        int width = [[UIScreen mainScreen] bounds].size.width;
        UIImage *stratosScreenImage = [UIImage imageWithData:stratosScreenData];
        stratosScreen = [[UIImageView alloc] initWithImage:stratosScreenImage];
        [stratosScreen setFrame:CGRectMake(0, 0, width-25, (width-25)*(915.5/350))];
        [stratosScreen setCenter:CGPointMake(width/2, -10)];
        [stratosScreen setContentMode:UIViewContentModeScaleAspectFit];
        [self addSubview:stratosScreen];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    return stratosScreen.bounds.size.height/2;
}
@end