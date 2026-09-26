#import "QPRootListController.h"
#import "../shared/QPCommon.h"
#import "../shared/QPPrefs.h"
#import "../shared/QPLocalize.h"
#import <spawn.h>

#if __has_include(<rootless.h>)
#import <rootless.h>
#endif
#ifndef ROOT_PATH
#define ROOT_PATH(x) (x)
#endif

static UIColor *QPAccent(void) {
    return [UIColor colorWithRed:0.25 green:0.48 blue:0.98 alpha:1.0];
}

static UIFont *QPTitleFont(void) {
    return [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
}

static UIFont *QPSubFont(void) {
    return [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
}

static UIView *QPCard(void) {
    UIView *c = [UIView new];
    c.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    if (@available(iOS 13.0, *)) {
        c.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        c.layer.cornerCurve = kCACornerCurveContinuous;
    }
    c.layer.cornerRadius = 20;
    return c;
}

@implementation QPRootListController {
    UIScrollView *_scroll;
    UIView *_content;
    CGFloat _laidWidth;
}

- (NSArray *)specifiers {
    return @[];
}

- (void)hideStockTable {
    UITableView *tv = nil;
    @try { tv = [self valueForKey:@"table"]; } @catch (NSException *e) {}
    if ([tv isKindOfClass:[UITableView class]]) {
        tv.hidden = YES;
        tv.scrollEnabled = NO;
        tv.separatorStyle = UITableViewCellSeparatorStyleNone;
        tv.backgroundColor = UIColor.clearColor;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"QuickPass";
    if (@available(iOS 13.0, *)) self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    else self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self hideStockTable];

    _scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scroll.alwaysBounceVertical = YES;
    _scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scroll];

    _content = [UIView new];
    [_scroll addSubview:_content];

    [self rebuild];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hideStockTable];
    [self rebuild];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _scroll.frame = self.view.bounds;
    CGFloat w = self.view.bounds.size.width;
    if (w > 2 && fabs(w - _laidWidth) > 1) [self rebuild];
}

- (UIColor *)labelColor {
    if (@available(iOS 13.0, *)) return [UIColor labelColor];
    return [UIColor darkTextColor];
}

- (UIColor *)secondaryColor {
    if (@available(iOS 13.0, *)) return [UIColor secondaryLabelColor];
    return [UIColor grayColor];
}

- (UIColor *)tertiaryColor {
    if (@available(iOS 13.0, *)) return [UIColor tertiaryLabelColor];
    return [UIColor lightGrayColor];
}

- (CGFloat)putSection:(NSString *)title atY:(CGFloat)y x:(CGFloat)x inner:(CGFloat)inner {
    UILabel *sec = [[UILabel alloc] initWithFrame:CGRectMake(x + 4, y, inner, 22)];
    sec.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    sec.textColor = [self secondaryColor];
    sec.text = title.uppercaseString;
    [_content addSubview:sec];
    return y + 28;
}

- (CGFloat)putSwitchGroup:(NSArray<NSArray *> *)rows y:(CGFloat)y x:(CGFloat)x inner:(CGFloat)inner {
    CGFloat rowH = 64;
    UIView *card = QPCard();
    card.frame = CGRectMake(x, y, inner, rowH * rows.count);
    CGFloat ry = 0;
    for (NSInteger i = 0; i < (NSInteger)rows.count; i++) {
        NSArray *row = rows[i];
        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(18, ry + 10, inner - 90, 22)];
        t.font = QPTitleFont();
        t.text = row[0];
        t.textColor = [self labelColor];
        [card addSubview:t];

        UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(18, ry + 32, inner - 90, 22)];
        s.font = QPSubFont();
        s.text = row[1];
        s.textColor = [self secondaryColor];
        s.adjustsFontSizeToFitWidth = YES;
        s.minimumScaleFactor = 0.8;
        [card addSubview:s];

        UISwitch *sw = [UISwitch new];
        sw.on = [row[3] boolValue];
        sw.onTintColor = QPAccent();
        sw.accessibilityIdentifier = row[2];
        sw.frame = CGRectMake(inner - 68, ry + 16, 51, 31);
        [sw addTarget:self action:@selector(toggleKey:) forControlEvents:UIControlEventValueChanged];
        [card addSubview:sw];

        if (i + 1 < (NSInteger)rows.count) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(18, ry + rowH - 1.0 / [UIScreen mainScreen].scale, inner - 36, 1.0 / [UIScreen mainScreen].scale)];
            if (@available(iOS 13.0, *)) line.backgroundColor = [UIColor separatorColor];
            else line.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            [card addSubview:line];
        }
        ry += rowH;
    }
    [_content addSubview:card];
    return y + card.frame.size.height + 18;
}

