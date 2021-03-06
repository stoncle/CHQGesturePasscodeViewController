//
//  CHQGesturePasscodeViewController.m
//  CHQGesturePasscodeViewController
//
//  Created by stoncle on 9/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

#import "CHQGesturePasscodeViewController.h"
#import "CHQGestureKeychainUtils.h"

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define kPasscodeCharWidth [_passcodeCharacter sizeWithAttributes: @{NSFontAttributeName : _passcodeFont}].width
#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width + 60.0f : [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width + 30.0f)
#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].height
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width
#else
// Thanks to Kent Nguyen - https://github.com/kentnguyen
#define kPasscodeCharWidth [_passcodeCharacter sizeWithFont:_passcodeFont].width
#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithFont:_labelFont].width + 60.0f : [_failedAttemptLabel.text sizeWithFont:_labelFont].width + 30.0f)
#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithFont:_labelFont].height
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithFont:_labelFont].width
#endif

@interface GesturePasscodeViewController () <UITextFieldDelegate>
@property (nonatomic, strong) CHQGestureLockView *lockView;
@property (nonatomic, strong) CHQGestureLockPreviewView *lockPreview;
//@property (nonatomic, strong) UIView      *coverView;
@property (nonatomic, strong) UIView      *animatingView;


@property (nonatomic, strong) UILabel     *failedAttemptLabel;
@property (nonatomic, strong) UILabel     *enterPasscodeLabel;

@property (nonatomic, strong) NSString    *tempPasscode;
@property (nonatomic, assign) NSInteger   failedAttempts;

@property (nonatomic, assign) CGFloat     modifierForBottomVerticalGap;
@property (nonatomic, assign) CGFloat     iPadFontSizeModifier;
@property (nonatomic, assign) CGFloat     iPhoneHorizontalGap;

@property (nonatomic, assign) BOOL        usesKeychain;
@property (nonatomic, assign) BOOL        displayedAsModal;
@property (nonatomic, assign) BOOL        displayedAsLockScreen;
@property (nonatomic, assign) BOOL        isCurrentlyOnScreen;
@property (nonatomic, assign) BOOL        isUserConfirmingPasscode;
@property (nonatomic, assign) BOOL        isUserBeingAskedForNewPasscode;
@property (nonatomic, assign) BOOL        isUserTurningPasscodeOff;
@property (nonatomic, assign) BOOL        isUserChangingPasscode;
@property (nonatomic, assign) BOOL        isUserEnablingPasscode;
@property (nonatomic, assign) BOOL        isUserSwitchingBetweenPasscodeModes;// simple/complex
@property (nonatomic, assign) BOOL        timerStartInSeconds;
@end

@implementation GesturePasscodeViewController


#pragma mark - Public, class methods
+ (BOOL)doesPasscodeExist {
	return [[GesturePasscodeViewController sharedUser] _doesPasscodeExist];
}


+ (NSString *)passcode {
	return [[GesturePasscodeViewController sharedUser] _passcode];
}


+ (NSTimeInterval)timerDuration {
	return [[GesturePasscodeViewController sharedUser] _timerDuration];
}


+ (void)saveTimerDuration:(NSTimeInterval)duration {
    [[GesturePasscodeViewController sharedUser] _saveTimerDuration:duration];
}


+ (NSTimeInterval)timerStartTime {
    return [[GesturePasscodeViewController sharedUser] _timerStartTime];
}


+ (void)saveTimerStartTime {
	[[GesturePasscodeViewController sharedUser] _saveTimerStartTime];
}


+ (BOOL)didPasscodeTimerEnd {
	return [[GesturePasscodeViewController sharedUser] _didPasscodeTimerEnd];
}


+ (void)deletePasscodeAndClose {
	[[GesturePasscodeViewController sharedUser] _deletePasscode];
    [[GesturePasscodeViewController sharedUser] _dismissMe];
}


+ (void)deletePasscode {
	[[GesturePasscodeViewController sharedUser] _deletePasscode];
}


+ (void)useKeychain:(BOOL)useKeychain {
    [[GesturePasscodeViewController sharedUser] _useKeychain:useKeychain];
}


#pragma mark - Private methods
- (void)_useKeychain:(BOOL)useKeychain {
    _usesKeychain = useKeychain;
}


- (BOOL)_doesPasscodeExist {
	return [self _passcode].length != 0;
}


- (NSTimeInterval)_timerDuration {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(timerDuration)]) {
        return [self.delegate timerDuration];
    }
    
	NSString *keychainValue =
    [CHQGestureKeychainUtils getPasswordForUsername:_keychainTimerDurationUsername
                               andServiceName:_keychainServiceName
                                        error:nil];
	if (!keychainValue) return -1;
	return keychainValue.doubleValue;
}


- (void)_saveTimerDuration:(NSTimeInterval) duration {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(saveTimerDuration:)]) {
        [self.delegate saveTimerDuration:duration];
        
        return;
    }
    
    [CHQGestureKeychainUtils storeUsername:_keychainTimerDurationUsername
						 andPassword:[NSString stringWithFormat: @"%.6f", duration]
					  forServiceName:_keychainServiceName
					  updateExisting:YES
							   error:nil];
}


- (NSTimeInterval)_timerStartTime {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(timerStartTime)]) {
        return [self.delegate timerStartTime];
    }
    
    NSString *keychainValue =
    [CHQGestureKeychainUtils getPasswordForUsername:_keychainTimerStartUsername
                               andServiceName:_keychainServiceName
                                        error:nil];
	if (!keychainValue) return -1;
	return keychainValue.doubleValue;
}


