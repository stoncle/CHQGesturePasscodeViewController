//
//  KKGestureLockView.h
//  KKGestureLockView
//
//  Created by Luke on 8/5/13.
//  Copyright (c) 2013 geeklu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@class CHQGestureLockView;

@protocol CHQGestureLockViewDelegate <NSObject>
@optional
- (void)gestureLockView:(CHQGestureLockView *)gestureLockView didBeginWithPasscode:(NSString *)passcode;

- (void)gestureLockView:(CHQGestureLockView *)gestureLockView didEndWithPasscode:(NSString *)passcode;

- (void)gestureLockView:(CHQGestureLockView *)gestureLockView didCanceledWithPasscode:(NSString *)passcode;
@end

@interface CHQGestureLockView : UIView



@property (nonatomic, strong, readonly) NSArray *buttons;
@property (nonatomic, strong, readonly) NSMutableArray *selectedButtons;

@property (nonatomic, assign) NSUInteger numberOfGestureNodes;
@property (nonatomic, assign) NSUInteger gestureNodesPerRow;

@property (nonatomic, strong) UIImage *normalGestureNodeImage;
@property (nonatomic, strong) UIImage *selectedGestureNodeImage;

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, strong, readonly) UIView *contentView;//the container of the gesture notes
@property (nonatomic, assign) UIEdgeInsets contentInsets;

@property (nonatomic, weak) id<CHQGestureLockViewDelegate> delegate;

- (float)getGapBetweenNote;
- (NSUInteger)getNodesPerRow;
- (float)getNodeWidth;

@end
