#import <UIKit/UIKit.h>
#import "shared/QPCommon.h"
#import "shared/QPPrefs.h"
#import "tweak/QPGlassButtonView.h"

@interface SBUIPasscodeLockViewBase : UIView
@property (nonatomic) BOOL usesBiometricPresentation;
- (void)setKeypadVisible:(BOOL)arg1 animated:(BOOL)arg2;
- (void)passcodeBiometricAuthenticationViewUsePasscodeButtonHit:(id)arg1;
- (void)_overrideBiometricMatchingEnabled:(BOOL)arg1 forReason:(id)arg2;
@end

@interface CSPasscodeViewController : UIViewController
@property (nonatomic) BOOL useBiometricPresentation;
@property (nonatomic) BOOL biometricButtonsInitiallyVisible;
@property (nonatomic) BOOL showProudLock;
- (SBUIPasscodeLockViewBase *)passcodeLockView;
@end

@interface CSCoverSheetViewController : UIViewController
- (BOOL)isPasscodeLockVisible;
- (void)setPasscodeLockVisible:(BOOL)arg1 animated:(BOOL)arg2;
- (void)setPasscodeLockVisible:(BOOL)arg1 animated:(BOOL)arg2 completion:(id)arg3;
- (void)setPasscodeLockVisible:(BOOL)arg1 animated:(BOOL)arg2 forceBiometricPresentation:(BOOL)arg3 completion:(id)arg4;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isUILocked;
- (CSCoverSheetViewController *)coverSheetViewController;
- (void)lockScreenViewControllerRequestsUnlock;
@end

static BOOL gBypassFaceIDForQuickPass = NO;

static inline void triggerPasscodeUnlock(CSCoverSheetViewController *csvc) {
    gBypassFaceIDForQuickPass = YES;

    if (csvc) {
        if ([csvc respondsToSelector:@selector(isPasscodeLockVisible)] && [csvc isPasscodeLockVisible]) {
            return;
        }
        if ([csvc respondsToSelector:@selector(setPasscodeLockVisible:animated:forceBiometricPresentation:completion:)]) {
            [csvc setPasscodeLockVisible:YES animated:NO forceBiometricPresentation:NO completion:nil];
            return;
        }
        if ([csvc respondsToSelector:@selector(setPasscodeLockVisible:animated:completion:)]) {
            [csvc setPasscodeLockVisible:YES animated:NO completion:nil];
            return;
        }
        if ([csvc respondsToSelector:@selector(setPasscodeLockVisible:animated:)]) {
            [csvc setPasscodeLockVisible:YES animated:NO];
            return;
        }
    }

    SBLockScreenManager *mgr = [NSClassFromString(@"SBLockScreenManager") sharedInstance];
    if (mgr) {
        if ([mgr respondsToSelector:@selector(coverSheetViewController)]) {
            CSCoverSheetViewController *scvc = [mgr coverSheetViewController];
            if (scvc && [scvc respondsToSelector:@selector(setPasscodeLockVisible:animated:)]) {
                [scvc setPasscodeLockVisible:YES animated:NO];
                return;
            }
        }
        if ([mgr respondsToSelector:@selector(lockScreenViewControllerRequestsUnlock)]) {
            [mgr lockScreenViewControllerRequestsUnlock];
        }
    }
}

%hook CSCoverSheetViewController