- (void)_saveTimerStartTime {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(saveTimerStartTime)]) {
        [self.delegate saveTimerStartTime];
        
        return;
    }
    
	[CHQGestureKeychainUtils storeUsername:_keychainTimerStartUsername
						 andPassword:[NSString stringWithFormat: @"%.6f",
                                      [NSDate timeIntervalSinceReferenceDate]]
					  forServiceName:_keychainServiceName
					  updateExisting:YES
							   error:nil];
}


- (BOOL)_didPasscodeTimerEnd {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(didPasscodeTimerEnd)]) {
        return [self.delegate didPasscodeTimerEnd];
    }
    
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	// startTime wasn't saved yet (first app use and it crashed, phone force
	// closed, etc) if it returns -1.
	if (now - [self _timerStartTime] >= [self _timerDuration] ||
        [self _timerStartTime] == -1) return YES;
	return NO;
}


- (void)_deletePasscode {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(deletePasscode)]) {
        [self.delegate deletePasscode];
        
        return;
    }
    
	[CHQGestureKeychainUtils deleteItemForUsername:_keychainPasscodeUsername
							  andServiceName:_keychainServiceName
									   error:nil];
}


- (void)_savePasscode:(NSString *)passcode {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(savePasscode:)]) {
        [self.delegate savePasscode:passcode];
        
        return;
    }
    
    [CHQGestureKeychainUtils storeUsername:_keychainPasscodeUsername
                         andPassword:passcode
                      forServiceName:_keychainServiceName
                      updateExisting:YES
                               error:nil];
}


- (NSString *)_passcode {
	if (!_usesKeychain &&
		[self.delegate respondsToSelector:@selector(passcode)]) {
		return [self.delegate passcode];
	}
	
	return [CHQGestureKeychainUtils getPasswordForUsername:_keychainPasscodeUsername
									  andServiceName:_keychainServiceName
											   error:nil];
}


#pragma mark - View life
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = _backgroundColor;
    
	_failedAttempts = 0;
	_animatingView = [[UIView alloc] initWithFrame: self.view.frame];
	[self.view addSubview: _animatingView];
    
	[self _setupViews];
    [self _setupLabels];
    [self _setupDelegate];
	
    
    [self.view setNeedsUpdateConstraints];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    NSLog(@"layout %@", [self.view performSelector:@selector(recursiveDescription)]);

}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


- (void)_cancelAndDismissMe {
	_isCurrentlyOnScreen = NO;
	_isUserBeingAskedForNewPasscode = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
	_isUserTurningPasscodeOff = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
	[self _resetUI];
	
    if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWillClose)]) {
		[self.delegate performSelector: @selector(passcodeViewControllerWillClose)];
    }
// Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeViewControllerWillClose"
//														object: self
//													  userInfo: nil];
	if (_displayedAsModal) [self dismissViewControllerAnimated:YES completion:nil];
	else if (!_displayedAsLockScreen) [self.navigationController popViewControllerAnimated:YES];
}


- (void)_dismissMe {
    _failedAttempts = 0;
	_isCurrentlyOnScreen = NO;
	[self _resetUI];
	[UIView animateWithDuration: _lockAnimationDuration animations: ^{
		if (_displayedAsLockScreen) {
			if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
				self.view.center = CGPointMake(self.view.center.x * -1.f, self.view.center.y);
			}
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
				self.view.center = CGPointMake(self.view.center.x * 2.f, self.view.center.y);
			}
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
				self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
			}
			else {
				self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
			}
		}
		else {
			// Delete from Keychain
			if (_isUserTurningPasscodeOff) {
				[self _deletePasscode];
			}
			// Update the Keychain if adding or changing passcode
			else {
				[self _savePasscode:_tempPasscode];
                //finalize type switching
			}
		}
	} completion: ^(BOOL finished) {
        if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWillClose)]) {
            [self.delegate performSelector: @selector(passcodeViewControllerWillClose)];
        }
// Or, if you prefer by notifications:
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeViewControllerWillClose"
//															object: self
//														  userInfo: nil];
		if (_displayedAsLockScreen) {
			[self.view removeFromSuperview];
			[self removeFromParentViewController];
		}
        else if (_displayedAsModal) {
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        }
        else if (!_displayedAsLockScreen) {
            [self.navigationController popViewControllerAnimated:NO];
        }
        NSLog(@"%@", self.navigationController.childViewControllers);
	}];
//	[[NSNotificationCenter defaultCenter]
//     removeObserver: self
//     name: UIApplicationDidChangeStatusBarOrientationNotification
//     object: nil];
//	[[NSNotificationCenter defaultCenter]
//     removeObserver: self
//     name: UIApplicationDidChangeStatusBarFrameNotification
//     object: nil];
}


