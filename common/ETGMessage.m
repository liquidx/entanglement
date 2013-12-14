//
//  ETGMessage.m
//  Entanglement
//
//  Created by Alastair Tse on 11/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGMessage.h"
#import "PTChannel.h"
#import "PTProtocol.h"

@implementation ETGMessage

- (id)initWithPayload:(dispatch_data_t)payload messageType:(uint32_t)messageType {
  self = [super init];
  if (self) {
    self.messageType = messageType;
    self.tag = 0;
    self.payload = payload;
  }
  return self;
}

- (id)initWithData:(NSData *)data messageType:(uint32_t)messageType {
  self = [super init];
  if (self) {
    self.messageType = messageType;
    self.tag = 0;
    self.payload = [data createReferencingDispatchData];
  }
  return self;
}

- (id)initWithPayload:(dispatch_data_t)payload {
  return [self initWithPayload:payload messageType:kETGMessageTypeUnknown];
}

- (id)initWithData:(NSData *)data {
  return [self initWithData:data messageType:kETGMessageTypeUnknown];
}


- (NSData *)data {
  if (!_payload) return nil;

  //  return [NSData dataWithContentsOfDispatchData:self.payload];
  __block NSMutableData *data = [NSMutableData dataWithCapacity:dispatch_data_get_size(self.payload)];
  dispatch_data_apply(self.payload, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
    [data appendBytes:buffer length:size];
    return YES;
  });
  return data;
}

- (void)sendWithChannel:(PTChannel *)channel completed:(void(^)(NSError *error))callback {
  [channel sendFrameOfType:_messageType
                       tag:_tag
               withPayload:_payload
                  callback:callback];
}

@end


@implementation ETGImageMessage

- (id)initWithPayload:(dispatch_data_t)payload {
  return [self initWithPayload:payload messageType:kETGMessageTypeImage];
}

- (id)initWithData:(NSData *)data {
  return [self initWithData:data messageType:kETGMessageTypeImage];
}

@end

@implementation ETGDeviceInfoMessage

- (id)initWithDeviceInfo:(NSDictionary *)deviceInfo {
  return [self initWithData:[NSJSONSerialization dataWithJSONObject:deviceInfo options:0 error:NULL]
                messageType:kETGMessageTypeDeviceInfo];
}

- (id)initWithPayload:(dispatch_data_t)payload {
  return [self initWithPayload:payload messageType:kETGMessageTypeDeviceInfo];
}

- (NSDictionary *)deviceInfo {
  return [NSJSONSerialization JSONObjectWithData:[self data] options:0 error:NULL];
}

@end

@implementation ETGTranslateViewportMessage

- (id)initWithPayload:(dispatch_data_t)payload {
  return [self initWithPayload:payload messageType:kETGMessageTypeTranslateViewport];
}

- (id)initWithTranslation:(CGPoint)translation {
  NSDictionary *point = @{@"x": @(translation.x), @"y": @(translation.y)};
  return [self initWithData:[NSJSONSerialization dataWithJSONObject:point options:0 error:NULL]
                messageType:kETGMessageTypeTranslateViewport];
}

- (CGPoint)translation {
  NSDictionary *point = [NSJSONSerialization JSONObjectWithData:[self data] options:0 error:NULL];
  return CGPointMake([point[@"x"] doubleValue], [point[@"y"] doubleValue]);
}


@end
