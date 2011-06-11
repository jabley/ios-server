//
//  Server.m
//  Client
//
//  Created by James Abley on 11/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Server.h"
#import "release.h"

#define SERVER_MAX_IOBUF 1024

/* Timeout in minutes */
#define SERVER_CLIENT_TIMEOUT (60*2)

#define SERVER_MAX_CLIENTS 300

/**
 * Key name for the client socket in the command dictionary.
 */
static NSString * kSocket = @"sock";

/**
 * Key name for the client command line in the command dictionary.
 */
static NSString * kCommandLine = @"cmd";

static NSString *VERSION = @"1.0";

/**
 * The terminator for the protocol.
 *
 * cmd[ args]\r\n
 */
static NSString * PROTOCOL_COMMAND_TERMINATOR = @"\r\n";

/**
 * Category for private API for this class.
 */
@interface Server(PrivateMethods)

/**
 * Wait for command input from the specified client socket.
 */
- (void)awaitCommand:(AsyncSocket *)sock;

/**
 * Processes a command from the CLI.
 *
 * @param the dictionary containing the command string and client socket. We pass things around this way due to
 *        lazyness. We could define a protocol, cast instances to that protocol and call a typed method. That seemed
 *        like too much work for now.
 */
- (void)processCommand:(NSDictionary*)command;

/**
 * Sends a reply to the client socket contained in the dictionary.
 * @param data the non-nil data to send to the client
 * @param command the non-nil dictionary containing the command information
 */
- (void)addReply:(NSData*)data command:(NSDictionary*)command;

@end

/**
 * Category for the methods defining the supported commands for this server. All of these methods have the same
 * signature; that is due to the dispatch mechanism using dictionary-based SEL lookup to invoke the SEL, passing in a
 * dictionary of parameters. That is a little lazy, but avoids needless complexity. Perhaps a structure would have been
 * an improvement; again, not bothered with that for now.
 */
@interface Server (SupportedCommands)

/**
 * Returns simple help for this server.
 */
- (void)helpCommand:(NSDictionary*)command;

/**
 * Returns the server info.
 *
 * @param command - the command object to be executed
 */
- (void)infoCommand:(NSDictionary*)command;

/**
 * Returns a response showing that the server is alive.
 *
 * @param command - the command object to be executed
 */
- (void)pingCommand:(NSDictionary*)command;

/**
 * Called when the client socket issues an unrecognised command.
 * @param command the non-nil dictionary containing the command string and client socket
 */
- (void)unknownCommand:(NSDictionary*)command;

@end

@implementation Server

- (id)init {
    if ((self = [super init])) {
        serverSocket_ = [[AsyncSocket alloc] initWithDelegate:self];
        commands_ = [[NSDictionary alloc] initWithObjectsAndKeys:
                     [NSValue valueWithPointer:@selector(helpCommand:)], @"help",
                     [NSValue valueWithPointer:@selector(infoCommand:)], @"info",
                     [NSValue valueWithPointer:@selector(pingCommand:)], @"ping",
                     nil];
        clientSockets_ = [[NSMutableArray alloc] init];
        startTime = time(NULL);
        num_commands = 0;
    }

    return self;
}

- (void)dealloc {
    [clientSockets_ release];

    [commands_ release];

    [serverSocket_ disconnect];
    [serverSocket_ release];

    [super dealloc];
}

#pragma mark AsyncSocketDelegate
/**
 * In the event of an error, the socket is closed.
 * You may call "unreadData" during this call-back to get the last bit of data off the socket.
 * When connecting, this delegate method may be called
 * before"onSocket:didAcceptNewSocket:" or "onSocket:didConnectToHost:".
 **/
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {}

/**
 * Called when a socket disconnects with or without error.  If you want to release a socket after it disconnects,
 * do so here. It is not safe to do that during "onSocket:willDisconnectWithError:".
 **/
- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    [clientSockets_ removeObject:sock];
}

/**
 * Called when a socket accepts a connection.  Another socket is spawned to handle it. The new socket will have
 * the same delegate and will call "onSocket:didConnectToHost:port:".
 **/
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {

    // Retain the new client socket if we want to accept the connection
    [clientSockets_ addObject:newSocket];
}