#pragma mark - UI setup
- (void)_setupViews {
//    _coverView = [[UIView alloc] initWithFrame: CGRectZero];
//    _coverView.backgroundColor = _coverViewBackgroundColor;
//    _coverView.frame = self.view.frame;
//    _coverView.userInteractionEnabled = NO;
//    _coverView.tag = _coverViewTag;
//    _coverView.hidden = YES;
//    [[UIApplication sharedApplication].keyWindow addSubview: _coverView];
    
    _lockView = [[CHQGestureLockView alloc]init];
    _lockView.normalGestureNodeImage = [UIImage imageNamed:@"gesture_node_normal.png"];
    _lockView.selectedGestureNodeImage = [UIImage imageNamed:@"gesture_node_selected.png"];
    _lockView.lineColor = [[UIColor orangeColor] colorWithAlphaComponent:0.3];
    _lockView.lineWidth = 5;
    _lockView.contentInsets = UIEdgeInsetsMake(0, -10, 0, 0);
    [_animatingView addSubview:_lockView];
    
    //must set autoresizing to NO so that contraints wont conflict
    _lockView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _lockPreview = [[CHQGestureLockPreviewView alloc]init];
    [_animatingView addSubview:_lockPreview];
    _lockPreview.translatesAutoresizingMaskIntoConstraints = NO;
    
    
}


- (void)_setupLabels {
    
    _enterPasscodeLabel = [[UILabel alloc] initWithFrame: CGRectZero];
	_enterPasscodeLabel.backgroundColor = _enterPasscodeLabelBackgroundColor;
	_enterPasscodeLabel.numberOfLines = 0;
	_enterPasscodeLabel.textColor = _labelTextColor;
	_enterPasscodeLabel.font = _labelFont;
	_enterPasscodeLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _enterPasscodeLabel];
	
	// It is also used to display the "Passcodes did not match" error message
    // if the user fails to confirm the passcode.
	_failedAttemptLabel = [[UILabel alloc] initWithFrame: CGRectZero];
	_failedAttemptLabel.text = @"1 Passcode Failed Attempt";
    _failedAttemptLabel.numberOfLines = 0;
	_failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
	_failedAttemptLabel.hidden = YES;
	_failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
	_failedAttemptLabel.font = _labelFont;
	_failedAttemptLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _failedAttemptLabel];
    
    _enterPasscodeLabel.text = _isUserChangingPasscode ? NSLocalizedStringFromTable(self.enterOldPasscodeString, _localizationTableName, @"") : NSLocalizedStringFromTable(self.enterPasscodeString, _localizationTableName, @"");
    _enterPasscodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_failedAttemptLabel.translatesAutoresizingMaskIntoConstraints = NO;
}


- (void)_setupDelegate
{
    _lockView.delegate = self;
}





- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.view removeConstraints:self.view.constraints];
    
    
    // MARK: Please read
	// The controller works properly on all devices and orientations, but looks odd on iPhone's landscape.
	// Usually, lockscreens on iPhone are kept portrait-only, though. It also doesn't fit inside a modal when landscape.
	// That's why only portrait is selected for iPhone's supported orientations.
	// Modify this to fit your needs.
    
    [_lockView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=30)-[_enterPasscodeLabel]" options:NSLayoutFormatAlignAllLeft metrics:nil views:NSDictionaryOfVariableBindings(_enterPasscodeLabel)]];
    //[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_enterPasscodeLabel]-10-[_lockView]-10-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(_enterPasscodeLabel, _lockView)]];
	
	CGFloat yOffsetFromCenter = -self.view.bounds.size.height * 0.30;
	NSLayoutConstraint *enterPasscodeConstraintCenterX =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
	NSLayoutConstraint *enterPasscodeConstraintCenterY =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeCenterY
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterY
                                multiplier: 1.0f
                                  constant: yOffsetFromCenter];
    [self.view addConstraint: enterPasscodeConstraintCenterX];
    [self.view addConstraint: enterPasscodeConstraintCenterY];
    NSLog(@"%f,%f,%f,%f", _enterPasscodeLabel.frame.origin.x, _enterPasscodeLabel.frame.origin.y, _enterPasscodeLabel.frame.size.width, _enterPasscodeLabel.frame.size.height);
    
    NSLayoutConstraint *lockPreviewWidth =
    [NSLayoutConstraint constraintWithItem:_lockPreview
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0f
                                  constant:_lockPreview.getNodesPerRow * _lockPreview.getNodeWidth +
     _lockPreview.getGapBetweenNote * (_lockPreview.getNodesPerRow-1)];
    NSLayoutConstraint *lockPreviewHeight =
    [NSLayoutConstraint constraintWithItem:_lockPreview
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_lockPreview
                                 attribute:NSLayoutAttributeHeight
                                multiplier:1.0f
                                  constant:0.0f];
    NSLayoutConstraint *lockPreviewConstraintCenterX =
    [NSLayoutConstraint constraintWithItem:_lockPreview
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_animatingView
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0f
                                  constant:0.0f];
    NSLayoutConstraint *lockPreviewPaddingWithEnterLabel =
    [NSLayoutConstraint constraintWithItem:_lockPreview
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_enterPasscodeLabel
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0f
                                  constant:30];
    [self.view addConstraint:lockPreviewWidth];
	[self.view addConstraint:lockPreviewHeight];
	[self.view addConstraint:lockPreviewConstraintCenterX];
	[self.view addConstraint:lockPreviewPaddingWithEnterLabel];
    
    
    NSLayoutConstraint *failedAttemptLabelCenterX =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
    NSLayoutConstraint *failedAttemptLabelY =
    [NSLayoutConstraint constraintWithItem:_failedAttemptLabel
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_enterPasscodeLabel
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0f
                                  constant:50];
	NSLayoutConstraint *failedAttemptLabelWidth =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeWidth
                                 relatedBy: NSLayoutRelationGreaterThanOrEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 1.0f
                                  constant: kFailedAttemptLabelWidth];
	NSLayoutConstraint *failedAttemptLabelHeight =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeHeight
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 1.0f
                                  constant: kFailedAttemptLabelHeight + 6.0f];
	[self.view addConstraint:failedAttemptLabelCenterX];
	[self.view addConstraint:failedAttemptLabelY];
	[self.view addConstraint:failedAttemptLabelWidth];
	[self.view addConstraint:failedAttemptLabelHeight];
    
    
    NSLayoutConstraint *lockViewWidth =
    [NSLayoutConstraint constraintWithItem:_lockView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0f
                                  constant:_lockView.getNodesPerRow * _lockView.getNodeWidth +
                                                _lockView.getGapBetweenNote * (_lockView.getNodesPerRow-1)];
    NSLayoutConstraint *lockViewHeight =
    [NSLayoutConstraint constraintWithItem:_lockView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_lockView
                                 attribute:NSLayoutAttributeHeight
                                multiplier:1.0f
                                  constant:0.0f];

    NSLayoutConstraint *lockViewConstraintCenterX =
    [NSLayoutConstraint constraintWithItem:_lockView
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_animatingView
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0f
                                  constant:0.0f];
    NSLayoutConstraint *lockViewPaddingWithFailedLabel =
    [NSLayoutConstraint constraintWithItem:_lockView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_failedAttemptLabel
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0f
                                  constant:30];
    [self.view addConstraint:lockViewWidth];
    [self.view addConstraint:lockViewHeight];
    [self.view addConstraint:lockViewConstraintCenterX];
    [self.view addConstraint:lockViewPaddingWithFailedLabel];
    NSLog(@"%f,%f,%f,%f",self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    NSLog(@"%f,%f,%f,%f",_lockView.frame.origin.x, _lockView.frame.origin.y, _lockView.frame.size.width, _lockView.frame.size.height);
    
    
	
	
    
//    NSLog(@"constraints %@", self.view.constraints);
//    NSLog(@"_passcodeTextField %@", _passcodeTextField.constraints);
}


