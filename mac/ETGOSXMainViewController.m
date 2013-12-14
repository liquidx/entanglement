//
//  ETGOSXMainViewController.m
//  Entanglement
//
//  Created by Alastair Tse on 14/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGOSXMainViewController.h"
#import "ETGClient.h"
#import "ETGDevice.h"

@interface ETGOSXMainViewController () <ETGClientDelegate>

@property(nonatomic, strong) NSTimer *screenshotTimer;
@property(nonatomic, strong) ETGClient *client;
@property(nonatomic, assign) NSInteger connectedDeviceCount;
@property(nonatomic, strong) NSMutableDictionary *deviceInfos;
@property(nonatomic, assign) CGRect captureRect;

@end

@implementation ETGOSXMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _deviceInfos = [NSMutableDictionary dictionary];
    _client = [[ETGClient alloc] initWithDelegate:self];
    [_client start];
  }
  return self;
}


#pragma mark - ETGClientDelegate

- (void)client:(ETGClient *)client didReceiveMessage:(ETGMessage *)message fromDevice:(ETGDevice *)device {
  if (message.messageType == kETGMessageTypeRequestImage) {
    [self screenshotAndSend];
  } else if (message.messageType == kETGMessageTypeDeviceInfo) {
    ETGDeviceInfoMessage *deviceInfoMessage = (ETGDeviceInfoMessage *)message;
    NSDictionary *deviceInfo = [deviceInfoMessage deviceInfo];
    [_deviceInfos setObject:deviceInfo forKey:@([device deviceID])];
    [_deviceListMenu addItemWithTitle:deviceInfo[@"name"]];
    NSLog(@"%@", [deviceInfoMessage deviceInfo]);

    // Get capture rect
    CGFloat scale = [deviceInfo[@"scale"] doubleValue];
    CGFloat width = [deviceInfo[@"width"] doubleValue];
    CGFloat height = [deviceInfo[@"height"] doubleValue];
    _captureRect = CGRectMake(0, 0, width * scale, height * scale);

  } else if (message.messageType == kETGMessageTypeTranslateViewport) {
    ETGTranslateViewportMessage *translateMessage = (ETGTranslateViewportMessage *)message;
    CGPoint translation = [translateMessage translation];
    _captureRect.origin.x += translation.x;
    _captureRect.origin.y += translation.y;
    NSLog(@"Capture Rect: (%f, %f), (%f, %f)", _captureRect.origin.x, _captureRect.origin.y, _captureRect.size.width, _captureRect.size.height);
  }
}

- (void)client:(ETGClient *)client deviceDidConnect:(ETGDevice *)device {
  _connectedDeviceCount++;
  if (_connectedDeviceCount > 0) {
    _statusField.stringValue = @"Connected";
    [self startScreenshotting];
  }
}

- (void)client:(ETGClient *)client deviceDidDisconnect:(ETGDevice *)device {
  _connectedDeviceCount--;
  NSString *deviceName = _deviceInfos[@([device deviceID])][@"name"];
  [_deviceListMenu removeItemWithTitle:deviceName];
  [_deviceInfos removeObjectForKey:@([device deviceID])];

  if (_connectedDeviceCount < 1) {
    _statusField.stringValue = @"Disconnected";
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
    NSMutableData *data = [NSMutableData data];
    CGImageRef screenshot = CGWindowListCreateImage(_captureRect,
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
