#import "QPPrefs.h"

static void QPPrefsChangedCallback(CFNotificationCenterRef center, void *observer,
                                   CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[QPPrefs shared] reload];
}

@implementation QPPrefs {
    NSDictionary *_raw;
}

+ (instancetype)shared {
    static QPPrefs *p = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        p = [[QPPrefs alloc] init];
    });
    return p;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reload];
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self,
            QPPrefsChangedCallback,
            CFSTR(kQPPrefsChangedNotification),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

- (void)reload {
    _raw = [NSDictionary dictionaryWithContentsOfFile:kQPPrefsPlistPath] ?: @{};
    
    _enabled = _raw[@"enabled"] ? [_raw[@"enabled"] boolValue] : YES;
    _allowDrag = _raw[@"allowDrag"] ? [_raw[@"allowDrag"] boolValue] : YES;
    _haptic = _raw[@"haptic"] ? [_raw[@"haptic"] boolValue] : YES;
    _specularGlow = _raw[@"specularGlow"] ? [_raw[@"specularGlow"] boolValue] : YES;
    _positionPreset = _raw[@"positionPreset"] ? [_raw[@"positionPreset"] integerValue] : QPPositionBottomCenter;
    _buttonStyle = _raw[@"buttonStyle"] ? [_raw[@"buttonStyle"] integerValue] : QPStyleLiquidGlass;
    _iconType = _raw[@"iconType"] ? [_raw[@"iconType"] integerValue] : QPIconKeypadGrid;
    _buttonSize = _raw[@"buttonSize"] ? [_raw[@"buttonSize"] doubleValue] : 50.0;
    _language = _raw[@"language"] ? [_raw[@"language"] integerValue] : 0;

    _hasCustomPosition = _raw[@"hasCustomPosition"] ? [_raw[@"hasCustomPosition"] boolValue] : NO;
    _customX = _raw[@"customX"] ? [_raw[@"customX"] doubleValue] : 0.0;
    _customY = _raw[@"customY"] ? [_raw[@"customY"] doubleValue] : 0.0;
}

- (void)setPref:(id)value forKey:(NSString *)key {
    if (!key.length || !value) return;
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:kQPPrefsPlistPath] mutableCopy] ?: [NSMutableDictionary dictionary];
    dict[key] = value;
    [dict writeToFile:kQPPrefsPlistPath atomically:YES];
    _raw = [dict copy];
    [self reload];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(kQPPrefsChangedNotification), NULL, NULL, true);
}

- (void)resetPosition {
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:kQPPrefsPlistPath] mutableCopy] ?: [NSMutableDictionary dictionary];
    dict[@"hasCustomPosition"] = @NO;
    dict[@"customX"] = @0.0;
    dict[@"customY"] = @0.0;
    dict[@"positionPreset"] = @(QPPositionBottomCenter);
    [dict writeToFile:kQPPrefsPlistPath atomically:YES];
    _raw = [dict copy];
    [self reload];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(kQPPrefsChangedNotification), NULL, NULL, true);
}

@end
