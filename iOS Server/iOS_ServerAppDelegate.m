//
//  iOS_ServerAppDelegate.m
//  iOS Server
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iOS_ServerAppDelegate.h"
#import "Preferences.h"

@implementation iOS_ServerAppDelegate


@synthesize window=_window;

@synthesize server = _server;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    self.server = [[Server alloc] init];

    NSInteger port = [[Preferences sharedInstance] serverPort];

    if ([self.server startWithPort:port]) {
        NSLog(@"Server started on port %d", port);
    } else {
        NSString *connectionMessage = [NSString stringWithFormat:
                                       @"Failed to listen on port %d. Try another port in the application settings.", port];

        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:connectionMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_server release];
    [super dealloc];
}

@end
