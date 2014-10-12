//
//  GestureAppDelegate.h
//  GesturePasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GesturePasscodeViewController;
@interface GestureAppDelegate : UIResponder <UIApplicationDelegate> {
	GesturePasscodeViewController *_passcodeController;
}

@property (strong, nonatomic) UIWindow *window;

@end
