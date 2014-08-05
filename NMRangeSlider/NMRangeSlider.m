//
//  RangeSlider.m
//  RangeSlider
//
//  Created by Murray Hughes on 04/08/2012
//  Copyright 2011 Null Monkey Pty Ltd. All rights reserved.
//

#import "NMRangeSlider.h"


#define IS_PRE_IOS7() (DeviceSystemMajorVersion() < 7)

NSUInteger DeviceSystemMajorVersion() {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion]
                                       componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
    });
    return _deviceSystemMajorVersion;
}



@interface NMRangeSlider ()
{
    float _lowerTouchOffset;
    float _upperTouchOffset;
    float _stepValueInternal;
    BOOL _haveAddedSubviews;
    CGPoint _touchDownPoint;
}

@property (retain, nonatomic) UIImageView* lowerHandle;
@property (retain, nonatomic) UIImageView* upperHandle;
@property (retain, nonatomic) UIImageView* track;
@property (retain, nonatomic) UIImageView* trackBackground;
@property (retain, nonatomic) UIImageView* pushHandle;
@property (readonly, assign, nonatomic) CGFloat centersOffset;
@property (weak, nonatomic) UILongPressGestureRecognizer *longPressRecognizer;
@property (readwrite, assign, nonatomic) float touchScalingActive;

@end


@implementation NMRangeSlider

#pragma mark -
#pragma mark - Constructors

- (id)init
{
    self = [super init];
    if (self) {
        [self configureView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self configureView];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self configureView];
    }
    
    return self;
}


- (void) configureView
{
    //Setup the default values
    _minimumValue = 0.0;
    _maximumValue = 1.0;
    _minimumRange = 0.0;
    _stepValue = 0.0;
    _stepValueInternal = 0.0;
    _touchScale = 0.1;
    
    _continuous = YES;
    
    _lowerValue = _minimumValue;
    _upperValue = _maximumValue;
    
    _lowerMaximumValue = NAN;
    _upperMinimumValue = NAN;
    _upperHandleHidden = NO;
    _lowerHandleHidden = NO;
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Properties

- (CGPoint) lowerCenter
{
    return _lowerHandle.center;
}

- (CGPoint) upperCenter
{
    return _upperHandle.center;
}

- (void) setLowerValue:(float)lowerValue
{
    [self setLowerValue:lowerValue upperValue:_upperValue];
}

- (void) setUpperValue:(float)upperValue
{
    [self setLowerValue:_lowerValue upperValue:upperValue];
}

- (void)setLowerValue:(float)lowerValue upperValue:(float)upperValue
{
    if(_stepValueInternal > 0) {
        lowerValue = roundf(lowerValue / _stepValueInternal) * _stepValueInternal;
        upperValue = roundf(upperValue / _stepValueInternal) * _stepValueInternal;
    }
    
    lowerValue = MIN(lowerValue, _maximumValue);
    lowerValue = MAX(lowerValue, _minimumValue);
    
    upperValue = MAX(upperValue, _minimumValue);
    upperValue = MIN(upperValue, _maximumValue);

    if (!isnan(_lowerMaximumValue)) {
        lowerValue = MIN(lowerValue, _lowerMaximumValue);
    }

    if (!isnan(_upperMinimumValue)) {
        upperValue = MAX(upperValue, _upperMinimumValue);
    }

    if (upperValue - _minimumRange < _minimumValue) {
        upperValue = MAX(upperValue, lowerValue + _minimumRange);
    } else {
        lowerValue = MIN(lowerValue, upperValue - _minimumRange);
    }

    _lowerValue = lowerValue;
    _upperValue = upperValue;
    
    [self setNeedsLayout];
}

- (void) setLowerValue:(float) lowerValue upperValue:(float) upperValue animated:(BOOL)animated
{
    if((!animated) && (isnan(lowerValue) || lowerValue==_lowerValue) && (isnan(upperValue) || upperValue==_upperValue))
    {
        //nothing to set
        return;
    }
    
    __block void (^setValuesBlock)(void) = ^ {
        
        if (isnan(lowerValue) && isnan(upperValue)) { return; }
        
        if (isnan(lowerValue)) {
            [self setUpperValue:upperValue];
        } else if (isnan(upperValue)) {
            [self setLowerValue:lowerValue];
        } else {
            [self setLowerValue:lowerValue upperValue:upperValue];
        }
        
    };
    
    if(animated)
    {
        [UIView animateWithDuration:0.25  delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             setValuesBlock();
                             [self layoutSubviews];
                             
                         } completion:^(BOOL finished) {
                             
                         }];
        
    }
    else
    {
        setValuesBlock();
    }

}

