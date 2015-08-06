#import <UIKit/UIKit.h>
#import <Preferences/PSTableCell.h>
#import "../DebugLog.h"
#import "images/conman.h"

@interface VeloxCustomCell : PSTableCell{
    CGFloat height;
}
@end

@implementation VeloxCustomCell

- (id)initWithSpecifier:(id)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    if (self) {
        if ([specifier respondsToSelector:@selector(propertyForKey:)]) {
            height = [[specifier propertyForKey:@"spacerHeight"] floatValue];
        }
    }
    
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return height;
}
/*
- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    if (self) {
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGRect frame1 = CGRectMake(0, -30, width, 60);
        CGRect frame2 = CGRectMake(0, 5, width, 60);
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
        [devName setText:@"By Phillip Tennen"];
        [devName setBackgroundColor:[UIColor clearColor]];
        devName.textColor = [UIColor grayColor];
        devName.textAlignment = NSTextAlignmentCenter;
        if (isPirated) {
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:conmanData options:0];
            UIImage *conManImage = [UIImage imageWithData:imageData];
            conMan = [[UIImageView alloc] initWithImage:conManImage];
            [conMan setFrame:CGRectMake(0, 0, 250, 171.5)];
            [conMan setCenter:CGPointMake(width/2, 145)];
            [self addSubview:conMan];
        }
        [self addSubview:tweakName];
        [self addSubview:devName];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    if (isPirated)
        return 215.0f;
    return 80.0f;
}
*/
@end