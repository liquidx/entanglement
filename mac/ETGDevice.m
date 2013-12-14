//
//  ETGDevice.m
//  Entanglement
//
//  Created by Alastair Tse on 13/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGDevice.h"
#import "ETGProtocol.h"

static const NSTimeInterval kETGReconnectDelay = 1.0;

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
