//
//  ETGAppDelegate.m
//  EntanglementOSX
//
//  Created by Alastair Tse on 10/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGAppDelegate.h"
#import "PTChannel.h"
#import "PTUSBHub.h"
#import "ETGProtocol.h"
#import "ETGMessage.h"
#import "ETGClient.h"

@interface ETGAppDelegate () <ETGClientDelegate>
@property(nonatomic, strong) NSTimer *screenshotTimer;
@property(nonatomic, strong) ETGClient *client;
@property(nonatomic, assign) NSInteger hasConnectedChannel;
@end

@implementation ETGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _client = [[ETGClient alloc] initWithDelegate:self];
  [_client start];
}

#pragma mark - ETGClientDelegate

- (void)client:(ETGClient *)client didReceiveMessage:(ETGMessage *)message {
  if (message.messageType == kETGMessageTypeRequestImage) {
    [self screenshotAndSend];
  }
}

- (void)client:(ETGClient *)client channelDidConnect:(PTChannel *)channel {
  _hasConnectedChannel++;
  if (_hasConnectedChannel) {
    [self startScreenshotting];
  }
}

- (void)client:(ETGClient *)client channelDidDisconnect:(PTChannel *)channel {
  _hasConnectedChannel--;
  if (_hasConnectedChannel < 1) {
    [self stopScreeshotting];
  }
}

#pragma mark - Screenshotting

- (void)startScreenshotting {
  if (!_screenshotTimer) return;
  _screenshotTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(screenshotTimerDidFire:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)stopScreeshotting {
  [_screenshotTimer invalidate];
  _screenshotTimer = nil;
}

- (void)screenshotTimerDidFire:(NSTimer *)timer {
  [self screenshotAndSend];
}

- (void)screenshotAndSend {
  NSMutableData *data = [NSMutableData data];
  CGImageRef screenshot = CGWindowListCreateImage(CGRectMake(0, 0, 640, 1136), kCGWindowListOptionAll, 0, kCGWindowImageDefault);
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, kUTTypePNG, 1, 0);
  CGImageDestinationAddImage(destination, screenshot, nil);
  CGImageDestinationFinalize(destination);
  CFRelease(destination);
  CGImageRelease(screenshot);

  ETGMessage *message = [[ETGImageMessage alloc] initWithData:data];
  [_client broadcastMessageToConnectedChannels:message];
}

@end