- (void)setLowerValue:(float)lowerValue animated:(BOOL) animated
{
    [self setLowerValue:lowerValue upperValue:NAN animated:animated];
}

- (void)setUpperValue:(float)upperValue animated:(BOOL) animated
{
    [self setLowerValue:NAN upperValue:upperValue animated:animated];
}

- (void) setLowerHandleHidden:(BOOL)lowerHandleHidden
{
    _lowerHandleHidden = lowerHandleHidden;
    [self setNeedsLayout];
}

- (void) setUpperHandleHidden:(BOOL)upperHandleHidden
{
    _upperHandleHidden = upperHandleHidden;
    [self setNeedsLayout];
}

//ON-Demand images. If the images are not set, then the default values are loaded.

- (UIImage *)trackBackgroundImage
{
    if(_trackBackgroundImage==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-trackBackground"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
            _trackBackgroundImage = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-trackBackground"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 2.0)];
            _trackBackgroundImage = image;
        }
    }
    
    return _trackBackgroundImage;
}

- (UIImage *)trackImage
{
    if(_trackImage==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-track"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
            _trackImage = image;
        }
        else
        {
            
            UIImage* image = [UIImage imageNamed:@"slider-default7-track"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 2.0)];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _trackImage = image;
        }
    }
    
    return _trackImage;
}


- (UIImage *)trackCrossedOverImage
{
    if(_trackCrossedOverImage==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-trackCrossedOver"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
            _trackCrossedOverImage = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-trackCrossedOver"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 2.0)];
            _trackCrossedOverImage = image;
        }
    }
    
    return _trackCrossedOverImage;
}

- (UIImage *)lowerHandleImageNormal
{
    if(_lowerHandleImageNormal==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle"];
            _lowerHandleImageNormal = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _lowerHandleImageNormal = image;
        }

    }
    
    return _lowerHandleImageNormal;
}

- (UIImage *)lowerHandleImageHighlighted
{
    if(_lowerHandleImageHighlighted==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle-highlighted"];
            _lowerHandleImageHighlighted = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _lowerHandleImageNormal = image;
        }
    }
    
    return _lowerHandleImageHighlighted;
}

- (UIImage *)upperHandleImageNormal
{
    if(_upperHandleImageNormal==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle"];
            _upperHandleImageNormal = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _upperHandleImageNormal = image;
        }
    }
    
    return _upperHandleImageNormal;
}

- (UIImage *)upperHandleImageHighlighted
{
    if(_upperHandleImageHighlighted==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle-highlighted"];
            _upperHandleImageHighlighted = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _upperHandleImageNormal = image;
        }
    }
    
    return _upperHandleImageHighlighted;
}

- (void)setPushEnabled:(BOOL)pushEnabled
{
    _pushEnabled = pushEnabled;
    _pushHandle = nil;
}

