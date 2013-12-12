//
//  ETGMessage.h
//  Entanglement
//
//  Created by Alastair Tse on 11/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
  kETGMessageTypeImage = 1,
  kETGMessageTypeRequestImage = 2
};

@class PTChannel;
@class PTData;

@interface ETGMessage : NSObject

@property (nonatomic, assign) uint32_t messageType;
@property (nonatomic, assign) uint32_t tag;
@property (nonatomic, strong) dispatch_data_t payload;

- (void)sendWithChannel:(PTChannel *)channel completed:(void(^)(NSError *error))callback;

@end

@interface ETGImageMessage : ETGMessage

- (id)initWithPayload:(dispatch_data_t)payload;
- (id)initWithData:(NSData *)data;
- (NSData *)data;

@end