/**
 * Called when a socket is about to connect. This method should return YES to continue, or NO to abort.
 * If aborted, will result in AsyncSocketCanceledError.
 *
 * If the connectToHost:onPort:error: method was called, the delegate will be able to access and configure the
 * CFReadStream and CFWriteStream as desired prior to connection.
 *
 * If the connectToAddress:error: method was called, the delegate will be able to access and configure the
 * CFSocket and CFSocketNativeHandle (BSD socket) as desired prior to connection. You will be able to access and
 * configure the CFReadStream and CFWriteStream in the onSocket:didConnectToHost:port: method.
 **/
- (BOOL)onSocketWillConnect:(AsyncSocket *)sock {

    /*
     * Slightly fuzzy test in that this isn't thread-safe. That is fine - this is a basic safety check to stop simple
     * DoS / QoS degradation.
     */
    BOOL result = [clientSockets_ count] < SERVER_MAX_CLIENTS;

    if (!result) {
        [clientSockets_ removeObject:sock];
    }

    return result;
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    [self awaitCommand: sock];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *command = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    // Strip the trailing delimiter chars that are included in the data buffer
    command = [command substringToIndex:[command length] - [PROTOCOL_COMMAND_TERMINATOR length]];

    NSLog(@"%@:%@ read <%@>", self, NSStringFromSelector(_cmd), command);

    NSDictionary *cmd = [[NSDictionary alloc] initWithObjectsAndKeys:
                             command, kCommandLine,
                             sock, kSocket,
                             nil];
    [self processCommand:cmd];
    [cmd release];
}

#pragma mark Server
- (BOOL)startWithPort:(NSInteger)port {
    NSError *err = nil;

    if (![serverSocket_ acceptOnPort:port error:&err]) {
        [serverSocket_ release];
        serverSocket_ = nil;
        return NO;
    }

    return YES;
}

- (void)stop {
    [serverSocket_ disconnect];
}

#pragma mark PrivateMethods
- (void) awaitCommand: (AsyncSocket *) sock  {
    NSData * terminator = [PROTOCOL_COMMAND_TERMINATOR dataUsingEncoding:NSUTF8StringEncoding];
    [sock readDataToData:terminator withTimeout:SERVER_CLIENT_TIMEOUT maxLength:SERVER_MAX_IOBUF tag:0];
}

- (void)processCommand:(NSDictionary *)command {

    NSString *cmdLine = [command objectForKey:kCommandLine];
    NSArray *tokens = [cmdLine componentsSeparatedByString:@" "];
    NSString *name = [tokens objectAtIndex:0];

    SEL cmd = [[commands_ objectForKey:name] pointerValue];

    if (cmd) {
        [self performSelector:cmd withObject:command];
        ++num_commands;
    } else {
        [self unknownCommand:command];
    }

    [self awaitCommand:[command objectForKey:kSocket]];
}

- (void)addReply:(NSData *)data command:(NSDictionary *)command {
    AsyncSocket *sock = [command objectForKey:kSocket];
    [sock writeData:data withTimeout:-1.0 tag:0];
}

#pragma mark SupportedCommands
- (void)helpCommand:(NSDictionary *)command {
    NSString *text = [NSString stringWithFormat:@"supported commands:\r\n%@\r\n",
                      [[commands_ allKeys] componentsJoinedByString:@"\r\n"]];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self addReply:data command:command];
}

- (void)infoCommand:(NSDictionary*)command {
    time_t uptime = time(NULL) - startTime;

    /* Multi-line string in Objective-C - yay! */
    NSString *template = @"version:%@\r\n"
                        @"git-sha1:%@\r\n"
                        @"git-dirty:%@\r\n"
                        @"uptime-in-seconds:%ld\r\n"
                        @"uptime-in-days:%ld\r\n"
                        @"connected-clients:%d\r\n"
                        @"total-commands-processed:%ld\r\n";
    NSData *data = [[NSString stringWithFormat:template,
                     VERSION,
                     gitSHA1,
                     gitDirty,
                     uptime,
                     uptime / (3600*24),
                     [clientSockets_ count],
                     num_commands] dataUsingEncoding:NSUTF8StringEncoding];
    [self addReply:data command:command];
}

- (void)pingCommand:(NSDictionary*)command {
    NSData *data = [@"+PONG\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    [self addReply:data command:command];
}

- (void)unknownCommand:(NSDictionary*)command {
    NSString *message = [NSString stringWithFormat:@"-ERR unknown command '%@'\r\n", [command objectForKey:kCommandLine]];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self addReply:data command:command];
}

@end

