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
#import "ETGDevice.h"

@interface ETGAppDelegate () <ETGClientDelegate>
@property(nonatomic, strong) NSTimer *screenshotTimer;
@property(nonatomic, strong) ETGClient *client;
@property(nonatomic, assign) NSInteger connectedDeviceCount;
@property(nonatomic, strong) NSMutableDictionary *deviceInfos;

@end

@implementation ETGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _client = [[ETGClient alloc] initWithDelegate:self];
  _deviceInfos = [NSMutableDictionary dictionary];
  [_client start];
}

#pragma mark - ETGClientDelegate

- (void)client:(ETGClient *)client didReceiveMessage:(ETGMessage *)message fromDevice:(ETGDevice *)device {
  if (message.messageType == kETGMessageTypeRequestImage) {
    [self screenshotAndSend];
  } else if (message.messageType == kETGMessageTypeDeviceInfo) {
    ETGDeviceInfoMessage *deviceInfoMessage = (ETGDeviceInfoMessage *)message;
    [_deviceInfos setObject:[deviceInfoMessage deviceInfo] forKey:@([device deviceID])];
    NSLog(@"%@", [deviceInfoMessage deviceInfo]);
  }
}

- (void)client:(ETGClient *)client deviceDidConnect:(ETGDevice *)device {
  _connectedDeviceCount++;
  if (_connectedDeviceCount > 0) {
    [self startScreenshotting];
  }
}

- (void)client:(ETGClient *)client deviceDidDisconnect:(ETGDevice *)device {
  _connectedDeviceCount--;
  [_deviceInfos removeObjectForKey:@([device deviceID])];
  if (_connectedDeviceCount < 1) {
    [self stopScreeshotting];
  }
}

#pragma mark - Screenshotting

- (void)startScreenshotting {
  if (_screenshotTimer) return;
  _screenshotTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
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
  for (NSNumber *deviceID in _deviceInfos) {
    NSDictionary *deviceInfo = [_deviceInfos objectForKey:deviceID];

    CGFloat devicePixelScale = [deviceInfo[@"scale"] floatValue];
    CGFloat devicePointWidth = [deviceInfo[@"width"] floatValue];
    CGFloat devicePointHeight = [deviceInfo[@"height"] floatValue];
    CGSize pixelSize = CGSizeMake(devicePointWidth * devicePixelScale, devicePointHeight * devicePixelScale);

    NSMutableData *data = [NSMutableData data];
    CGImageRef screenshot = CGWindowListCreateImage(CGRectMake(0, 0, pixelSize.width, pixelSize.height),
                                                    kCGWindowListOptionAll,
                                                    0,
                                                    kCGWindowImageDefault);

    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, kUTTypePNG, 1, 0);
    CGImageDestinationAddImage(destination, screenshot, nil);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    CGImageRelease(screenshot);

    ETGImageMessage *message = [[ETGImageMessage alloc] initWithData:data];
    [_client sendMessage:message toDeviceID:[deviceID integerValue]];

  }
}

@end
