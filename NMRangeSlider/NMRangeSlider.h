//
//  RangeSlider.h
//  RangeSlider
//
//  Created by Murray Hughes on 04/08/2012
//  Copyright 2011 Null Monkey Pty Ltd. All rights reserved.
//
// Inspried by: https://github.com/buildmobile/iosrangeslider

#import <UIKit/UIKit.h>

@interface NMRangeSlider : UIControl

// default 0.0
@property(assign, nonatomic) float minimumValue;

// default 1.0
@property(assign, nonatomic) float maximumValue;

// default 0.0. This is the minimum distance between between the upper and lower values
@property(assign, nonatomic) float minimumRange;

// default 0.0 (disabled)
@property(assign, nonatomic) float stepValue;

// If NO the slider will move freely with the tounch. When the touch ends, the value will snap to the nearest step value
// If YES the slider will stay in its current position until it reaches a new step value.
// default NO
@property(assign, nonatomic) BOOL stepValueContinuously;

// defafult YES, indicating whether changes in the sliders value generate continuous update events.
@property(assign, nonatomic) BOOL continuous;

// default 0.0. this value will be pinned to min/max
@property(assign, nonatomic) float lowerValue;

// default 1.0. this value will be pinned to min/max
@property(assign, nonatomic) float upperValue;

// center location for the lower handle control
@property(readonly, nonatomic) CGPoint lowerCenter;

// center location for the upper handle control
@property(readonly, nonatomic) CGPoint upperCenter;

// maximum value for left thumb
@property(assign, nonatomic) float lowerMaximumValue;

// minimum value for right thumb
@property(assign, nonatomic) float upperMinimumValue;

// default nil. Specifies how far apart the centers of the handles are when they reach the minimum range. Use this, for example,
// to have the handles just touch at the minimum range by setting this value to one handle width.
@property (strong, nonatomic) NSNumber *minimumRangeOffset;

// default NO. If YES, lower slider will push upper slider (and vise versa) when miminum range reached
@property (assign, nonatomic) BOOL pushEnabled;

// default NO. If YES, long press on handle enables touch scaling, which can be used to provide
// a fine-tuning mode.
@property (assign, nonatomic) BOOL longPressScalesTouches;

// default 0.1. Scale factor used when long press scaling is active
@property (assign, nonatomic) float touchScale;

// returns YES if touch scaling is currently active
@property (readonly, assign, nonatomic) float touchScalingActive;

// defualt nil. View used as a background behind the touched handle to highlight
// long press mode. View's size should be bigger than the
@property (retain, nonatomic) UIView *touchScalingBackgroundView;

@property (assign, nonatomic) BOOL lowerHandleHidden;
@property (assign, nonatomic) BOOL upperHandleHidden;

// Images, these should be set before the control is displayed.
// If they are not set, then the default images are used.
// eg viewDidLoad


//Probably should add support for all control states... Anyone?

@property(retain, nonatomic) UIImage* lowerHandleImageNormal;
@property(retain, nonatomic) UIImage* lowerHandleImageHighlighted;

@property(retain, nonatomic) UIImage* upperHandleImageNormal;
@property(retain, nonatomic) UIImage* upperHandleImageHighlighted;

@property(retain, nonatomic) UIImage* trackImage;

// track image when lower value is higher than the upper value (eg. when minimum range is negative
@property(retain, nonatomic) UIImage* trackCrossedOverImage;

@property(retain, nonatomic) UIImage* trackBackgroundImage;

//Setting the lower/upper values with an animation :-)
- (void)setLowerValue:(float)lowerValue animated:(BOOL) animated;

- (void)setUpperValue:(float)upperValue animated:(BOOL) animated;

- (void)setLowerValue:(float)lowerValue upperValue:(float)upperValue animated:(BOOL)animated;

@end