- (CGFloat)putChips:(NSString *)title sub:(NSString *)sub key:(NSString *)key keys:(NSArray *)keys titles:(NSArray *)titles value:(NSInteger)value
                  y:(CGFloat)y x:(CGFloat)x inner:(CGFloat)inner {
    CGFloat extra = sub.length ? 22 : 0;
    UIView *card = QPCard();
    card.frame = CGRectMake(x, y, inner, 80 + extra);

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(18, 10, inner - 36, 18)];
    l.font = QPSubFont();
    l.text = title;
    l.textColor = [self secondaryColor];
    [card addSubview:l];

    CGFloat chipY = 34;
    if (sub.length) {
        UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(18, 28, inner - 36, 20)];
        h.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
        h.text = sub;
        h.textColor = [self tertiaryColor];
        [card addSubview:h];
        chipY = 50;
    }

    CGFloat bx = 16;
    UIColor *offInk = [self labelColor];
    for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:titles[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        [b sizeToFit];
        CGFloat bw = MAX(54, b.bounds.size.width + 20);
        if (bx + bw > inner - 16) { bx = 16; chipY += 40; }
        b.frame = CGRectMake(bx, chipY, bw, 32);
        b.layer.cornerRadius = 16;
        BOOL on = (value == [keys[i] integerValue]);
        b.backgroundColor = on ? QPAccent() : [UIColor colorWithWhite:0.5 alpha:0.12];
        [b setTitleColor:on ? UIColor.whiteColor : offInk forState:UIControlStateNormal];
        b.tag = 700 + i;
        b.accessibilityIdentifier = key;
        [b addTarget:self action:@selector(pickChip:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:b];
        bx += bw + 8;
    }

    if (chipY > 50) {
        card.frame = CGRectMake(x, y, inner, chipY + 44);
    }
    [_content addSubview:card];
    return y + card.frame.size.height + 18;
}

