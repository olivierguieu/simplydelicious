//
//  MCOAppDelegate.h
//  test3
//
//  Created by Olivier Guieu on 19/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@class MCOMainViewController;

@interface MCOAppDelegate : UIResponder <UIApplicationDelegate>
{
    BOOL            isConnected;
}

@property (nonatomic, retain) Reachability* reachability;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MCOMainViewController *mainViewController;

- (BOOL) isConnected;
- (void) setIsConnected: (BOOL) bConnected;


@end