- (CGFloat)centersOffset
{
    if (!_minimumRangeOffset) { return 0.0; }
    float scale = (CGRectGetWidth(self.frame) - CGRectGetWidth(self.upperHandle.frame)) / (_maximumValue - _minimumValue);
    float minimumRangePoints = _minimumRange * scale;
    return [_minimumRangeOffset floatValue] - minimumRangePoints;
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Math Math Math

//Returns the lower value based on the X potion
//The return value is automatically adjust to fit inside the valid range
-(float)lowerValueForCenterX:(float)x
{
    float _padding = _lowerHandle.frame.size.width/2.0f;
    float value = _minimumValue + (x-_padding) / (self.frame.size.width-(_padding*2)-self.centersOffset) * (_maximumValue - _minimumValue);
    
    value = MAX(value, _minimumValue);
    if (!self.pushEnabled) {
        value = MIN(value, _upperValue - _minimumRange);
    }
    
    return value;
}

-(float)centerXForLowerValue:(float)value
{
    float _padding = _lowerHandle.frame.size.width/2.0f;
    CGFloat x = _padding + (value - _minimumValue) * (self.frame.size.width-(_padding*2)-self.centersOffset) / (_maximumValue - _minimumValue);
    return x;
}

//Returns the upper value based on the X potion
//The return value is automatically adjust to fit inside the valid range
-(float)upperValueForCenterX:(float)x
{
    float _padding = _upperHandle.frame.size.width/2.0;
    
    float value = _minimumValue + (x-_padding-self.centersOffset) / (self.frame.size.width-(_padding*2)-self.centersOffset) * (_maximumValue - _minimumValue);
    
    value = MIN(value, _maximumValue);
    if (!self.pushEnabled) {
        value = MAX(value, _lowerValue+_minimumRange);
    }
    
    return value;
}

-(float)centerXForUpperValue:(float)value
{
    float _padding = _upperHandle.frame.size.width/2.0;
    float x = _padding + self.centersOffset + (value - _minimumValue) * (self.frame.size.width-(_padding*2)-self.centersOffset) / (_maximumValue - _minimumValue);
    return x;
}

//returns the rect for the track image between the lower and upper values based on the trackimage object
- (CGRect)trackRect
{
    CGRect retValue;
    
    UIImage* currentTrackImage = [self trackImageForCurrentValues];
    
    retValue.size = CGSizeMake(currentTrackImage.size.width, currentTrackImage.size.height);
    
    if(currentTrackImage.capInsets.top || currentTrackImage.capInsets.bottom)
    {
        retValue.size.height=self.bounds.size.height;
    }
    
    float lowerHandleWidth = _lowerHandleHidden ? 2.0f : _lowerHandle.frame.size.width;
    float upperHandleWidth = _upperHandleHidden ? 2.0f : _upperHandle.frame.size.width;
    
    float xLowerValue = ((self.bounds.size.width - lowerHandleWidth - self.centersOffset) * (_lowerValue - _minimumValue) / (_maximumValue - _minimumValue))+(lowerHandleWidth/2.0f);
    float xUpperValue = self.centersOffset + ((self.bounds.size.width - upperHandleWidth - self.centersOffset) * (_upperValue - _minimumValue) / (_maximumValue - _minimumValue))+(upperHandleWidth/2.0f);
    
    retValue.origin = CGPointMake(xLowerValue, (self.bounds.size.height/2.0f) - (retValue.size.height/2.0f));
    retValue.size.width = xUpperValue-xLowerValue;

    return retValue;
}

- (UIImage*) trackImageForCurrentValues
{
    if(self.lowerValue <= self.upperValue)
    {
        return self.trackImage;
    }
    else
    {
        return self.trackCrossedOverImage;
    }
}

//returns the rect for the background image
 -(CGRect) trackBackgroundRect
{
    CGRect trackBackgroundRect;
    
    trackBackgroundRect.size = CGSizeMake(_trackBackgroundImage.size.width-4, _trackBackgroundImage.size.height);
    
    if(_trackBackgroundImage.capInsets.top || _trackBackgroundImage.capInsets.bottom)
    {
        trackBackgroundRect.size.height=self.bounds.size.height;
    }
    
    if(_trackBackgroundImage.capInsets.left || _trackBackgroundImage.capInsets.right)
    {
        trackBackgroundRect.size.width=self.bounds.size.width-4;
    }
    
    trackBackgroundRect.origin = CGPointMake(2, (self.bounds.size.height/2.0f) - (trackBackgroundRect.size.height/2.0f));
    
    return trackBackgroundRect;
}

//returms the rect of the tumb image for a given track rect and value
- (CGRect)lowerThumbRectForValue:(float)value handle:(UIImageView*)handle
{
    CGRect thumbRect = [self thumbRectForHandle:handle];
    CGFloat xValue = ((self.bounds.size.width-thumbRect.size.width-self.centersOffset)*((value - _minimumValue) / (_maximumValue - _minimumValue)));
    return [self thumbRectForValue:value handle:handle thumbRect:thumbRect xValue:xValue];
}

- (CGRect)upperThumbRectForValue:(float)value handle:(UIImageView*)handle
{
    CGRect thumbRect = [self thumbRectForHandle:handle];
    float xValue = self.centersOffset + ((self.bounds.size.width-thumbRect.size.width-self.centersOffset)*((value - _minimumValue) / (_maximumValue - _minimumValue)));
    return [self thumbRectForValue:value handle:handle thumbRect:thumbRect xValue:xValue];
}

- (CGRect)thumbRectForHandle:(UIImageView *)handle
{
    CGRect thumbRect;
    UIEdgeInsets insets = handle.image.capInsets;
    
    thumbRect.size = handle.bounds.size;
    
    if(insets.top || insets.bottom)
    {
        thumbRect.size.height=self.bounds.size.height;
    }
    return thumbRect;
}

- (CGRect)thumbRectForValue:(float)value handle:(UIImageView*)handle thumbRect:(CGRect)thumbRect xValue:(CGFloat)xValue
{
    thumbRect.origin = CGPointMake(xValue, (self.bounds.size.height/2.0f) - (thumbRect.size.height/2.0f));
    thumbRect.origin = [self incrementalPointForPoint:thumbRect.origin];
    return thumbRect;
}

- (CGPoint)scaleTouchPoint:(CGPoint)point
{
    CGPoint delta = CGPointMake(point.x - _touchDownPoint.x, point.y - _touchDownPoint.y);
    CGFloat scale = self. self.touchScalingActive ? self.touchScale : 1.0;
    delta.x *= scale;
    delta.y *= scale;
    return CGPointMake(_touchDownPoint.x + delta.x, _touchDownPoint.y + delta.y);
}

- (CGPoint)incrementalPointForPoint:(CGPoint)point
{
    CGFloat scale = [UIScreen mainScreen].scale;
    point.x = round(point.x * scale) / scale;
    point.y = round(point.y * scale) / scale;
    return point;
}

#pragma mark - Touch scaling

- (void)setLongPressScalesTouches:(BOOL)longPressScalesTouches
{
    if (_longPressScalesTouches != longPressScalesTouches) {
        _longPressScalesTouches = longPressScalesTouches;
        if (longPressScalesTouches) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
            self.longPressRecognizer = longPress;
            self.longPressRecognizer.cancelsTouchesInView = NO;
            // reduce allowable movement a lot because in this scenario, we're expecting
            // slider movement and we don't want it to be interpreted as a long press
            self.longPressRecognizer.allowableMovement = 2.0;
            [self addGestureRecognizer:longPress];
        } else {
            [self removeGestureRecognizer:self.longPressRecognizer];
        }
    }
}

