#import "QPRootListController.h"
#import "../shared/QPCommon.h"
#import "../shared/QPLocalize.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <spawn.h>
#import <unistd.h>

#if __has_include(<rootless.h>)
#import <rootless.h>
#endif
#ifndef ROOT_PATH
#define ROOT_PATH(x) (x)
#endif

static NSString *const kDomain = @"com.jinken.quickpass";
static NSString *const kReload = @"com.jinken.quickpass/SettingsChanged";

static void QPPostReload(void) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)kReload, NULL, NULL, true);
}

static void QPAssignIvar(PSListController *ctrl, NSArray *specs) {
    Ivar iv = class_getInstanceVariable([PSListController class], "_specifiers");
    if (iv) object_setIvar(ctrl, iv, specs);
}

@implementation QPHeaderCell {
    UIImageView *_banner;
    UIView *_scrim;
    UILabel *_title;
    UILabel *_subtitle;
    UILabel *_version;
}

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"QPHeaderCell" specifier:specifier];
    if (!self) return self;
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = [UIView new];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _banner = [UIImageView new];
    _banner.contentMode = UIViewContentModeScaleAspectFill;
    _banner.clipsToBounds = YES;
    _banner.layer.cornerRadius = 20;
    _banner.backgroundColor = [UIColor colorWithRed:0.06 green:0.12 blue:0.28 alpha:1.0];
    if (@available(iOS 13.0, *)) _banner.layer.cornerCurve = kCACornerCurveContinuous;

    NSBundle *bundle = [NSBundle bundleForClass:[QPRootListController class]];
    NSString *path = [bundle pathForResource:@"banner" ofType:@"png"];
    if (path) _banner.image = [UIImage imageWithContentsOfFile:path];
    [self.contentView addSubview:_banner];

    _scrim = [UIView new];
    _scrim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    [_banner addSubview:_scrim];

    _title = [UILabel new];
    _title.text = @"QuickPass";
    _title.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    _title.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_title];

    _subtitle = [UILabel new];
    _subtitle.text = QPLoc(@"app_sub");
    _subtitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _subtitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    _subtitle.numberOfLines = 2;
    [self.contentView addSubview:_subtitle];

    _version = [UILabel new];
    _version.text = [NSString stringWithFormat:@"  v%@  ", kQPVersion];
    _version.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    _version.textColor = [UIColor whiteColor];
    _version.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25];
    _version.textAlignment = NSTextAlignmentCenter;
    _version.layer.cornerRadius = 10;
    _version.clipsToBounds = YES;
    [self.contentView addSubview:_version];

    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 168.0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat margin = 12.0;
    _banner.frame = CGRectMake(margin, 6, self.contentView.bounds.size.width - margin * 2, self.contentView.bounds.size.height - 12);
    _scrim.frame = _banner.bounds;
    _title.frame = CGRectMake(_banner.frame.origin.x + 16, _banner.frame.origin.y + 22, _banner.frame.size.width - 32, 34);
    _subtitle.frame = CGRectMake(_title.frame.origin.x, CGRectGetMaxY(_title.frame) + 2, _banner.frame.size.width - 32, 36);
    [_version sizeToFit];
    CGFloat vw = MAX(56, _version.bounds.size.width + 12);
    _version.frame = CGRectMake(_title.frame.origin.x, CGRectGetMaxY(_banner.frame) - 32, vw, 20);
}

@end

@implementation QPBaseListController

- (NSString *)qpPlistName {
    NSString *fromSpec = [self.specifier propertyForKey:@"qpPlist"];
    if ([fromSpec isKindOfClass:[NSString class]] && fromSpec.length) return fromSpec;
    return @"Root";
}

- (NSArray *)specifiers {
    if (self.qpHold) return self.qpHold;

    NSString *name = [self qpPlistName];
    NSArray *loaded = [self loadSpecifiersFromPlistName:name target:self];
    NSMutableArray *out = [NSMutableArray array];
    for (PSSpecifier *sp in loaded ?: @[]) {
        NSString *act = [sp propertyForKey:@"action"];
        if ([act isKindOfClass:[NSString class]] && act.length) {
            SEL sel = NSSelectorFromString(act);
            if (sel && [self respondsToSelector:sel] && [sp respondsToSelector:@selector(setButtonAction:)]) {
                ((void (*)(id, SEL, SEL))objc_msgSend)(sp, @selector(setButtonAction:), sel);
            }
        }
        [out addObject:sp];
    }
    self.qpHold = out;
    QPAssignIvar(self, out);
    return out;
}

- (void)reloadSpecifiers {
    self.qpHold = nil;
    QPAssignIvar(self, nil);
    [super reloadSpecifiers];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    CFStringRef key = (__bridge CFStringRef)specifier.properties[@"key"];
    if (!key) return specifier.properties[@"default"];
    CFPropertyListRef val = CFPreferencesCopyAppValue(key, (__bridge CFStringRef)kDomain);
    if (val) return CFBridgingRelease(val);
    return specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    CFStringRef key = (__bridge CFStringRef)specifier.properties[@"key"];
    if (!key) return;
    CFPreferencesSetAppValue(key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)kDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
    QPPostReload();
}

- (void)openURL:(PSSpecifier *)specifier {
    NSString *urlString = [specifier propertyForKey:@"url"];
    if (urlString) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    }
}

- (void)copyAccount {
    [UIPasteboard generalPasteboard].string = kQPDonateAccount;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"copied")
                                                                   message:[NSString stringWithFormat:@"%@: %@", kQPDonateBank, kQPDonateAccount]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)copyMessage {
    [UIPasteboard generalPasteboard].string = kQPDonateText;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"copied")
                                                                   message:kQPDonateText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetPosition {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:kQPPrefsPlistPath] ?: [NSMutableDictionary dictionary];
    dict[@"hasCustomPosition"] = @NO;
    dict[@"customX"] = @0.0;
    dict[@"customY"] = @0.0;
    dict[@"positionPreset"] = @(QPPositionBottomCenter);
    [dict writeToFile:kQPPrefsPlistPath atomically:YES];

    QPPostReload();

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"app_name")
                                                                   message:QPLoc(@"reset_pos")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)respring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"respring")
                                                                   message:QPLoc(@"app_sub")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"respring") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        pid_t pid;
        const char *paths[] = {
            ROOT_PATH("/usr/bin/sbreload"),
            "/var/jb/usr/bin/sbreload",
            "/usr/bin/sbreload",
            ROOT_PATH("/usr/bin/killall"),
            "/var/jb/usr/bin/killall",
            "/usr/bin/killall",
            NULL
        };
        for (int i = 0; paths[i]; i++) {
            if (access(paths[i], X_OK) != 0) continue;
            if (strstr(paths[i], "killall")) {
                const char *args[] = {"killall", "-9", "SpringBoard", NULL};
                posix_spawn(&pid, paths[i], NULL, NULL, (char *const *)args, NULL);
                return;
            }
            const char *args[] = {"sbreload", NULL};
            posix_spawn(&pid, paths[i], NULL, NULL, (char *const *)args, NULL);
            return;
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@implementation QPRootListController
- (NSString *)qpPlistName {
    return @"Root";
}
- (id)specifiers {
    NSArray *s = [super specifiers];
    self.title = @"QuickPass";
    return s;
}
@end

@implementation QPSubListController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.specifier.name.length) self.title = self.specifier.name;
}
@end

@implementation QPDonateController
- (NSString *)qpPlistName {
    return @"Donate";
}
@end

@implementation QPAboutController
- (NSString *)qpPlistName {
    return @"About";
}
@end
