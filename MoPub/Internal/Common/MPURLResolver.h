//
//  MPURLResolver.h
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPGlobal.h"
#import "MPURLActionInfo.h"

typedef void (^MPURLResolverCompletionBlock)(MPURLActionInfo *actionInfo, NSError *error);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_5_0
@interface MPURLResolver : NSObject <NSURLConnectionDataDelegate>
#else
@interface MPURLResolver : NSObject
#endif

+ (instancetype)resolverWithURL:(NSURL *)URL completion:(MPURLResolverCompletionBlock)completion;
- (void)start;
- (void)cancel;

@end