- (void)setTouchScalingActive:(float)touchScalingActive
{
    [self setTouchScalingActive:touchScalingActive animated:NO];
}

- (void)setTouchScalingActive:(float)touchScalingActive animated:(BOOL)animated
{
    if (_touchScalingActive != touchScalingActive) {
        _touchScalingActive = touchScalingActive;
        if (touchScalingActive) {
            [self insertPressBackgroundView:self.touchScalingBackgroundView animated:animated];
        } else {
            [self removeLongPressBackgroundView:self.touchScalingBackgroundView animated:animated];
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self setTouchScalingActive:YES animated:YES];
    } else if (longPress.state == UIGestureRecognizerStateEnded) {
        [self setTouchScalingActive:NO animated:YES];
    }
}

- (void)setTouchScalingBackgroundView:(UIView *)longPressBackgroundView
{
    if (_touchScalingBackgroundView != longPressBackgroundView) {
        [self removeLongPressBackgroundView:_touchScalingBackgroundView animated:NO];
        _touchScalingBackgroundView = longPressBackgroundView;
        if (self.touchScalingActive) {
            [self insertPressBackgroundView:longPressBackgroundView animated:NO];
            [self setNeedsLayout];
        }
    }
}

- (void)insertPressBackgroundView:(UIView *)view animated:(BOOL)animated
{
    if (!view) { return; }
    UIView *activeHandle = [self activeHandle];
    if (!activeHandle) { return; }
    view.center = activeHandle.center;
    [self insertSubview:view belowSubview:activeHandle];
    if (animated) {
        CGFloat alpha = view.alpha;
        CGAffineTransform transform = CGAffineTransformMakeScale(0.2, 0.2);
        view.alpha = 0.25;
        view.transform = transform;
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.alpha = alpha;
            view.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)removeLongPressBackgroundView:(UIView *)view animated:(BOOL)animated
{
    if (!view) { return; }
    if (animated) {
        CGFloat alpha = view.alpha;
        [UIView animateWithDuration:0.22 delay:0 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.transform = CGAffineTransformMakeScale(0.5, 0.5);
            view.alpha = 0.0;
        } completion:^(BOOL finished) {
            view.alpha = alpha;
            view.transform = CGAffineTransformIdentity;
            [view removeFromSuperview];
        }];
    } else {
        [view removeFromSuperview];
    }
}