#pragma mark - Displaying
//- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle {
- (void)showLockScreenWithAnimation:(BOOL)animated {

	[self _prepareAsLockScreen];
    
	// In case the user leaves the app while the lockscreen is already active.
	if (!_isCurrentlyOnScreen) {
		// Usually, the app's window is the first on the stack. I'm doing this because if an alertView or actionSheet
		// is open when presenting the lockscreen causes problems, because the av/as has it's own window that replaces the keyWindow
		// and due to how Apple handles said window internally.
		// Currently the lockscreen appears behind the av/as, which is the best compromise for now.
		// You can read and/or give a hand following one of the links below
		// http://stackoverflow.com/questions/19816142/uialertviews-uiactionsheets-and-keywindow-problems
		// https://github.com/rolandleth/GesturePasscodeViewController/issues/16
		// Usually not more than one window is needed, but your needs may vary; modify below.
		// Also, in case the control doesn't work properly,
		// try it with .keyWindow before anything else, it might work.
		UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
//		UIWindow *mainWindow = [UIApplication sharedApplication].windows[0];
//        if([mainWindow.rootViewController.childViewControllers containsObject:self])
//        {
//            return;
//        }
		[mainWindow addSubview: self.view];
		[mainWindow.rootViewController addChildViewController: self];
        NSLog(@"%@", mainWindow.rootViewController);
        NSLog(@"%@", mainWindow.rootViewController.childViewControllers);
		// All this hassle because a view added to UIWindow does not rotate automatically
		// and if we would have added the view anywhere else, it wouldn't display properly
		// (having a modal on screen when the user leaves the app, for example).
		[self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
		CGPoint newCenter;
		if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
			self.view.center = CGPointMake(self.view.center.x * -1.f, self.view.center.y);
			newCenter = CGPointMake(mainWindow.center.x - self.navigationController.navigationBar.frame.size.height / 2,
									mainWindow.center.y);
		}
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
			self.view.center = CGPointMake(self.view.center.x * 2.f, self.view.center.y);
			newCenter = CGPointMake(mainWindow.center.x + self.navigationController.navigationBar.frame.size.height / 2,
									mainWindow.center.y);
		}
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
			newCenter = CGPointMake(mainWindow.center.x,
									mainWindow.center.y - self.navigationController.navigationBar.frame.size.height / 2);
            NSLog(@"%f,%f", newCenter.x, newCenter.y);
            NSLog(@"%f,%f", mainWindow.center.x, mainWindow.center.y);
		}
		else {
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
			newCenter = CGPointMake(mainWindow.center.x,
									mainWindow.center.y + self.navigationController.navigationBar.frame.size.height / 2);
		}
        
        if (![[UIApplication sharedApplication] isStatusBarHidden]) {
            newCenter.y += MIN([[UIApplication sharedApplication] statusBarFrame].size.height,
                               [[UIApplication sharedApplication] statusBarFrame].size.width);
        }
        
		if (animated) {
			[UIView animateWithDuration: _lockAnimationDuration animations: ^{
				self.view.center = newCenter;
			}];
		}
        else {
			self.view.center = newCenter;
		}
		
		// Add nav bar & logout button if specified
