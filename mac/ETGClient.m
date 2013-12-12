//
//  ETGClient.m
//  Entanglement
//
//  Created by Alastair Tse on 11/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGClient.h"
#import "PTChannel.h"
#import "ETGProtocol.h"
#import "ETGMessage.h"

static const NSTimeInterval kETGReconnectDelay = 1.0;

#pragma mark - Device

@class ETGDevice;

@protocol ETGDeviceDelegate <PTChannelDelegate>
- (void)deviceDidConnect:(ETGDevice *)device;
- (void)deviceDidDisconnect:(ETGDevice *)device;
@end

@interface ETGDevice : NSObject
@property(nonatomic, weak) id<ETGDeviceDelegate> delegate;
@property(nonatomic, assign) NSInteger deviceID;
@property(nonatomic, strong) PTChannel *activeChannel;
@property(nonatomic, strong) NSDictionary *properties;

- (id)initWithDelegate:(id<ETGClientDelegate>)delegate;
- (void)tryConnect;
- (void)disconnect;

@end

@implementation ETGDevice

- (id)initWithDelegate:(id<ETGDeviceDelegate>)delegate {
  self = [super init];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

- (void)disconnect {
  [_delegate deviceDidDisconnect:self];
  [_activeChannel close];
  _activeChannel = nil;
}

- (void)tryConnect {
  if (_activeChannel) return;  // Already connected.

  PTChannel *channel = [PTChannel channelWithDelegate:_delegate];
  channel.userInfo = @(_deviceID);

  [channel connectToPort:ETGProtocolPort
              overUSBHub:[PTUSBHub sharedHub]
                deviceID:@(_deviceID)
                callback:^(NSError *error) {
                  if (error) {
                    // Failed to connect, try again.
                    NSLog(@"Failed to connect to device #%ld: %@", _deviceID, error);
                    [self performSelector:@selector(tryConnect)
                               withObject:nil
                               afterDelay:kETGReconnectDelay];
                     return;
                  }

                  NSLog(@"Connect device %ld with channel.", _deviceID);
                  // Successfully connected.
                  _activeChannel = channel;
                  [_delegate deviceDidConnect:self];
                }];

}

@end

#pragma mark - Client


@interface ETGClient () <ETGDeviceDelegate>

@property(nonatomic, strong) dispatch_queue_t connectionRequestQueue;
@property(nonatomic, strong) NSMutableArray *attachedDevices;  // ETCDevice(s)

@end

@implementation ETGClient

- (id)initWithDelegate:(id<ETGClientDelegate>)delegate {
  self = [super init];
  if (self) {
    // We use a serial queue that we toggle depending on if we are connected or
    // not. When we are not connected to a peer, the queue is running to handle
    // "connect" tries. When we are connected to a peer, the queue is suspended
    // thus no longer trying to connect.
    _connectionRequestQueue = dispatch_queue_create("ETGConnectionRequestQueue", DISPATCH_QUEUE_SERIAL);
    _delegate = delegate;
    _attachedDevices = [NSMutableArray array];
  }
  return self;
}

- (void)start {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

  // Monitor USB device attachments.
  //
  // When they occur, being attempting to connect to the ETG service.
  [nc addObserverForName:PTUSBDeviceDidAttachNotification
                  object:[PTUSBHub sharedHub]
                   queue:nil
              usingBlock:^(NSNotification *note) {
                NSLog(@"PTUSBDeviceDidAttachNotification: %@", note.userInfo);
                ETGDevice *device = [[ETGDevice alloc] initWithDelegate:self];
                device.properties = note.userInfo[@"Properties"];
                device.deviceID = [note.userInfo[@"DeviceID"] integerValue];
                [_attachedDevices addObject:device];

                dispatch_async(_connectionRequestQueue, ^{
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [device tryConnect];
                  });
                });
              }];

  // Monitor USB device detachments.
  //
  // When they occur, remove the specific device from our attached devices array.
  [nc addObserverForName:PTUSBDeviceDidDetachNotification
                  object:[PTUSBHub sharedHub]
                   queue:nil
              usingBlock:^(NSNotification *note) {
                NSInteger detachedDeviceID = [[note.userInfo objectForKey:@"DeviceID"] integerValue];
                NSLog(@"PTUSBDeviceDidDetachNotification: %ld", detachedDeviceID);

                for (ETGDevice *device in _attachedDevices) {
                  if ([device deviceID] == detachedDeviceID) {
                    [device disconnect];
                    [_attachedDevices removeObject:device];
                    break;
                  }
                }
              }];
}

- (void)stop {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (void)broadcastMessageToConnectedChannels:(ETGMessage *)message {
  for (ETGDevice *device in _attachedDevices) {
    if ([device activeChannel]) {
      [message sendWithChannel:[device activeChannel] completed:nil];
    }
  }
}

#pragma mark -

- (ETGDevice *)deviceWithChannel:(PTChannel *)channel {
  for (ETGDevice *device in _attachedDevices) {
    if ([[device activeChannel] isEqual:channel]) return device;
  }
  return nil;
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel
shouldAcceptFrameOfType:(uint32_t)type
                   tag:(uint32_t)tag
           payloadSize:(uint32_t)payloadSize {

  if (type == kETGMessageTypeRequestImage) {
    NSLog(@"image request received");
    return YES;
  }

  NSLog(@"Unexpected frame of type %u", type);
  ETGDevice *device = [self deviceWithChannel:channel];
  [device disconnect];
  [device tryConnect];

  return NO;
}

- (void)ioFrameChannel:(PTChannel*)channel
 didReceiveFrameOfType:(uint32_t)type
                   tag:(uint32_t)tag
               payload:(dispatch_data_t)payload {
  NSLog(@"received %@, %u, %u, %@", channel, type, tag, payload);
  ETGMessage *message = nil;
  if (type == kETGMessageTypeImage) {
    message = [[ETGImageMessage alloc] initWithPayload:payload];
  } else if (type == kETGMessageTypeRequestImage) {
    message = [[ETGMessage alloc] init];
    message.messageType = kETGMessageTypeRequestImage;
  }

  [_delegate client:self didReceiveMessage:message];
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
  ETGDevice *device = [self deviceWithChannel:channel];
  [device disconnect];
  [device tryConnect];
  NSLog(@"Channel ended with Error: %@", error);
}

#pragma mark - 

- (void)deviceDidConnect:(ETGDevice *)device {
  [_delegate client:self channelDidConnect:[device activeChannel]];
}

- (void)deviceDidDisconnect:(ETGDevice *)device {
  [_delegate client:self channelDidDisconnect:[device activeChannel]];

}

@end
