#import "QPGlassButtonView.h"
#import "QPPrefs.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>

@interface QPGlassButtonView () <UIGestureRecognizerDelegate>
@end

@implementation QPGlassButtonView {
    UIView *_fillView;
    UIVisualEffectView *_blurView;
    CAGradientLayer *_specularLayer;
    CALayer *_outerRimLayer;
    CALayer *_innerRimLayer;
    UIImageView *_iconImageView;
    UILabel *_pillLabel;
    
    UITapGestureRecognizer *_tapGesture;
    UILongPressGestureRecognizer *_dragGesture;
    CGPoint _dragStartCenter;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO; // allow shadow
        self.backgroundColor = [UIColor clearColor];

        // Layer shadow
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 8;
        self.layer.shadowOpacity = 0.35;

        // Base fill view
        _fillView = [[UIView alloc] initWithFrame:self.bounds];
        _fillView.clipsToBounds = YES;
        [self addSubview:_fillView];

        // System Blur
        UIBlurEffectStyle blurStyle = UIBlurEffectStyleDark;
        if (@available(iOS 13.0, *)) {
            blurStyle = UIBlurEffectStyleSystemThinMaterialDark;
        }
        _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurStyle]];
        _blurView.frame = _fillView.bounds;
        _blurView.userInteractionEnabled = NO;
        [_fillView addSubview:_blurView];

        // Specular radial reflection
        _specularLayer = [CAGradientLayer layer];
        _specularLayer.type = kCAGradientLayerRadial;
        _specularLayer.locations = @[@0.0, @0.45, @1.0];
        [_fillView.layer addSublayer:_specularLayer];

        // Inner rim (3D refraction)
        _innerRimLayer = [CALayer layer];
        _innerRimLayer.borderWidth = 0.8;
        _innerRimLayer.masksToBounds = YES;
        [_fillView.layer addSublayer:_innerRimLayer];

        // Outer rim
        _outerRimLayer = [CALayer layer];
        _outerRimLayer.borderWidth = 1.2;
        _outerRimLayer.masksToBounds = YES;
        [_fillView.layer addSublayer:_outerRimLayer];

        // Icon View
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.tintColor = [UIColor whiteColor];
        _iconImageView.userInteractionEnabled = NO;
        [_fillView addSubview:_iconImageView];

        // Pill label for "Passcode" mode
        _pillLabel = [[UILabel alloc] init];
        _pillLabel.textColor = [UIColor whiteColor];
        _pillLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        _pillLabel.textAlignment = NSTextAlignmentCenter;
        _pillLabel.text = @"Passcode";
        _pillLabel.hidden = YES;
        [_fillView addSubview:_pillLabel];

        // Gestures
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _tapGesture.cancelsTouchesInView = NO;
        _tapGesture.delegate = self;
        [self addGestureRecognizer:_tapGesture];

        _dragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
        _dragGesture.minimumPressDuration = 0.28;
        _dragGesture.allowableMovement = 12.0;
        _dragGesture.delegate = self;
        [self addGestureRecognizer:_dragGesture];

        [_tapGesture requireGestureRecognizerToFail:_dragGesture];

        [self updateStyle];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.bounds;
    _fillView.frame = b;
    _blurView.frame = b;

    CGFloat r = (self.buttonStyle == QPStylePillLabel) ? 18.0 : (b.size.width / 2.0);
    _fillView.layer.cornerRadius = r;
    _blurView.layer.cornerRadius = r;
    if (@available(iOS 13.0, *)) {
        _fillView.layer.cornerCurve = kCACornerCurveContinuous;
        _blurView.layer.cornerCurve = kCACornerCurveContinuous;
        _outerRimLayer.cornerCurve = kCACornerCurveContinuous;
        _innerRimLayer.cornerCurve = kCACornerCurveContinuous;
    }

    _outerRimLayer.frame = _fillView.bounds;
    _outerRimLayer.cornerRadius = r;

    _innerRimLayer.frame = CGRectInset(_fillView.bounds, 1.0, 1.0);
    _innerRimLayer.cornerRadius = MAX(r - 1.0, 0);

    CGFloat w = b.size.width;
    CGFloat h = b.size.height;
    _specularLayer.frame = CGRectMake(-w * 0.2, -h * 0.4, w * 1.4, h * 1.4);

    if (self.buttonStyle == QPStylePillLabel) {
        _pillLabel.hidden = NO;
        _iconImageView.hidden = YES;
        _pillLabel.frame = b;
    } else {
        _pillLabel.hidden = YES;
        _iconImageView.hidden = NO;
        CGFloat iconSize = MAX(20, b.size.width * 0.44);
        _iconImageView.frame = CGRectMake((w - iconSize) / 2.0, (h - iconSize) / 2.0, iconSize, iconSize);
    }
}