//		if (hasLogout) {
//			// Navigation Bar with custom UI
//			self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, mainWindow.frame.origin.y, 320, 64)];
//            self.navBar.tintColor = self.navigationTintColor;
//			if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
//				self.navBar.barTintColor = self.navigationBarTintColor;
//				self.navBar.translucent  = self.navigationBarTranslucent;
//			}
//			if (self.navigationTitleColor) {
//				self.navBar.titleTextAttributes =
//				@{ NSForegroundColorAttributeName : self.navigationTitleColor };
//			}
//			
//			// Navigation item
//			UIBarButtonItem *leftButton =
//            [[UIBarButtonItem alloc] initWithTitle:logoutTitle
//                                             style:UIBarButtonItemStyleDone
//                                            target:self
//                                            action:@selector(_logoutWasPressed)];
//			UINavigationItem *item =
//            [[UINavigationItem alloc] initWithTitle:self.title];
//			item.leftBarButtonItem = leftButton;
//			item.hidesBackButton = YES;
//			
//			[self.navBar pushNavigationItem:item animated:NO];
//			[mainWindow addSubview:self.navBar];
//		}
		
		_isCurrentlyOnScreen = YES;
        
	}
}


- (void)_prepareNavigationControllerWithController:(UIViewController *)viewController {
	self.navigationItem.rightBarButtonItem =
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
												  target:self
												  action:@selector(_cancelAndDismissMe)];
	
	if (!_displayedAsModal) {
		[viewController.navigationController pushViewController:self
													   animated:YES];
        self.navigationItem.hidesBackButton = _hidesBackButton;
        [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
        
		return;
	}
	UINavigationController *navController =
	[[UINavigationController alloc] initWithRootViewController:self];
	
	// Make sure nav bar for logout is off the screen
	[self.navBar removeFromSuperview];
	self.navBar = nil;
	
	// Customize navigation bar
	// Make sure UITextAttributeTextColor is not set to nil
	// barTintColor & translucent is only called on iOS7+
	navController.navigationBar.tintColor = self.navigationTintColor;
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		navController.navigationBar.barTintColor = self.navigationBarTintColor;
		navController.navigationBar.translucent = self.navigationBarTranslucent;
	}
	if (self.navigationTitleColor) {
		navController.navigationBar.titleTextAttributes =
		@{ NSForegroundColorAttributeName : self.navigationTitleColor };
	}
	
	[viewController presentViewController:navController
								 animated:YES
							   completion:nil];
	[self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}


- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController
										asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForEnablingPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = NSLocalizedStringFromTable(self.enablePasscodeString, _localizationTableName, @"");
}


- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController
										asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForChangingPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = NSLocalizedStringFromTable(self.changePasscodeString, _localizationTableName, @"");
}


- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController
                                         asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForTurningOffPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = NSLocalizedStringFromTable(self.turnOffPasscodeString, _localizationTableName, @"");
}


#pragma mark - Preparing
- (void)_prepareAsLockScreen {
    // In case the user leaves the app while changing/disabling Passcode.
    if (_isCurrentlyOnScreen && !_displayedAsLockScreen) {
        [self _cancelAndDismissMe];
    }
    _displayedAsLockScreen = YES;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
    
	[self _resetUI];
}


- (void)_prepareForChangingPasscode {
	_isCurrentlyOnScreen = YES;
	_displayedAsLockScreen = NO;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
    
	[self _resetUI];
}


- (void)_prepareForTurningOffPasscode {
	_isCurrentlyOnScreen = YES;
	_displayedAsLockScreen = NO;
	_isUserTurningPasscodeOff = YES;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
    [_lockPreview resetLabelsColor];
    _lockPreview.hidden = YES;
    
	[self _resetUI];
}


- (void)_prepareForEnablingPasscode {
	_isCurrentlyOnScreen = YES;
	_displayedAsLockScreen = NO;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = YES;
    _isUserSwitchingBetweenPasscodeModes = NO;
    [_lockPreview resetLabelsColor];
    _lockPreview.hidden = NO;
	[self _resetUI];
}


#pragma mark - CHQGestureLockDelegate
- (void)gestureLockView:(CHQGestureLockView *)gestureLockView didBeginWithPasscode:(NSString *)passcode{
    NSLog(@"%@",passcode);
    
}

- (void)gestureLockView:(CHQGestureLockView *)gestureLockView didEndWithPasscode:(NSString *)passcode{
    NSLog(@"%@", passcode);
    
    [self performSelector: @selector(_validatePasscode:)
               withObject: passcode
               afterDelay: 0.15];
}

#pragma mark - Validation



