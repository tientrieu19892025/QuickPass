#ifndef QPCommon_h
#define QPCommon_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kQPBundleID                 @"com.jinken.quickpass"
#define kQPPrefsChangedNotification "com.jinken.quickpass/SettingsChanged"
#define kQPPrefsPlistPath           @"/var/mobile/Library/Preferences/com.jinken.quickpass.plist"
#define kQPVersion                  @"1.2.0"
#define kQPCredit                   @"Jinken Nguyen - 1989"
#define kQPDonateBank               @"MB Bank"
#define kQPDonateAccount            @"0345140889"
#define kQPDonateName               @"Nguyễn Tiến Triều"
#define kQPDonateText               @"Nếu bạn thấy tweak hữu ích, hãy donate giúp tác giả duy trì và phát triển nhiều tweak hay qua MB Bank - 0345140889 - Nguyễn Tiến Triều"

typedef NS_ENUM(NSInteger, QPPositionPreset) {
    QPPositionBottomCenter = 0,
    QPPositionBelowClock,
    QPPositionBottomRight,
    QPPositionBottomLeft,
    QPPositionCustomDrag,
};

typedef NS_ENUM(NSInteger, QPButtonStyle) {
    QPStyleLiquidGlass = 0, // Liquid Glass 3D (Viền khúc xạ ánh sáng, đổ bóng sâu)
    QPStyleFrostedDark,     // Mờ tối huyền bí (iOS Native Thin Material Dark)
    QPStyleUltraClear,      // Trong suốt tinh khiết (Specular Highlight)
    QPStyleSolidAccent,     // Màu nổi bật (Gradient Accent)
    QPStylePillLabel,       // Thanh chữ con nhộng "Passcode"
};

typedef NS_ENUM(NSInteger, QPIconType) {
    QPIconKeypadGrid = 0,   // Biểu tượng bàn phím số 9 chấm
    QPIconLockCircle,       // Ổ khoá bảo mật
    QPIconShieldCheck,      // Khiên an toàn FaceID
    QPIconTouchDigit,       // Chạm vân tay / số
};

#endif