- (void)updateLongPressBackgroundLayout
{
    if (!self.touchScalingActive || !self.touchScalingBackgroundView) { return; }
    UIView *active = [self activeHandle];
    if (!active) { return; }
    // TODO make origin incremental
    self.touchScalingBackgroundView.center = active.center;
    CGRect frame = self.touchScalingBackgroundView.frame;
    frame.origin = [self incrementalPointForPoint:frame.origin];
    self.touchScalingBackgroundView.frame = frame;
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Layout


- (void) addSubviews
{
    //------------------------------
    // Track Brackground
    self.trackBackground = [[UIImageView alloc] initWithImage:self.trackBackgroundImage];
    self.trackBackground.frame = [self trackBackgroundRect];
    
    //------------------------------
    // Track
    self.track = [[UIImageView alloc] initWithImage:[self trackImageForCurrentValues]];
    self.track.frame = [self trackRect];
    
    //------------------------------
    // Lower Handle Handle
    self.lowerHandle = [[UIImageView alloc] initWithImage:self.lowerHandleImageNormal highlightedImage:self.lowerHandleImageHighlighted];
    self.lowerHandle.frame = [self lowerThumbRectForValue:_lowerValue handle:self.lowerHandle];
    
    //------------------------------
    // Upper Handle Handle
    self.upperHandle = [[UIImageView alloc] initWithImage:self.upperHandleImageNormal highlightedImage:self.upperHandleImageHighlighted];
    self.upperHandle.frame = [self upperThumbRectForValue:_upperValue handle:self.upperHandle];
    
    [self addSubview:self.trackBackground];
    [self addSubview:self.track];
    [self addSubview:self.lowerHandle];
    [self addSubview:self.upperHandle];
}


-(void)layoutSubviews
{
    if(_haveAddedSubviews==NO)
    {
        _haveAddedSubviews=YES;
        [self addSubviews];
    }
    
    if(_lowerHandleHidden)
    {
        _lowerValue = _minimumValue;
    }
    
    if(_upperHandleHidden)
    {
        _upperValue = _maximumValue;
    }

    self.trackBackground.frame = [self trackBackgroundRect];
    self.track.frame = [self trackRect];
    self.track.image = [self trackImageForCurrentValues];

    // Layout the lower handle
    self.lowerHandle.frame = [self lowerThumbRectForValue:_lowerValue handle:self.lowerHandle];
    self.lowerHandle.image = self.lowerHandleImageNormal;
    self.lowerHandle.highlightedImage = self.lowerHandleImageHighlighted;
    self.lowerHandle.hidden = self.lowerHandleHidden;
    
    // Layoput the upper handle
    self.upperHandle.frame = [self upperThumbRectForValue:_upperValue handle:self.upperHandle];
    self.upperHandle.image = self.upperHandleImageNormal;
    self.upperHandle.highlightedImage = self.upperHandleImageHighlighted;
    self.upperHandle.hidden= self.upperHandleHidden;
    
    [self updateLongPressBackgroundLayout];
}

- (CGSize)intrinsicContentSize
{
   return CGSizeMake(UIViewNoIntrinsicMetric, MAX(self.lowerHandleImageNormal.size.height, self.upperHandleImageNormal.size.height));
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Touch handling

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    if (inside) { return YES; }
    return [self touchedHandleWithPoint:point] != nil;
}

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    _touchDownPoint = touchPoint;
    
    UIView *touched = [self touchedHandleWithPoint:touchPoint];
    
    if (touched == self.lowerHandle)
    {
        _lowerHandle.highlighted = YES;
        _lowerTouchOffset = touchPoint.x - _lowerHandle.center.x;
        [self bringSubviewToFront:self.lowerHandle];
    } else if (touched == self.upperHandle) {
        _upperHandle.highlighted = YES;
        _upperTouchOffset = touchPoint.x - _upperHandle.center.x;
        [self bringSubviewToFront:self.upperHandle];
    }
    
    _stepValueInternal= _stepValueContinuously ? _stepValue : 0.0f;
    
    return YES;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(!_lowerHandle.highlighted && !_upperHandle.highlighted ){
        return YES;
    }

    CGPoint touchPoint = [touch locationInView:self];
    touchPoint = [self scaleTouchPoint:touchPoint];

    if (self.pushEnabled && !_pushHandle && !(_lowerHandle.highlighted && _upperHandle.highlighted)) {

        CGPoint previousTouchPoint = [touch previousLocationInView:self];
        previousTouchPoint = [self scaleTouchPoint:previousTouchPoint];
        CGFloat distance = touchPoint.x - previousTouchPoint.x;
        if (distance > 0 && _lowerHandle.highlighted) {
            float newLowerValue = [self lowerValueForCenterX:(touchPoint.x - _lowerTouchOffset)];
            float valueDistance = _lowerValue + _minimumRange - _upperValue;
            float newValueDistance = newLowerValue + _minimumRange - _upperValue;
            if (valueDistance <= 0 && newValueDistance >= 0) {
                float alpha = -valueDistance / (newValueDistance - valueDistance);
                // need the non-integral centerX
                float upperCenterX = [self centerXForUpperValue:_upperValue];
                _upperTouchOffset = previousTouchPoint.x + alpha * distance - upperCenterX;
                _upperHandle.highlighted = YES;
                _pushHandle = _lowerHandle;
            }
        } else if (distance < 0 && _upperHandle.highlighted) {
            float newUpperValue = [self upperValueForCenterX:(touchPoint.x - _upperTouchOffset)];
            float valueDistance = _lowerValue + _minimumRange - _upperValue;
            float newValueDistance = _lowerValue + _minimumRange - newUpperValue;
            if (valueDistance <= 0 && newValueDistance >= 0) {
                float alpha = -valueDistance / (newValueDistance - valueDistance);
                // need the non-integral centerX
                float lowerCenterX = [self centerXForLowerValue:_lowerValue];
                _lowerTouchOffset = previousTouchPoint.x + alpha * distance - lowerCenterX;
                _lowerHandle.highlighted = YES;
                _pushHandle = _upperHandle;
            }
        }
    }

    float newLowerValue = _lowerValue;
    float newUpperValue = _upperValue;
    
    if(_lowerHandle.highlighted)
    {
        float value = [self lowerValueForCenterX:(touchPoint.x - _lowerTouchOffset)];
        
        //decide if the upper value should be updated
        if (value < _lowerValue || !_upperHandle.highlighted || _lowerHandle == _pushHandle) {
            newLowerValue = value;
        }
        
        // decide if upper handle should be un-highlighted
        if (_upperHandle.highlighted && newLowerValue < _lowerValue && _upperHandle != _pushHandle) {
            _upperHandle.highlighted=NO;
            [self bringSubviewToFront:_lowerHandle];
            _pushHandle = nil;
        }
    }
    
    if(_upperHandle.highlighted )
    {
        float value = [self upperValueForCenterX:(touchPoint.x - _upperTouchOffset)];
        
        //decide if the upper value should be updated
        if (value > _upperValue || !_lowerHandle.highlighted || _upperHandle == _pushHandle) {
            newUpperValue = value;
        }

        // decide if lower handle should be un-highlighted
        if (_lowerHandle.highlighted && newUpperValue > _upperValue && _lowerHandle != _pushHandle) {
            _lowerHandle.highlighted=NO;
            [self bringSubviewToFront:_upperHandle];
            _pushHandle = nil;
        }
    }

//    [self setUpperValue:newUpperValue animated:NO];
//    [self setLowerValue:newLowerValue animated:NO];
    [self setLowerValue:newLowerValue upperValue:newUpperValue animated:_stepValueContinuously ? YES : NO];
    
    //send the control event
    if(_continuous)
    {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    //redraw
    [self setNeedsLayout];

    return YES;
}



-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _lowerHandle.highlighted = NO;
    _upperHandle.highlighted = NO;
    _pushHandle = nil;
    
    if(_stepValue>0)
    {
        _stepValueInternal=_stepValue;
        
        [self setLowerValue:_lowerValue animated:YES];
        [self setUpperValue:_upperValue animated:YES];
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (UIImageView *)touchedHandleWithPoint:(CGPoint)point
{
    CGPoint lowerVector = CGPointMake(self.lowerHandle.center.x - point.x, self.lowerHandle.center.y - point.y);
    CGPoint upperVector = CGPointMake(self.upperHandle.center.x - point.x, self.upperHandle.center.y - point.y);
    
    CGFloat lowerDistance = sqrt(lowerVector.x * lowerVector.x + lowerVector.y * lowerVector.y);
    CGFloat upperDistance = sqrt(upperVector.x * upperVector.x + upperVector.y * upperVector.y);
    
    BOOL insideLower = CGRectContainsPoint(self.lowerHandle.frame, point);
    BOOL insideUpper = CGRectContainsPoint(self.upperHandle.frame, point);
    // select touched handle if touch inside one but not the other
    if (insideLower && !insideUpper) {
        lowerDistance = -1;
    } else if (insideUpper && !insideLower) {
        upperDistance = -1;
    }
    
    if (lowerDistance > 22 && upperDistance > 22) { return nil; }
    
    // break tie if both same distance by selecting the one on top
    if (lowerDistance == upperDistance) {
        if ([self.subviews indexOfObject:self.lowerHandle] > [self.subviews indexOfObject:self.upperHandle]) {
            lowerDistance = -1;
        } else {
            upperDistance = -1;
        }
    }
    
    return lowerDistance < upperDistance ? self.lowerHandle : self.upperHandle;
}

- (UIView *)activeHandle
{
    UIView *activeHandle = nil;
    if (self.pushHandle) {
        activeHandle = self.pushHandle;
    } else if (self.lowerHandle.highlighted) {
        activeHandle = self.lowerHandle;
    } else if (self.upperHandle.highlighted) {
        activeHandle = self.upperHandle;
    }
    return activeHandle;
}

@end