- (BOOL)_validatePasscode:(NSString *)typedString {
    NSString *savedPasscode = [self _passcode];
    // Entering from Settings. If savedPasscode is empty, it means
    // the user is setting a new Passcode now, or is changing his current Passcode.
    if ((_isUserChangingPasscode  || savedPasscode.length == 0) && !_isUserTurningPasscodeOff) {
        // Either the user is being asked for a new passcode, confirmation comes next,
        // either he is setting up a new passcode, confirmation comes next, still.
        // We need the !_isUserConfirmingPasscode condition, because if he's adding a new Passcode,
        // then savedPasscode is still empty and the condition will always be true, not passing this point.
        if ((_isUserBeingAskedForNewPasscode || savedPasscode.length == 0) && !_isUserConfirmingPasscode) {
            _tempPasscode = typedString;
            NSArray *passArr = [typedString componentsSeparatedByString:@","];
            [_lockPreview updateLabelsColor:passArr];
            // The delay is to give time for the last bullet to appear
            [self performSelector:@selector(_askForConfirmationPasscode)
                       withObject:nil
                       afterDelay:0.15f];
        }
        // User entered his Passcode correctly and we are at the confirming screen.
        else if (_isUserConfirmingPasscode) {
            // User entered the confirmation Passcode correctly
            if ([typedString isEqualToString: _tempPasscode]) {
                [self _dismissMe];
            }
            // User entered the confirmation Passcode incorrectly, start over.
            else {
                [self performSelector:@selector(_reAskForNewPasscode)
                           withObject:nil
                           afterDelay:_slideAnimationDuration];
            }
        }
        // Changing Passcode and the entered Passcode is correct.
        else if ([typedString isEqualToString:savedPasscode]){
            [self performSelector:@selector(_askForNewPasscode)
                       withObject:nil
                       afterDelay:_slideAnimationDuration];
            _failedAttempts = 0;
        }
        // Acting as lockscreen and the entered Passcode is incorrect.
        else {
            [self performSelector: @selector(_denyAccess)
                       withObject: nil
                       afterDelay: _slideAnimationDuration];
            return NO;
        }
    }
    // App launch/Turning passcode off: Passcode OK -> dismiss, Passcode incorrect -> deny access.
    else {
        if ([typedString isEqualToString: savedPasscode]) {
            if ([self.delegate respondsToSelector: @selector(passcodeWasEnteredSuccessfully)]) {
                [self.delegate performSelector: @selector(passcodeWasEnteredSuccessfully)];
            }
//Or, if you prefer by notifications:
//            [[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeWasEnteredSuccessfully"
//                                                                object: self
//                                                              userInfo: nil];
            [self _dismissMe];
        }
        else {
            [self performSelector: @selector(_denyAccess)
                       withObject: nil
                       afterDelay: _slideAnimationDuration];
            return NO;
        }
    }
    
    return YES;
}


