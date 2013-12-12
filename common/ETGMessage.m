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

- (void)sendWithChannel:(PTChannel *)channel completed:(void(^)(NSError *error))callback {
  [channel sendFrameOfType:_messageType
                       tag:_tag
               withPayload:_payload
                  callback:callback];
}

@end


@implementation ETGImageMessage

- (id)initWithPayload:(dispatch_data_t)payload {
  self = [super init];
  if (self) {
    self.messageType = kETGMessageTypeImage;
    self.tag = 0;
    self.payload = payload;
  }
  return self;
}

- (id)initWithData:(NSData *)data {
  self = [super init];
  if (self) {
    self.messageType = kETGMessageTypeImage;
    self.tag = 0;
    self.payload = [data createReferencingDispatchData];
//    void *bytes = CFAllocatorAllocate(NULL, [data length], 0);
//    self.payload = dispatch_data_create(bytes, [data length], nil, ^{
//      CFAllocatorDeallocate(NULL, bytes);
//    });
  }
  return self;
}

- (NSData *)data {
//  return [NSData dataWithContentsOfDispatchData:self.payload];
  __block NSMutableData *data = [NSMutableData dataWithCapacity:dispatch_data_get_size(self.payload)];
  dispatch_data_apply(self.payload, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
    [data appendBytes:buffer length:size];
    return YES;
  });
  return data;
}

@end
