//
//  ETGViewController.m
//  Entanglement
//
//  Created by Alastair Tse on 10/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGViewController.h"
#import "ETGProtocol.h"
#import "PTChannel.h"
#import "ETGMessage.h"

@interface ETGViewController () <PTChannelDelegate>

@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property(nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property(nonatomic, assign) CGPoint lastPoint;

@end

@implementation ETGViewController {
  PTChannel *_peerChannel;
  PTChannel *_serverChannel;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  _imageView = [[UIImageView alloc] initWithFrame:[[self view] bounds]];
  _imageView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
  [self.view addSubview:_imageView];

  _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
  [self.view addGestureRecognizer:_tapRecognizer];

  _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
  _lastPoint = CGPointZero;
  [self.view addGestureRecognizer:_panRecognizer];

  // Create a new channel that is listening on our IPv4 port
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  [channel listenOnPort:ETGProtocolPort
            IPv4Address:INADDR_LOOPBACK
               callback:^(NSError *error) {
                 if (error) {
                   NSLog(@"Failed to connect: %@", error);
                   return;
                 }
                 NSLog(@"Connected");
                 _serverChannel = channel;
               }];
}

- (void)dealloc {
  [_peerChannel close];
  [_serverChannel close];
}

#pragma mark -

- (void)tap:(UITapGestureRecognizer *)tapRecognizer {
  if (tapRecognizer.state == UIGestureRecognizerStateEnded) {
    ETGMessage *message = [[ETGMessage alloc] init];
    message.messageType = kETGMessageTypeRequestImage;
    message.tag = 0;
    message.payload = nil;
    [message sendWithChannel:_peerChannel completed:^(NSError *error) {
      if (error) {
        NSLog(@"Error sending request");
      }
    }];
  }
}

- (void)pan:(UIPanGestureRecognizer *)panRecognizer {
  switch (panRecognizer.state) {
    case UIGestureRecognizerStateBegan: {
      _lastPoint = CGPointZero;
      break;
    }
    case UIGestureRecognizerStateChanged: {
      CGPoint point = [panRecognizer translationInView:self.view];
      CGPoint diff = CGPointMake(-(point.x - _lastPoint.x), -(point.y - _lastPoint.y));
      ETGTranslateViewportMessage *message = [[ETGTranslateViewportMessage alloc] initWithTranslation:diff];
      [message sendWithChannel:_peerChannel completed:^(NSError *error) {
        if (error) {
          NSLog(@"Error sending request");
        }
      }];
      _lastPoint = point;
      break;
    }
    case UIGestureRecognizerStateEnded: {
      _lastPoint = CGPointZero;
      break;
    }
    default:
      break;
  }
}

- (void)sendDeviceInfo {
  CGSize size = [[UIScreen mainScreen] bounds].size;
  CGFloat scale = [[UIScreen mainScreen] scale];
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  NSDictionary *deviceInfo = @{
    @"width": @(size.width),
    @"height": @(size.height),
    @"scale": @(scale),
    @"orientation": @(orientation),
    @"name": [[UIDevice currentDevice] name],
    @"device": [[UIDevice currentDevice] model],
    @"os": [[UIDevice currentDevice] systemVersion],
  };

  ETGDeviceInfoMessage *message = [[ETGDeviceInfoMessage alloc] initWithDeviceInfo:deviceInfo];
  [message sendWithChannel:_peerChannel completed:NULL];
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel
    shouldAcceptFrameOfType:(uint32_t)type
                        tag:(uint32_t)tag
                payloadSize:(uint32_t)payloadSize {
  if (channel != _peerChannel) {
    // A previous channel that has been canceled but not yet ended. Ignore.
    return NO;
  }

  if (type != kETGMessageTypeImage) {
    NSLog(@"Unexpected frame of type %u", type);
    [_peerChannel close];
    _peerChannel = nil;
    return NO;
  }
  return YES;
}

// Invoked when a new frame has arrived on a channel.
- (void)ioFrameChannel:(PTChannel*)channel
 didReceiveFrameOfType:(uint32_t)type
                   tag:(uint32_t)tag
               payload:(dispatch_data_t)payload {
  //NSLog(@"didReceiveFrameOfType: %u, %u, %@", type, tag, payload);
  if (type == kETGMessageTypeImage) {
    ETGImageMessage *message = [[ETGImageMessage alloc] initWithPayload:payload];
    NSData *imageData =[message data];
    UIImage * image = [UIImage imageWithData:imageData];
    if (!image) {
      NSLog(@"Null image with data");
      NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"image.png"];
      NSLog(@"Debug output at %@", path);
      [[message data] writeToFile:path  atomically:YES];
    }
    if (image) {
      [_imageView setImage:image];
    }
  }
}

// Invoked when the channel closed. If it closed because of an error, *error* is
// a non-nil NSError object.
- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
  if (error) {
    NSLog(@"Error occurred while ending: %@", error);
    return;
  }
  NSLog(@"Disconnected");
}

// For listening channels, this method is invoked when a new connection has been
// accepted.
- (void)ioFrameChannel:(PTChannel*)channel
   didAcceptConnection:(PTChannel*)otherChannel
           fromAddress:(PTAddress*)address {
  // Cancel any other connection. We are FIFO, so the last connection
  // established will cancel any previous connection and "take its place".
  if (_peerChannel) {
    [_peerChannel cancel];
    _peerChannel = nil;
  }

  // Weak pointer to current connection. Connection objects live by themselves
  // (owned by its parent dispatch queue) until they are closed.
  _peerChannel = otherChannel;
  _peerChannel.userInfo = address;
  NSLog(@"Connected to %@", address);

  // Send initial packet with device info.
  [self sendDeviceInfo];
}



@end