- (CGFloat)putButton:(NSString *)title action:(SEL)sel filled:(BOOL)filled y:(CGFloat)y x:(CGFloat)x inner:(CGFloat)inner {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(x, y, inner, 52);
    b.layer.cornerRadius = 16;
    if (@available(iOS 13.0, *)) b.layer.cornerCurve = kCACornerCurveContinuous;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = filled ? [UIFont systemFontOfSize:17 weight:UIFontWeightBold] : QPTitleFont();
    if (filled) {
        b.backgroundColor = QPAccent();
        [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        b.backgroundColor = QPCard().backgroundColor;
        [b setTitleColor:QPAccent() forState:UIControlStateNormal];
    }
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [_content addSubview:b];
    return y + 64;
}

#pragma mark - Actions & Callbacks

- (void)toggleKey:(UISwitch *)s {
    NSString *key = s.accessibilityIdentifier;
    if (!key.length) return;
    [[QPPrefs shared] setPref:@(s.on) forKey:key];
}

- (void)pickChip:(UIButton *)b {
    NSString *key = b.accessibilityIdentifier ?: @"";
    NSInteger idx = b.tag - 700;
    if ([key isEqualToString:@"positionPreset"]) {
        NSArray *vals = @[ @(QPPositionBottomCenter), @(QPPositionBelowClock), @(QPPositionBottomRight), @(QPPositionBottomLeft) ];
        if (idx >= 0 && idx < (NSInteger)vals.count) {
            [[QPPrefs shared] setPref:vals[idx] forKey:@"positionPreset"];
            [[QPPrefs shared] setPref:@NO forKey:@"hasCustomPosition"];
        }
    } else if ([key isEqualToString:@"buttonStyle"]) {
        NSArray *vals = @[ @(QPStyleLiquidGlass), @(QPStyleFrostedDark), @(QPStyleUltraClear), @(QPStyleSolidAccent), @(QPStylePillLabel) ];
        if (idx >= 0 && idx < (NSInteger)vals.count) {
            [[QPPrefs shared] setPref:vals[idx] forKey:@"buttonStyle"];
        }
    } else if ([key isEqualToString:@"iconType"]) {
        NSArray *vals = @[ @(QPIconKeypadGrid), @(QPIconLockCircle), @(QPIconShieldCheck), @(QPIconTouchDigit) ];
        if (idx >= 0 && idx < (NSInteger)vals.count) {
            [[QPPrefs shared] setPref:vals[idx] forKey:@"iconType"];
        }
    } else if ([key isEqualToString:@"buttonSize"]) {
        NSArray *vals = @[ @44.0, @50.0, @58.0 ];
        if (idx >= 0 && idx < (NSInteger)vals.count) {
            [[QPPrefs shared] setPref:vals[idx] forKey:@"buttonSize"];
        }
    } else if ([key isEqualToString:@"language"]) {
        [[QPPrefs shared] setPref:@(idx) forKey:@"language"];
    }
    [self rebuild];
}

- (void)resetPosition {
    [[QPPrefs shared] resetPosition];
    [self rebuild];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"app_name")
                                                                   message:QPLoc(@"reset_pos")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)copyDonateAccount {
    [UIPasteboard generalPasteboard].string = kQPDonateAccount;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"copied")
                                                                   message:[NSString stringWithFormat:@"%@: %@", kQPDonateBank, kQPDonateAccount]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)copyDonateText {
    [UIPasteboard generalPasteboard].string = kQPDonateText;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QPLoc(@"copied")
                                                                   message:kQPDonateText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:QPLoc(@"ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openURLString:(NSString *)urlStr {
    if (urlStr.length) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] options:@{} completionHandler:nil];
    }
}

- (void)openKofi { [self openURLString:@"https://ko-fi.com/jinkennguyen"]; }
- (void)openPaypal { [self openURLString:@"https://paypal.me/jinkennguyen"]; }
- (void)openBmc { [self openURLString:@"https://buymeacoffee.com/jinkennguyen"]; }
- (void)openGithub { [self openURLString:@"https://github.com/jinkennguyen"]; }

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

#pragma mark - Main Rebuild

