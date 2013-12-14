//
//  ETGMessage.h
//  Entanglement
//
//  Created by Alastair Tse on 11/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
  kETGMessageTypeUnknown = 0,
  kETGMessageTypeImage = 1,
  kETGMessageTypeRequestImage = 2,
  kETGMessageTypeDeviceInfo = 3,
  kETGMessageTypeTranslateViewport = 4,  // translates the viewport on the device.
};

@class PTChannel;
@class PTData;

@interface ETGMessage : NSObject

@property (nonatomic, assign) uint32_t messageType;
@property (nonatomic, assign) uint32_t tag;
@property (nonatomic, strong) dispatch_data_t payload;

- (id)initWithPayload:(dispatch_data_t)payload messageType:(uint32_t)messageType;
- (id)initWithData:(NSData *)data messageType:(uint32_t)messageType;

- (id)initWithPayload:(dispatch_data_t)payload;
- (id)initWithData:(NSData *)data;

- (NSData *)data;

- (void)sendWithChannel:(PTChannel *)channel completed:(void(^)(NSError *error))callback;

@end

@interface ETGImageMessage : ETGMessage
@end

@interface ETGDeviceInfoMessage : ETGMessage

- (id)initWithDeviceInfo:(NSDictionary *)deviceInfo;
- (NSDictionary *)deviceInfo;

@end

@interface ETGTranslateViewportMessage : ETGMessage
- (id)initWithTranslation:(CGPoint)translation;
- (CGPoint)translation;
@end