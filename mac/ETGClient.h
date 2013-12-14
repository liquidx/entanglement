//
//  ETGClient.h
//  Entanglement
//
//  Created by Alastair Tse on 11/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ETGMessage.h"

@protocol ETGClientDelegate;
@class ETGDevice;

/**
 * Entanglement protocol client.
 *
 * This client monitors USB attachments and detachments, probes for newly connected
 * devices that have the entanglement client turned on on all attached devices.
 */
@interface ETGClient : NSObject

@property(nonatomic, weak) id<ETGClientDelegate> delegate;

- (id)initWithDelegate:(id<ETGClientDelegate>)delegate;
- (void)start;

- (void)broadcastMessageToConnectedChannels:(ETGMessage *)message;
- (void)sendMessage:(ETGMessage *)message toDeviceID:(NSInteger)deviceID;

@end

@protocol ETGClientDelegate <NSObject>

- (void)client:(ETGClient *)client didReceiveMessage:(ETGMessage *)message fromDevice:(ETGDevice *)device;
- (void)client:(ETGClient *)client deviceDidConnect:(ETGDevice *)device;
- (void)client:(ETGClient *)client deviceDidDisconnect:(ETGDevice *)device;

@end