#pragma mark - Actions
- (void)_askForNewPasscode {
	_isUserBeingAskedForNewPasscode = YES;
	_isUserConfirmingPasscode = NO;
    [_lockPreview resetLabelsColor];
    
    // Update layout considering type
    [self.view setNeedsUpdateConstraints];
    
	_failedAttemptLabel.hidden = YES;
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(_resetUI) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: _slideAnimationDuration];
	[transition setTimingFunction:
     [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	//[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)_reAskForNewPasscode {
	_isUserBeingAskedForNewPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_tempPasscode = @"";
    [_lockPreview resetLabelsColor];
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(_resetUIForReEnteringNewPasscode)
               withObject: nil
               afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: _slideAnimationDuration];
	[transition setTimingFunction:
     [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	//[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)_askForConfirmationPasscode {
	_isUserBeingAskedForNewPasscode = NO;
	_isUserConfirmingPasscode = YES;
	_failedAttemptLabel.hidden = YES;
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(_resetUI) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: _slideAnimationDuration];
	[transition setTimingFunction:
     [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	//[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)_denyAccess {
    
	_failedAttempts++;
	
	if (_maxNumberOfAllowedFailedAttempts > 0 &&
		_failedAttempts == _maxNumberOfAllowedFailedAttempts &&
		[self.delegate respondsToSelector: @selector(maxNumberOfFailedAttemptsReached)]) {
		[self.delegate maxNumberOfFailedAttemptsReached];
    }
//	Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"maxNumberOfFailedAttemptsReached"
//														object: self
//													  userInfo: nil];
	
	if (_failedAttempts == 1) {
        _failedAttemptLabel.text =
        NSLocalizedStringFromTable(@"1 Passcode Failed Attempt", _localizationTableName, @"");
    }
	else {
		_failedAttemptLabel.text = [NSString stringWithFormat: NSLocalizedStringFromTable(@"%i Passcode Failed Attempts", _localizationTableName, @""), _failedAttempts];
	}
	_failedAttemptLabel.layer.cornerRadius = kFailedAttemptLabelHeight * 0.65f;
	_failedAttemptLabel.clipsToBounds = true;
	_failedAttemptLabel.hidden = NO;
}


- (void)_logoutWasPressed {
	// Notify delegate that logout button was pressed
	if ([self.delegate respondsToSelector: @selector(logoutButtonWasPressed)]) {
		[self.delegate logoutButtonWasPressed];
	}
}


- (void)_resetUI {
	_failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
	_failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
    if (_failedAttempts == 0) _failedAttemptLabel.hidden = YES;
	
	if (_isUserConfirmingPasscode) {
        _lockPreview.hidden = NO;
		if (_isUserEnablingPasscode) {
            _enterPasscodeLabel.text = NSLocalizedStringFromTable(self.reenterPasscodeString, _localizationTableName, @"");
        }
		else if (_isUserChangingPasscode) {
            _enterPasscodeLabel.text = NSLocalizedStringFromTable(self.reenterNewPasscodeString, _localizationTableName, @"");
        }
	}
	else if (_isUserBeingAskedForNewPasscode) {
        _lockPreview.hidden = NO;
        
		if (_isUserEnablingPasscode || _isUserChangingPasscode) {
			_enterPasscodeLabel.text = NSLocalizedStringFromTable(self.enterNewPasscodeString, _localizationTableName, @"");
		}
	}
	else {
        if (_isUserChangingPasscode) {
            _lockPreview.hidden = YES;
            _enterPasscodeLabel.text = NSLocalizedStringFromTable(self.enterOldPasscodeString, _localizationTableName, @"");
        } else {
            if(_isUserEnablingPasscode)
            {
                _lockPreview.hidden = NO;
            }
            else
            {
                _lockPreview.hidden = YES;
            }
            _enterPasscodeLabel.text = NSLocalizedStringFromTable(self.enterPasscodeString, _localizationTableName, @"");
        }
    }
	
	// Make sure nav bar for logout is off the screen
	[self.navBar removeFromSuperview];
	self.navBar = nil;
    
}


- (void)_resetUIForReEnteringNewPasscode {
	// If there's no passcode saved in Keychain,
    // the user is adding one for the first time, otherwise he's changing his passcode.
	NSString *savedPasscode = [CHQGestureKeychainUtils getPasswordForUsername: _keychainPasscodeUsername
														 andServiceName: _keychainServiceName
																  error: nil];
	_enterPasscodeLabel.text = savedPasscode.length == 0 ? NSLocalizedStringFromTable(self.enterPasscodeString, _localizationTableName, @"") : NSLocalizedStringFromTable(self.enterNewPasscodeString, _localizationTableName, @"");
	
	_failedAttemptLabel.hidden = NO;
	_failedAttemptLabel.text = NSLocalizedStringFromTable(@"Passcodes did not match. Try again.", _localizationTableName, @"");
	_failedAttemptLabel.backgroundColor = [UIColor clearColor];
	_failedAttemptLabel.layer.borderWidth = 0;
	_failedAttemptLabel.layer.borderColor = [UIColor clearColor].CGColor;
	_failedAttemptLabel.textColor = _labelTextColor;
}



#pragma mark - Notification Observers
- (void)_applicationDidEnterBackground {
	if ([self _doesPasscodeExist]) {
		// Without animation because otherwise it won't come down fast enough,
		// so inside iOS' multitasking view the app won't be covered by anything.
		if ([self _timerDuration] <= 0) {
            // This is here and the rest in willEnterForeground because when self is pushed
            // instead of presented as a modal,
            // the app would be visible from the multitasking view.
            if (_isCurrentlyOnScreen && !_displayedAsModal) return;
            
            [self showLockScreenWithAnimation:NO];
        }
		else {
//			_coverView.hidden = NO;
//			if (![[UIApplication sharedApplication].keyWindow viewWithTag: _coverViewTag])
//				[[UIApplication sharedApplication].keyWindow addSubview: _coverView];
		}
	}
}


- (void)_applicationDidBecomeActive {
//	_coverView.hidden = YES;
}


- (void)_applicationWillEnterForeground {
    static int i = 0;
    i++;
    NSLog(@"%d", i);
	if ([self _doesPasscodeExist] &&
		[self _didPasscodeTimerEnd]) {
        // This is here instead of didEnterBackground because when self is pushed
        // instead of presented as a modal,
        // the app would be visible from the multitasking view.
        if (!_displayedAsModal && !_displayedAsLockScreen && _isCurrentlyOnScreen) {
            //if set animated yes, then u must set delay too.
            [self.navigationController popViewControllerAnimated:NO];
            NSArray *conArr = self.navigationController.childViewControllers;
            NSLog(@"%@", self);
            if([conArr containsObject:self])
            {
                return;
            }
            

            // This is like this because it screws up the navigation stack otherwise
            //must set delay if nav controller pop view animated! or the passcode would be covered by nav controller page.
            [self performSelector:@selector(showLockScreenWithAnimation:)
                       withObject:@(NO)
                       afterDelay:0.0];
//            objc_msgSend(self, @selector(showLockScreenWithAnimation:withLogout:andLogoutTitle:), YES, NO, nil);
//            [[GesturePasscodeViewController sharedUser] showLockScreenWithAnimation:YES
//                                                                     withLogout:NO
//                                                                 andLogoutTitle:nil];
        }
        else {
            NSArray *conArr = self.navigationController.childViewControllers;
            NSLog(@"%@", self);
            if([conArr containsObject:self])
            {
                return;
            }
            [self showLockScreenWithAnimation:NO];
        }
	}
}

- (void)_applicationWillResignActive {
	if ([self _doesPasscodeExist]) {
		[self _saveTimerStartTime];
	}
}


#pragma mark - Init
+ (instancetype)sharedUser {
    __strong static GesturePasscodeViewController *sharedObject = nil;
    
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedObject = [[GesturePasscodeViewController alloc] init];
	});
	
	return sharedObject;
}


- (id)init {
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
//    if (self) {
//        [self _commonInit];
//    }
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        [self _commonInit];
//    }
    return self;
}


- (void)_commonInit {
	[self _loadDefaults];
	[self _addObservers];
}


- (void)_loadDefaults {
    [self _loadMiscDefaults];
    [self _loadStringDefaults];
    [self _loadGapDefaults];
    [self _loadFontDefaults];
    [self _loadColorDefaults];
    [self _loadKeychainDefaults];
}


- (void)_loadMiscDefaults {
//    _coverViewTag = 994499;
    _lockAnimationDuration = 0.25;
    _slideAnimationDuration = 0.15;
    _maxNumberOfAllowedFailedAttempts = 0;
    _usesKeychain = YES;
    _displayedAsModal = YES;
    _hidesBackButton = YES;
    _passcodeCharacter = @"\u2014"; // A longer "-";
    _localizationTableName = @"GesturePasscodeViewController";
}


- (void)_loadStringDefaults {
    self.enterOldPasscodeString = @"Enter your old passcode";
    self.enterPasscodeString = @"Enter your passcode";
    self.enablePasscodeString = @"Enable Passcode";
    self.changePasscodeString = @"Change Passcode";
    self.turnOffPasscodeString = @"Turn Off Passcode";
    self.reenterPasscodeString = @"Re-enter your passcode";
    self.reenterNewPasscodeString = @"Re-enter your new passcode";
    self.enterNewPasscodeString = @"Enter your new passcode";
}


- (void)_loadGapDefaults {
    _iPadFontSizeModifier = 1.5;
    _iPhoneHorizontalGap = 40.0;
    _horizontalGap = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? _iPhoneHorizontalGap * _iPadFontSizeModifier : _iPhoneHorizontalGap;
    _verticalGap = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 60.0f : 25.0f;
    _modifierForBottomVerticalGap = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.6f : 3.0f;
    _failedAttemptLabelGap = _verticalGap * _modifierForBottomVerticalGap - 2.0f;
    _passcodeOverlayHeight = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 96.0f : 40.0f;
}


- (void)_loadFontDefaults {
    _labelFontSize = 15.0;
    _passcodeFontSize = 33.0;
    _labelFont = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
    [UIFont fontWithName: @"AvenirNext-Regular" size:_labelFontSize * _iPadFontSizeModifier] :
    [UIFont fontWithName: @"AvenirNext-Regular" size:_labelFontSize];
    _passcodeFont = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
    [UIFont fontWithName: @"AvenirNext-Regular" size: _passcodeFontSize * _iPadFontSizeModifier] :
    [UIFont fontWithName: @"AvenirNext-Regular" size: _passcodeFontSize];
}


- (void)_loadColorDefaults {
    // Backgrounds
    _backgroundColor =  [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f];
    _passcodeBackgroundColor = [UIColor clearColor];
//    _coverViewBackgroundColor = [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f];
    _failedAttemptLabelBackgroundColor =  [UIColor colorWithRed:0.8f green:0.1f blue:0.2f alpha:1.000f];
    _enterPasscodeLabelBackgroundColor = [UIColor clearColor];
    
    // Text
    _labelTextColor = [UIColor colorWithWhite:0.31f alpha:1.0f];
    _passcodeTextColor = [UIColor colorWithWhite:0.31f alpha:1.0f];
    _failedAttemptLabelTextColor = [UIColor whiteColor];
}


- (void)_loadKeychainDefaults {
    _keychainPasscodeUsername = @"demoPasscode";
    _keychainTimerStartUsername = @"demoPasscodeTimerStart";
    _keychainServiceName = @"demoServiceName";
    _keychainTimerDurationUsername = @"passcodeTimerDuration";
}


- (void)_addObservers {
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationDidEnterBackground)
     name: UIApplicationDidEnterBackgroundNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationWillResignActive)
     name: UIApplicationWillResignActiveNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationDidBecomeActive)
     name: UIApplicationDidBecomeActiveNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationWillEnterForeground)
     name: UIApplicationWillEnterForegroundNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(statusBarFrameOrOrientationChanged:)
     name:UIApplicationDidChangeStatusBarOrientationNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(statusBarFrameOrOrientationChanged:)
     name:UIApplicationDidChangeStatusBarFrameNotification
     object:nil];
}


