//
//  ETGAppDelegate.m
//  EntanglementOSX
//
//  Created by Alastair Tse on 10/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGAppDelegate.h"

#import "PTChannel.h"
#import "PTUSBHub.h"
#import "ETGProtocol.h"
#import "ETGMessage.h"
#import "ETGClient.h"
#import "ETGDevice.h"
#import "ETGOSXMainViewController.h"

@interface ETGAppDelegate ()
@property(nonatomic, strong) ETGOSXMainViewController *mainViewController;
@end

@implementation ETGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _mainViewController = [[ETGOSXMainViewController alloc] initWithNibName:@"ETGOSXMainViewController" bundle:nil];
  self.window.contentView = [_mainViewController view];
}

@end
