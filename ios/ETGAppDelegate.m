//
//  ETGAppDelegate.m
//  Entanglement
//
//  Created by Alastair Tse on 10/12/2013.
//  Copyright (c) 2013 Alastair Tse. All rights reserved.
//

#import "ETGAppDelegate.h"
#import "ETGViewController.h"

@implementation ETGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [application setStatusBarHidden:YES];
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  _window.rootViewController = [[ETGViewController alloc] init];
  [_window makeKeyAndVisible];
  return YES;
}

@end
