#import "QPLocalize.h"
#import "QPPrefs.h"

BOOL QPPreferEnglish(void) {
    NSInteger lang = [QPPrefs shared].language;
    if (lang == 1) return NO; // Vietnamese
    if (lang == 2) return YES; // English
    for (NSString *l in [NSLocale preferredLanguages]) {
        NSString *lower = l.lowercaseString;
        if ([lower hasPrefix:@"vi"]) return NO;
        if ([lower hasPrefix:@"en"]) return YES;
    }
    return NO;
}

NSString *QPLoc(NSString *key) {
    static NSDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{
            @"app_name": @{ @"vi": @"QuickPass", @"en": @"QuickPass" },
            @"app_sub": @{
                @"vi": @"Phím tắt mật khẩu nhanh Face ID · Kính lỏng Liquid Glass",
                @"en": @"Instant Passcode Screen for Face ID · Liquid Glass"
            },
            @"enabled": @{ @"vi": @"Bật QuickPass", @"en": @"Enable QuickPass" },
            @"enabled_desc": @{
                @"vi": @"Kích hoạt nút mở nhanh bàn phím số trên Màn hình khoá.",
                @"en": @"Show instant passcode keypad button on Lock Screen."
            },
            @"allow_drag": @{ @"vi": @"Kéo thả di chuyển trực tiếp", @"en": @"Drag to reposition anywhere" },
            @"allow_drag_desc": @{
                @"vi": @"Chạm giữ và kéo nút đến bất kỳ vị trí nào trên màn hình.",
                @"en": @"Long press & drag the button to any position freely."
            },
            @"haptic": @{ @"vi": @"Rung phản hồi (Haptic)", @"en": @"Haptic Feedback" },
            @"haptic_desc": @{
                @"vi": @"Rung chạm xúc giác nhẹ nhàng khi bấm hoặc kéo.",
                @"en": @"Gentle tactile vibration when tapping or moving."
            },
            @"position_title": @{ @"vi": @"Vị trí nút mặc định", @"en": @"Default Position Preset" },
            @"pos_sub": @{
                @"vi": @"Chọn vị trí cố định hoặc kéo thả tự do trên màn hình.",
                @"en": @"Select preset location or drag freely on Lock Screen."
            },
            @"style_title": @{ @"vi": @"Ngôn ngữ thiết kế nút", @"en": @"Button Appearance Style" },
            @"style_sub": @{
                @"vi": @"Liquid Glass 3D, Mờ tối iOS, Trong suốt hoặc Dạng thanh.",
                @"en": @"Liquid Glass 3D, Frosted Dark, Ultra Clear or Pill."
            },
            @"icon_title": @{ @"vi": @"Biểu tượng đồ hoạ", @"en": @"Icon Graphic" },
            @"icon_sub": @{
                @"vi": @"Biểu tượng hiển thị bên trong nút bấm.",
                @"en": @"Graphic symbol rendered inside the button."
            },
            @"size_title": @{ @"vi": @"Kích thước nút (Size)", @"en": @"Button Size" },
            @"size_sub": @{
                @"vi": @"44px (Nhỏ gọn), 50px (Chuẩn Apple), 58px (Lớn dễ chạm).",
                @"en": @"44px (Compact), 50px (Standard Apple), 58px (Large)."
            },
            @"glow_title": @{ @"vi": @"Hiệu ứng phát sáng (Glow Rim)", @"en": @"Specular Glow Rim" },
            @"glow_desc": @{
                @"vi": @"Viền kính phản xạ ánh sáng nổi bật phong cách Liquid Glass.",
                @"en": @"Specular light reflection rim in Liquid Glass style."
            },
            @"actions": @{ @"vi": @"Thao tác nhanh", @"en": @"Quick Actions" },
            @"reset_pos": @{ @"vi": @"Đặt lại vị trí ban đầu (Giữa)", @"en": @"Reset Button Position" },
            @"respring": @{ @"vi": @"Respring SpringBoard", @"en": @"Respring SpringBoard" },
            @"donate_title": @{ @"vi": @"Ủng hộ tác giả (Donate)", @"en": @"Donate & Support" },
            @"copy_account": @{ @"vi": @"Sao chép số tài khoản MB Bank", @"en": @"Copy MB Bank Account" },
            @"copy_text": @{ @"vi": @"Sao chép nội dung Donate", @"en": @"Copy Donate Message" },
            @"copied": @{ @"vi": @"Đã sao chép vào bộ nhớ tạm!", @"en": @"Copied to clipboard!" },
            @"close": @{ @"vi": @"Đóng", @"en": @"Close" },
            @"ok": @{ @"vi": @"Đồng ý", @"en": @"OK" },
            @"cancel": @{ @"vi": @"Huỷ", @"en": @"Cancel" }
        };
    });

    NSDictionary *sub = dict[key];
    if (!sub) return key;
    NSString *lang = QPPreferEnglish() ? @"en" : @"vi";
    return sub[lang] ?: key;
}