- (void)viewDidLoad {
    %orig;
    if (![QPPrefs shared].enabled) return;

    QPGlassButtonView *btn = (QPGlassButtonView *)[self.view viewWithTag:98927];
    if (!btn) {
        CGFloat sz = [QPPrefs shared].buttonSize;
        CGFloat w = ([QPPrefs shared].buttonStyle == QPStylePillLabel) ? 104.0 : sz;
        CGFloat h = ([QPPrefs shared].buttonStyle == QPStylePillLabel) ? 38.0 : sz;
        btn = [[QPGlassButtonView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
        btn.tag = 98927;

        __weak typeof(self) weakSelf = self;
        btn.onTap = ^{
            triggerPasscodeUnlock(weakSelf);
        };
        btn.onDragEnd = ^(CGPoint center) {
            [[QPPrefs shared] setPref:@YES forKey:@"hasCustomPosition"];
            [[QPPrefs shared] setPref:@(center.x) forKey:@"customX"];
            [[QPPrefs shared] setPref:@(center.y) forKey:@"customY"];
        };
        [self.view addSubview:btn];
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    QPPrefs *p = [QPPrefs shared];
    QPGlassButtonView *btn = (QPGlassButtonView *)[self.view viewWithTag:98927];
    if (!p.enabled) {
        if (btn) btn.hidden = YES;
        return;
    }

    CGFloat sz = p.buttonSize;
    CGFloat w = (p.buttonStyle == QPStylePillLabel) ? 104.0 : sz;
    CGFloat h = (p.buttonStyle == QPStylePillLabel) ? 38.0 : sz;

    if (!btn) {
        btn = [[QPGlassButtonView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
        btn.tag = 98927;
        __weak typeof(self) weakSelf = self;
        btn.onTap = ^{
            triggerPasscodeUnlock(weakSelf);
        };
        btn.onDragEnd = ^(CGPoint center) {
            [[QPPrefs shared] setPref:@YES forKey:@"hasCustomPosition"];
            [[QPPrefs shared] setPref:@(center.x) forKey:@"customX"];
            [[QPPrefs shared] setPref:@(center.y) forKey:@"customY"];
        };
        [self.view addSubview:btn];
    }

    btn.hidden = NO;
    btn.bounds = CGRectMake(0, 0, w, h);
    [btn updateStyle];

    CGRect bounds = self.view.bounds;

    if (p.hasCustomPosition && p.customX > 0 && p.customY > 0) {
        // Use user's custom dragged position
        btn.center = CGPointMake(p.customX, p.customY);
    } else {
        // Calculate based on preset
        CGFloat bottomPadding = 50.0;
        if (@available(iOS 11.0, *)) {
            bottomPadding += self.view.safeAreaInsets.bottom;
        }

        switch (p.positionPreset) {
            case QPPositionBelowClock: {
                btn.center = CGPointMake(bounds.size.width / 2.0, 240.0);
                break;
            }
            case QPPositionBottomRight: {
                btn.center = CGPointMake(bounds.size.width - (w / 2.0) - 24.0, bounds.size.height - bottomPadding - (h / 2.0));
                break;
            }
            case QPPositionBottomLeft: {
                btn.center = CGPointMake((w / 2.0) + 24.0, bounds.size.height - bottomPadding - (h / 2.0));
                break;
            }
            case QPPositionBottomCenter:
            default: {
                btn.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height - bottomPadding - (h / 2.0));
                break;
            }
        }
    }

    [self.view bringSubviewToFront:btn];

    if ([self respondsToSelector:@selector(isPasscodeLockVisible)]) {
        btn.alpha = [self isPasscodeLockVisible] ? 0.0 : 1.0;
    }
}

- (void)setPasscodeLockVisible:(BOOL)visible animated:(BOOL)animated {
    if (!visible) {
        gBypassFaceIDForQuickPass = NO;
    }
    %orig(visible, animated);
    QPGlassButtonView *btn = (QPGlassButtonView *)[self.view viewWithTag:98927];
    if (btn) {
        if (animated) {
            [UIView animateWithDuration:0.25 animations:^{
                btn.alpha = visible ? 0.0 : 1.0;
            }];
        } else {
            btn.alpha = visible ? 0.0 : 1.0;
        }
    }
}

%end

%hook CSPasscodeViewController

- (BOOL)useBiometricPresentation {
    if (gBypassFaceIDForQuickPass) {
        return NO;
    }
    return %orig;
}

- (void)setUseBiometricPresentation:(BOOL)val {
    if (gBypassFaceIDForQuickPass) {
        %orig(NO);
        return;
    }
    %orig;
}

- (void)viewDidLoad {
    if (gBypassFaceIDForQuickPass) {
        if ([self respondsToSelector:@selector(setUseBiometricPresentation:)]) {
            self.useBiometricPresentation = NO;
        }
        if ([self respondsToSelector:@selector(setShowProudLock:)]) {
            self.showProudLock = NO;
        }
        if ([self respondsToSelector:@selector(setBiometricButtonsInitiallyVisible:)]) {
            self.biometricButtonsInitiallyVisible = NO;
        }
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    if (gBypassFaceIDForQuickPass) {
        if ([self respondsToSelector:@selector(setUseBiometricPresentation:)]) {
            self.useBiometricPresentation = NO;
        }
        if ([self respondsToSelector:@selector(setShowProudLock:)]) {
            self.showProudLock = NO;
        }
        if ([self respondsToSelector:@selector(setBiometricButtonsInitiallyVisible:)]) {
            self.biometricButtonsInitiallyVisible = NO;
        }
    }
    %orig;
    if (gBypassFaceIDForQuickPass) {
        SBUIPasscodeLockViewBase *pView = nil;
        if ([self respondsToSelector:@selector(passcodeLockView)]) {
            pView = [self passcodeLockView];
        } else {
            @try {
                pView = [self valueForKey:@"_passcodeLockView"];
            } @catch (__unused id ex) {}
        }
        if (pView) {
            if ([pView respondsToSelector:@selector(setUsesBiometricPresentation:)]) {
                pView.usesBiometricPresentation = NO;
            }
            if ([pView respondsToSelector:@selector(setKeypadVisible:animated:)]) {
                [pView setKeypadVisible:YES animated:NO];
            }
            if ([pView respondsToSelector:@selector(passcodeBiometricAuthenticationViewUsePasscodeButtonHit:)]) {
                [pView passcodeBiometricAuthenticationViewUsePasscodeButtonHit:nil];
            }
            [pView becomeFirstResponder];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    gBypassFaceIDForQuickPass = NO;
}

%end

%hook SBUIPasscodeLockViewBase

- (BOOL)usesBiometricPresentation {
    if (gBypassFaceIDForQuickPass) {
        return NO;
    }
    return %orig;
}

- (void)didMoveToWindow {
    %orig;
    if (gBypassFaceIDForQuickPass && self.window) {
        if ([self respondsToSelector:@selector(setUsesBiometricPresentation:)]) {
            self.usesBiometricPresentation = NO;
        }
        if ([self respondsToSelector:@selector(setKeypadVisible:animated:)]) {
            [self setKeypadVisible:YES animated:NO];
        }
        if ([self respondsToSelector:@selector(passcodeBiometricAuthenticationViewUsePasscodeButtonHit:)]) {
            [self passcodeBiometricAuthenticationViewUsePasscodeButtonHit:nil];
        }
        [self becomeFirstResponder];
    }
}

%end

%ctor {
    @autoreleasepool {
        [[QPPrefs shared] reload];
    }
}
