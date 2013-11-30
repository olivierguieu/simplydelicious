//
//  MCOAppDelegate.m
//  test3
//
//  Created by Olivier Guieu on 19/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MCOAppDelegate.h"
#import "MCOMainViewController.h"
#import "FlurryAnalytics.h"

#import "ASIDownloadCache.h"

#define KDELICIOUSURL @"www.delicious.com"

@implementation MCOAppDelegate

@synthesize window = _window;
@synthesize mainViewController = _mainViewController;

@synthesize reachability;

- (void)dealloc
{
    [_window release];
    [_mainViewController release];
    
    [reachability release];
    
    [super dealloc];
}

- (BOOL) isConnected
{
    return isConnected;
}

- (void) setIsConnected: (BOOL) bConnected
{
    isConnected=bConnected;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FlurryAnalytics startSession:@"9BF7UZH2GG29Q4UTD8DT"];

    // Check network
    
    Reachability *r = [Reachability reachabilityWithHostName:KDELICIOUSURL];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == NotReachable)
    {
        self.isConnected = FALSE;
    }
    else
    {
        self.isConnected = TRUE;
    }
    
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
	self.reachability = [Reachability reachabilityWithHostName:KDELICIOUSURL];
	[self.reachability startNotifier];    

    
    // Activate standard cache for ASIHTTP - a priori inutile
    // [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    
    // Activate SDURLCache, cf https://github.com/rs/SDURLCache
    // ne sert effectivement qu'en dessous de la version 5.0 d'IOS
//    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024   // 1MB mem cache
//                                                         diskCapacity:1024*1024*5 // 5MB disk cache
//                                                             diskPath:[SDURLCache defaultCachePath]];
//    [NSURLCache setSharedURLCache:urlCache];
//    [urlCache release];
//    

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

    // Override point for customization after application launch.
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) 
    {
        self.mainViewController = [[[MCOMainViewController alloc] initWithNibName:@"MCOMainViewController-others" bundle:nil] autorelease];
    } 
    else
    {
        self.mainViewController = [[[MCOMainViewController alloc] initWithNibName:@"MCOMainViewController" bundle:nil] autorelease];
    }

    
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    
    

    
    return YES;
}

- (void)reachabilityChanged:(NSNotification*)note
{
	Reachability* r = [note object];
	NetworkStatus ns = r.currentReachabilityStatus;
    
	if (ns == NotReachable)
	{
        isConnected = FALSE;
	}
    else {
        isConnected=TRUE;
    }
    
    [self.mainViewController reflectReachabilityChanged];
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
