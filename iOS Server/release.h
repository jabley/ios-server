//
//  release.h
//  Client
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

/**
 * Header file that can be included which contains git status information. The corresponding release.m file is generated
 * at build time by a script phase.
 */

/**
 * Returns the git SHA1 for the version that the binary was built against.
 */
extern NSString * const gitSHA1;

/**
 * Returns a flag indicating the git dirty state when the binary was built.
 */
extern NSString * const gitDirty;