- (void)updateStyle {
    QPPrefs *p = [QPPrefs shared];
    self.buttonStyle = (QPButtonStyle)p.buttonStyle;
    self.iconType = (QPIconType)p.iconType;
    self.specularGlow = p.specularGlow;

    // Reset backgrounds
    _fillView.backgroundColor = [UIColor clearColor];
    _blurView.hidden = NO;
    _specularLayer.hidden = !self.specularGlow;

    switch (self.buttonStyle) {
        case QPStyleLiquidGlass: {
            _blurView.hidden = NO;
            _fillView.backgroundColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.18 alpha:0.45];
            _outerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.55].CGColor;
            _innerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
            _specularLayer.colors = @[
                (id)[UIColor colorWithWhite:1.0 alpha:0.35].CGColor,
                (id)[UIColor colorWithWhite:1.0 alpha:0.10].CGColor,
                (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor
            ];
            break;
        }
        case QPStyleFrostedDark: {
            _blurView.hidden = NO;
            _fillView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
            _outerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
            _innerRimLayer.borderColor = [UIColor clearColor].CGColor;
            _specularLayer.hidden = YES;
            break;
        }
        case QPStyleUltraClear: {
            _blurView.hidden = YES;
            _fillView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
            _outerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.70].CGColor;
            _innerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;
            _specularLayer.colors = @[
                (id)[UIColor colorWithWhite:1.0 alpha:0.45].CGColor,
                (id)[UIColor colorWithWhite:1.0 alpha:0.15].CGColor,
                (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor
            ];
            break;
        }
        case QPStyleSolidAccent: {
            _blurView.hidden = YES;
            _fillView.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.95 alpha:0.85];
            _outerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.45].CGColor;
            _innerRimLayer.borderColor = [UIColor clearColor].CGColor;
            _specularLayer.hidden = YES;
            break;
        }
        case QPStylePillLabel: {
            _blurView.hidden = NO;
            _fillView.backgroundColor = [UIColor colorWithRed:0.08 green:0.10 blue:0.15 alpha:0.60];
            _outerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.40].CGColor;
            _innerRimLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
            _specularLayer.hidden = YES;
            break;
        }
    }

    // Set Icon graphic
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightSemibold];
        UIImage *img = nil;
        switch (self.iconType) {
            case QPIconLockCircle:
                img = [UIImage systemImageNamed:@"lock.fill" withConfiguration:cfg];
                break;
            case QPIconShieldCheck:
                img = [UIImage systemImageNamed:@"lock.shield.fill" withConfiguration:cfg] ?: [UIImage systemImageNamed:@"shield.fill" withConfiguration:cfg];
                break;
            case QPIconTouchDigit:
                img = [UIImage systemImageNamed:@"hand.tap.fill" withConfiguration:cfg] ?: [UIImage systemImageNamed:@"number.circle.fill" withConfiguration:cfg];
                break;
            case QPIconKeypadGrid:
            default:
                img = [UIImage systemImageNamed:@"circle.grid.3x3.fill" withConfiguration:cfg] ?: [UIImage systemImageNamed:@"square.grid.3x3.fill" withConfiguration:cfg];
                break;
        }
        _iconImageView.image = img;
    }

    [self setNeedsLayout];
}

#pragma mark - Gestures & Interactions

- (void)handleTap:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        if ([QPPrefs shared].haptic) {
            if (@available(iOS 10.0, *)) {
                UIImpactFeedbackGenerator *feed = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                [feed prepare];
                [feed impactOccurred];
            }
        }
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(0.90, 0.90);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15 animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }];

        if (self.onTap) {
            self.onTap();
        }
    }
}

- (void)handleDrag:(UILongPressGestureRecognizer *)g {
    if (![QPPrefs shared].allowDrag) return;

    CGPoint translation = [g locationInView:self.superview];

    switch (g.state) {
        case UIGestureRecognizerStateBegan: {
            _dragStartCenter = self.center;
            if ([QPPrefs shared].haptic) {
                if (@available(iOS 10.0, *)) {
                    UIImpactFeedbackGenerator *feed = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                    [feed prepare];
                    [feed impactOccurred];
                }
            }
            [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
                self.transform = CGAffineTransformMakeScale(1.18, 1.18);
                self.alpha = 0.92;
            } completion:nil];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            self.center = translation;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:0 animations:^{
                self.transform = CGAffineTransformIdentity;
                self.alpha = 1.0;
            } completion:nil];

            if ([QPPrefs shared].haptic) {
                if (@available(iOS 10.0, *)) {
                    UINotificationFeedbackGenerator *noti = [[UINotificationFeedbackGenerator alloc] init];
                    [noti prepare];
                    [noti notificationOccurred:UINotificationFeedbackTypeSuccess];
                }
            }

            if (self.onDragEnd) {
                self.onDragEnd(self.center);
            }
            break;
        }
        default:
            break;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

@end
