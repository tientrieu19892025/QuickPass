#import <UIKit/UIKit.h>
#import "shared/QPCommon.h"
#import "shared/QPPrefs.h"
#import "tweak/QPGlassButtonView.h"

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

static inline void triggerPasscodeUnlock(CSCoverSheetViewController *csvc) {
    if (csvc) {
        if ([csvc respondsToSelector:@selector(isPasscodeLockVisible)] && [csvc isPasscodeLockVisible]) {
            return;
        }
        if ([csvc respondsToSelector:@selector(setPasscodeLockVisible:animated:forceBiometricPresentation:completion:)]) {
            [csvc setPasscodeLockVisible:YES animated:YES forceBiometricPresentation:NO completion:nil];
            return;
        }
        if ([csvc respondsToSelector:@selector(setPasscodeLockVisible:animated:completion:)]) {
            [csvc setPasscodeLockVisible:YES animated:YES completion:nil];
            return;
        }
        if ([csvc respondsToSelector:@selector(setPasscodeLockVisible:animated:)]) {
            [csvc setPasscodeLockVisible:YES animated:YES];
            return;
        }
    }

    SBLockScreenManager *mgr = [NSClassFromString(@"SBLockScreenManager") sharedInstance];
    if (mgr) {
        if ([mgr respondsToSelector:@selector(coverSheetViewController)]) {
            CSCoverSheetViewController *scvc = [mgr coverSheetViewController];
            if (scvc && [scvc respondsToSelector:@selector(setPasscodeLockVisible:animated:)]) {
                [scvc setPasscodeLockVisible:YES animated:YES];
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

%ctor {
    @autoreleasepool {
        [[QPPrefs shared] reload];
    }
}