#pragma mark - Handling rotation



- (NSUInteger)supportedInterfaceOrientations {
	if (_displayedAsLockScreen)
        return UIInterfaceOrientationMaskAll;
	// I'll be honest and mention I have no idea why this line of code below works.
	// Without it, if you present the passcode view as lockscreen (directly on the window)
	// and then inside of a modal, the orientation will be wrong.
	
	// If you could explain why, I'd be more than grateful :)
    else
        return UIInterfaceOrientationPortraitUpsideDown;
}


// All of the rotation handling is thanks to Håvard Fossli's - https://github.com/hfossli
// answer: http://stackoverflow.com/a/4960988/793916
- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification {
    /*
     This notification is most likely triggered inside an animation block,
     therefore no animation is needed to perform this nice transition.
     */
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}

// And to his AGWindowView: https://github.com/hfossli/AGWindowView
// Without the 'desiredOrientation' method, using showLockscreen in one orientation,
// then presenting it inside a modal in another orientation would display
// the view in the first orientation.
- (UIInterfaceOrientation)desiredOrientation {
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UIInterfaceOrientationMask statusBarOrientationAsMask = UIInterfaceOrientationMaskFromOrientation(statusBarOrientation);
    if(self.supportedInterfaceOrientations & statusBarOrientationAsMask) {
        return statusBarOrientation;
    }
    else {
        if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskPortrait) {
            return UIInterfaceOrientationPortrait;
        }
        else if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeLeft) {
            return UIInterfaceOrientationLandscapeLeft;
        }
        else if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeRight) {
            return UIInterfaceOrientationLandscapeRight;
        }
        else {
            return UIInterfaceOrientationPortraitUpsideDown;
        }
    }
}


- (void)rotateAccordingToStatusBarOrientationAndSupportedOrientations {
	UIInterfaceOrientation orientation = [self desiredOrientation];
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation(orientation);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
	
    [self setIfNotEqualTransform: transform
						   frame: self.view.window.bounds];
}


- (void)setIfNotEqualTransform:(CGAffineTransform)transform frame:(CGRect)frame {
    if(!CGAffineTransformEqualToTransform(self.view.transform, transform)) {
        self.view.transform = transform;
    }
    if(!CGRectEqualToRect(self.view.frame, frame)) {
        self.view.frame = frame;
    }
}


+ (CGFloat)getStatusBarHeight {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        return [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}


CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation) {
    CGFloat angle;
	
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        default:
            angle = 0.0;
            break;
    }
	
    return angle;
}

UIInterfaceOrientationMask UIInterfaceOrientationMaskFromOrientation(UIInterfaceOrientation orientation) {
    return 1 << orientation;
}


@end
