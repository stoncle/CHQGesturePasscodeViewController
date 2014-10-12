//
//  GestureAppDelegate.m
//  GesturePasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "GestureAppDelegate.h"
#import "GestureDemoViewController.h"
#import "CHQGesturePasscodeViewController.h"

// Just to test that setting the passcode delegate here works.
// You can uncomment below and comment it inside GestureDemoViewController.
@interface GestureAppDelegate () <CHQGesturePasscodeViewControllerDelegate>

@end

@implementation GestureAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
	
	GestureDemoViewController *demoController = [[GestureDemoViewController alloc] init];
	demoController.title = nil;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: demoController];
//	UITabBarController *navController = [[UITabBarController alloc] init];
//	[navController addChildViewController: demoController];
	self.window.rootViewController = navController;
	[self.window makeKeyAndVisible];
    
//    [GesturePasscodeViewController sharedUser].delegate = self;
//    [GesturePasscodeViewController useKeychain:YES];
	if ([GesturePasscodeViewController doesPasscodeExist] &&
        [GesturePasscodeViewController didPasscodeTimerEnd]) {
        [[GesturePasscodeViewController sharedUser] showLockScreenWithAnimation:YES];
	}
	
    return YES;
}

@end
