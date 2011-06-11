//
//  iOS_ServerAppDelegate.h
//  iOS Server
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"

@interface iOS_ServerAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) Server *server;

@end