- (void)rebuild {
    for (UIView *v in _content.subviews) [v removeFromSuperview];
    CGFloat w = self.view.bounds.size.width;
    if (w < 2) w = [UIScreen mainScreen].bounds.size.width;
    _laidWidth = w;
    CGFloat x = 16, inner = w - 32, y = 12;
    QPPrefs *p = [QPPrefs shared];
    BOOL en = QPPreferEnglish();

    // 1. Hero Card (Liquid Glass Gradient Header)
    UIView *hero = QPCard();
    hero.frame = CGRectMake(x, y, inner, 126);
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.colors = @[
        (id)[UIColor colorWithRed:0.20 green:0.42 blue:0.95 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.38 green:0.68 blue:0.98 alpha:1.0].CGColor
    ];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint = CGPointMake(1, 1);
    grad.frame = CGRectMake(0, 0, inner, 126);
    grad.cornerRadius = 20;
    if (@available(iOS 13.0, *)) grad.cornerCurve = kCACornerCurveContinuous;
    [hero.layer insertSublayer:grad atIndex:0];

    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(20, 16, inner - 40, 30)];
    name.text = @"QuickPass";
    name.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    name.textColor = UIColor.whiteColor;
    [hero addSubview:name];

    UILabel *tag = [[UILabel alloc] initWithFrame:CGRectMake(20, 48, inner - 40, 22)];
    tag.text = QPLoc(@"app_sub");
    tag.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    tag.textColor = [UIColor colorWithWhite:1.0 alpha:0.94];
    [hero addSubview:tag];

    UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(20, 76, inner - 40, 36)];
    ver.text = [NSString stringWithFormat:@"v%@  ·  Jinken Nguyen - 1989\niOS 12 – 26  ·  Rootless · Rootful · RootHide", kQPVersion];
    ver.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    ver.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
    ver.numberOfLines = 2;
    [hero addSubview:ver];

    [_content addSubview:hero];
    y += 142;

    // 2. Section: General
    y = [self putSection:(en ? @"General" : @"Cài đặt chung") atY:y x:x inner:inner];
    y = [self putSwitchGroup:@[
        @[ QPLoc(@"enabled"), QPLoc(@"enabled_desc"), @"enabled", @(p.enabled) ],
        @[ QPLoc(@"allow_drag"), QPLoc(@"allow_drag_desc"), @"allowDrag", @(p.allowDrag) ],
        @[ QPLoc(@"haptic"), QPLoc(@"haptic_desc"), @"haptic", @(p.haptic) ],
        @[ QPLoc(@"glow_title"), QPLoc(@"glow_desc"), @"specularGlow", @(p.specularGlow) ],
    ] y:y x:x inner:inner];

    // 3. Section: Button Appearance & Graphics
    y = [self putSection:(en ? @"Design & Graphics" : @"Đồ hoạ & Kiểu dáng") atY:y x:x inner:inner];
    y = [self putChips:QPLoc(@"style_title")
                   sub:QPLoc(@"style_sub")
                   key:@"buttonStyle"
                  keys:@[ @0, @1, @2, @3, @4 ]
                titles:(en ? @[ @"Liquid Glass", @"Frosted", @"Clear", @"Accent", @"Pill" ]
                           : @[ @"Kính lỏng 3D", @"Mờ tối", @"Trong suốt", @"Màu khối", @"Dạng thanh" ])
                 value:p.buttonStyle y:y x:x inner:inner];

    y = [self putChips:QPLoc(@"icon_title")
                   sub:QPLoc(@"icon_sub")
                   key:@"iconType"
                  keys:@[ @0, @1, @2, @3 ]
                titles:(en ? @[ @"Keypad", @"Lock", @"Shield", @"Touch" ]
                           : @[ @"Bàn phím", @"Ổ khoá", @"Khiên", @"Chạm số" ])
                 value:p.iconType y:y x:x inner:inner];

    y = [self putChips:QPLoc(@"size_title")
                   sub:QPLoc(@"size_sub")
                   key:@"buttonSize"
                  keys:@[ @44, @50, @58 ]
                titles:(en ? @[ @"Compact (44)", @"Standard (50)", @"Large (58)" ]
                           : @[ @"Nhỏ gọn (44)", @"Chuẩn (50)", @"Lớn (58)" ])
                 value:(NSInteger)p.buttonSize y:y x:x inner:inner];

    // 4. Section: Position Preset
    y = [self putSection:(en ? @"Position Preset" : @"Vị trí hiển thị") atY:y x:x inner:inner];
    NSString *curPosSub = p.hasCustomPosition
        ? (en ? @"Custom position currently applied (dragged on screen)." : @"Đang dùng vị trí kéo thả tự do trên màn hình.")
        : QPLoc(@"pos_sub");
    y = [self putChips:QPLoc(@"position_title")
                   sub:curPosSub
                   key:@"positionPreset"
                  keys:@[ @0, @1, @2, @3 ]
                titles:(en ? @[ @"Center", @"Below Clock", @"Right", @"Left" ]
                           : @[ @"Ở giữa", @"Dưới đồng hồ", @"Góc phải", @"Góc trái" ])
                 value:p.positionPreset y:y x:x inner:inner];

    // 5. Section: Actions
    y = [self putSection:QPLoc(@"actions") atY:y x:x inner:inner];
    y = [self putButton:QPLoc(@"reset_pos") action:@selector(resetPosition) filled:NO y:y x:x inner:inner];
    y = [self putButton:QPLoc(@"respring") action:@selector(respring) filled:YES y:y x:x inner:inner];

    // 6. Section: Language
    y = [self putSection:(en ? @"Language" : @"Ngôn ngữ") atY:y x:x inner:inner];
    y = [self putChips:(en ? @"Language" : @"Ngôn ngữ")
                   sub:(en ? @"Auto follows the system language." : @"Tự động theo ngôn ngữ hệ thống.")
                   key:@"language"
                  keys:@[ @0, @1, @2 ]
                titles:@[ @"Auto", @"Tiếng Việt", @"English" ]
                 value:p.language y:y x:x inner:inner];

    // 7. Section: Donate
    y = [self putSection:QPLoc(@"donate_title") atY:y x:x inner:inner];
    UIView *donCard = QPCard();
    donCard.frame = CGRectMake(x, y, inner, 108);
    UILabel *dt = [[UILabel alloc] initWithFrame:CGRectMake(18, 12, inner - 36, 84)];
    dt.numberOfLines = 5;
    dt.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    dt.text = kQPDonateText;
    dt.textColor = [self labelColor];
    [donCard addSubview:dt];
    [_content addSubview:donCard];
    y += 120;

    y = [self putButton:QPLoc(@"copy_account") action:@selector(copyDonateAccount) filled:NO y:y x:x inner:inner];
    y = [self putButton:QPLoc(@"copy_text") action:@selector(copyDonateText) filled:NO y:y x:x inner:inner];
    y = [self putButton:@"MB Bank  ·  0345140889" action:@selector(copyDonateAccount) filled:NO y:y x:x inner:inner];

    // 8. International Donate Buttons
    y = [self putSection:(en ? @"International Donate" : @"Ủng hộ Quốc tế") atY:y x:x inner:inner];
    y = [self putButton:@"Ko-fi (ko-fi.com/jinkennguyen)" action:@selector(openKofi) filled:NO y:y x:x inner:inner];
    y = [self putButton:@"PayPal (paypal.me/jinkennguyen)" action:@selector(openPaypal) filled:NO y:y x:x inner:inner];
    y = [self putButton:@"Buy Me a Coffee" action:@selector(openBmc) filled:NO y:y x:x inner:inner];
    y = [self putButton:@"GitHub: @jinkennguyen" action:@selector(openGithub) filled:NO y:y x:x inner:inner];

    // 9. Credit Footer
    UILabel *credit = [[UILabel alloc] initWithFrame:CGRectMake(x, y, inner, 56)];
    credit.font = QPSubFont();
    credit.numberOfLines = 3;
    credit.textAlignment = NSTextAlignmentCenter;
    credit.textColor = [self tertiaryColor];
    credit.text = [NSString stringWithFormat:@"Credit: Jinken Nguyen - 1989\nDonate: MB Bank 0345140889 — Nguyễn Tiến Triều\nQuickPass v%@ · Rootful · Rootless · RootHide", kQPVersion];
    [_content addSubview:credit];
    y += 74;

    _content.frame = CGRectMake(0, 0, w, y);
    _scroll.contentSize = CGSizeMake(w, y);
    _scroll.frame = self.view.bounds;
}

@end
