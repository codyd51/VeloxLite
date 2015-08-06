#import "Interfaces.h"

@interface VeloxCustomListController : PSListController {
    UIWindow *settingsView;

}
@end

@implementation VeloxCustomListController
-(id)specifiers {
    NSMutableArray *specifiers = [[NSMutableArray alloc] init];
    if (_specifiers == nil) {
        
        NSString* sourcePath = @"/Library/Application Support/Velox/API/";
        NSArray* fileHolderArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourcePath error:NULL];
        [fileHolderArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* filename = (NSString*)obj;
            DebugLogC(@"filename is %@", filename);
            NSString *appFolder = [sourcePath stringByAppendingPathComponent:filename];
            BOOL isDir = NO;
            NSString *dictPlist = [appFolder stringByAppendingPathComponent:@"Info.plist"];
            [[NSFileManager defaultManager]
             fileExistsAtPath:appFolder isDirectory:&isDir];
            if (isDir && [[NSFileManager defaultManager] fileExistsAtPath:dictPlist]) {
                NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:dictPlist];
                NSString *name = [dict objectForKey:@"preferenceBundleLabel"];
                NSString *bundleName = [appFolder stringByAppendingPathComponent:[dict objectForKey:@"preferenceBundleName"]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:bundleName] && [dict objectForKey:@"preferenceBundleName"]) {
                    DebugLogC(@"[%@] It exists. bundleName: %@", name, bundleName);
                    PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:name
                                                                            target:self
                                                                               set:NULL
                                                                               get:NULL
                                                                            detail:Nil
                                                                              cell:PSLinkCell
                                                                              edit:Nil];
                    [specifier setProperty:bundleName forKey:@"lazy-bundle"];
                    specifier->action = @selector(lazyLoadBundle:);
                    [specifier setProperty:NSClassFromString(@"VeloxTintedCell") forKey:@"cellClass"];
                    [specifiers addObject:specifier];
                } else {
                    DebugLogC(@"[%@] It don't exist", name);
                }
            }
        }];
        _specifiers = [NSArray arrayWithArray:specifiers];
    }
    DebugLogC(@"_specifiers: %@", _specifiers);
    return _specifiers;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isMovingToParentViewController)
        [self reloadSpecifiers];
    settingsView = [[UIApplication sharedApplication] keyWindow];
    settingsView.tintColor = kDarkerTintColor;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    settingsView.tintColor = nil;
}

@end