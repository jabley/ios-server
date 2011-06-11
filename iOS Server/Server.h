//
//  Server.h
//  Client
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

/**
 * Class that provides server services for the application. This class is responsible for opening the server socket and
 * dispatching commands.
 *
 * Commands take the format:
 *
 * name[ args]\r\n
 * <dl>
 *   <dt>name</dt>
 *   <dd>the command name</dd>
 *   <dt>args</dt>
 *   <dd>the optional arguments for the command</dd>
 *   <dt>/r/n</dt>
 *   <dd>the command terminator</dd>
 * </dl>
 *
 * See netty for more ideas.
 */
@interface Server : NSObject {

    /**
     * The Socket that this server is listening on.
     */
    AsyncSocket *serverSocket_;

    /**
     * The non-nil set of commands that this server will process, keyed by command name. This enables our table-based
     * dispatch mechanism.
     */
    NSDictionary * commands_;

    /**
     * The non-nil list of client sockets that have requested commands to be executed.
     */
    NSMutableArray *clientSockets_;

    /**
     * The application start time.
     */
    time_t startTime;

    /*
     * The number of commands that have been processed.
     */
    long long num_commands;
}

/**
 * Creates a new Server.
 * @param port - the port to bind to
 * @return YES if it started OK, otherwise NO
 */
- (BOOL)startWithPort:(NSInteger)port;

/**
 * Stops the server.
 */
- (void)stop;

@end
