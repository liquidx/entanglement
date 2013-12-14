//
//  ETGDevice.h
//  Entanglement
//
//  Created by Alastair Tse on 13/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PTChannel.h"

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

- (id)initWithDelegate:(id<ETGDeviceDelegate>)delegate;
- (void)tryConnect;
- (void)disconnect;

@end
