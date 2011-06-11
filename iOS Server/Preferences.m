//
//  Preferences.m
//  iOS Server
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"

static NSString * kServerPort = @"server.port";

/**
 * The static singleton instance.
 */
static Preferences *sharedInstance = nil;

@implementation Preferences


+ (void)initialize {
    NSDictionary *applicationDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithUnsignedShort:8090], kServerPort,
                                         nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:applicationDefaults];
}

- (NSInteger)serverPort {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kServerPort];
}

- (void)setServerPort:(NSInteger)serverPort {
    [[NSUserDefaults standardUserDefaults] setInteger:serverPort forKey:kServerPort];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Singleton methods

// Below code based on Apple recommendations...

+ (Preferences*)sharedInstance {
    @synchronized(self) {
        if (sharedInstance == nil) {
			sharedInstance = [[Preferences alloc] init];
		}
    }

    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}


@end
