//
//  Preferences.h
//  iOS Server
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Preferences : NSObject {

}

/**
 * Returns the shared instance.
 */
+ (Preferences*)sharedInstance;

/**
 * The port that the server listens on.
 */
@property (nonatomic) NSInteger serverPort;


@end
