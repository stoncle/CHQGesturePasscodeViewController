//
//  KKGestureLockView.m
//  KKGestureLockView
//
//  Created by Luke on 8/5/13.
//  Copyright (c) 2013 geeklu. All rights reserved.
//

#import "CHQGestureLockPreviewView.h"
const static NSUInteger kNumberOfNodes = 9;
const static NSUInteger kNodesPerRow = 3;
const static CGFloat kNodeDefaultWidth = 10;
const static CGFloat kNodeDefaultHeight = 10;
const static float kGapBetweenNode = 7;

const static CGFloat kTrackedLocationInvalidInContentView = -1.0;


@interface CHQGestureLockPreviewView (){
    struct {
        unsigned int didBeginWithPasscode :1;
        unsigned int didEndWithPasscode : 1;
        unsigned int didCanceled : 1;
    } _delegateFlags;
}

@property (nonatomic, strong) UIView *contentView;

//Implement nodes with buttons
@property (nonatomic, assign) CGSize labelSize;
@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) NSMutableArray *selectedLabels;

@property (nonatomic, assign) CGPoint trackedLocationInContentView;

@end

@implementation CHQGestureLockPreviewView

- (float)getGapBetweenNote
{
    return kGapBetweenNode;
}
- (NSUInteger)getNodesPerRow
{
    return kNodesPerRow;
}
- (float)getNodeWidth
{
    return kNodeDefaultWidth;
}

#pragma mark -
#pragma mark Private Methods


- (void)_lockViewInitialize{
    self.backgroundColor = [UIColor clearColor];
    
    self.contentInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    self.contentView = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.bounds, self.contentInsets)];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentView];
    
    self.labelSize = CGSizeMake(kNodeDefaultWidth, kNodeDefaultHeight);
    
    
    self.numberOfGestureNodes = kNumberOfNodes;
    self.gestureNodesPerRow = kNodesPerRow;
    
    self.selectedLabels = [NSMutableArray array];
    
    self.trackedLocationInContentView = CGPointMake(kTrackedLocationInvalidInContentView, kTrackedLocationInvalidInContentView);
}

- (void)updateLabelsColor:(NSArray *)coloredButton
{
    int j = 0;
    for(j=0; j<coloredButton.count; j++)
    {
        UILabel *label = [_labels objectAtIndex:[[coloredButton objectAtIndex:j] intValue]];
        label.backgroundColor = [UIColor blackColor];
    }
}
- (void)resetLabelsColor
{
    int j = 0;
    for(j=0; j<_labels.count; j++)
    {
        UILabel *label = [_labels objectAtIndex:j];
        label.backgroundColor = [UIColor clearColor];
    }
}


#pragma mark -
#pragma mark UIView Overrides
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self _lockViewInitialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self _lockViewInitialize];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.contentView.frame = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
    CGFloat horizontalNodeMargin = kGapBetweenNode;
    CGFloat verticalNodeMargin = kGapBetweenNode;
    for (int i = 0; i < self.numberOfGestureNodes ; i++) {
        int row = i / self.gestureNodesPerRow;
        int column = i % self.gestureNodesPerRow;
        UILabel *label = [self.labels objectAtIndex:i];
        label.frame = CGRectMake(floorf((self.labelSize.width + horizontalNodeMargin) * column), floorf((self.labelSize.height + verticalNodeMargin) * row), self.labelSize.width, self.labelSize.height);
    
    }
}


#pragma mark -
#pragma mark Accessors



- (void)setNumberOfGestureNodes:(NSUInteger)numberOfGestureNodes{
    if (_numberOfGestureNodes != numberOfGestureNodes) {
        _numberOfGestureNodes = numberOfGestureNodes;
        
        if (self.labels != nil && [self.labels count] > 0) {
            for (UILabel *label in self.labels) {
                [label removeFromSuperview];
            }
        }
        
        NSMutableArray *labelArray = [NSMutableArray arrayWithCapacity:numberOfGestureNodes];
        for (NSUInteger i = 0; i < numberOfGestureNodes; i++) {
            UILabel *label = [[UILabel alloc]init];
            label.tag = i;
            label.userInteractionEnabled = NO;
            label.frame = CGRectMake(0, 0, self.labelSize.width, self.labelSize.height);
            label.backgroundColor = [UIColor clearColor];
            [label.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [label.layer setBorderWidth:1.0f];
            [label.layer setCornerRadius: 5.0f];
            [labelArray addObject:label];
            [self.contentView addSubview:label];
        }
        self.labels = [labelArray copy];
    }
}
@end
