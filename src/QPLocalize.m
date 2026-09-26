#import "QPLocalize.h"

BOOL QPIsVietnamese(void) {
    NSString *lang = [[NSLocale preferredLanguages] firstObject] ?: @"";
    return [lang hasPrefix:@"vi"];
}

NSString *QPLoc(NSString *key) {
    static NSDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{
            @"app_title": @[@"QuickPass - Mật khẩu nhanh Face ID", @"QuickPass - Quick Passcode for Face ID"],
            @"app_subtitle": @[@"Bấm mở ngay bàn phím mật mã số trên Màn hình khoá", @"Instant Passcode Screen for Face ID Devices"],
            @"enabled": @[@"Bật QuickPass", @"Enable QuickPass"],
            @"enabled_desc": @[@"Thêm nút mở bàn phím mật khẩu số trực tiếp trên Màn hình khoá cho thiết bị Face ID.", @"Add instant passcode keypad button on Lock Screen."],
            @"button_position": @[@"Vị trí nút", @"Button Position"],
            @"button_style": @[@"Kiểu hiển thị nút", @"Button Appearance"],
            @"button_size": @[@"Kích thước nút", @"Button Size"],
            @"haptic_feedback": @[@"Rung phản hồi (Haptic)", @"Haptic Feedback"],
            @"haptic_desc": @[@"Rung xúc giác nhẹ khi bấm nút.", @"Gentle haptic feedback when tapping the button."],
            @"donate_title": @[@"Ủng hộ tác giả (Donate)", @"Donate to Author"],
            @"donate_btn": @[@"Ủng hộ qua MB Bank", @"Donate via MB Bank"],
            @"copy_account": @[@"Sao chép số tài khoản MB Bank", @"Copy MB Bank Account Number"],
            @"copy_message": @[@"Sao chép nội dung ủng hộ", @"Copy Donate Message"],
            @"copied": @[@"Đã sao chép vào bộ nhớ tạm!", @"Copied to clipboard!"],
            @"credit_title": @[@"Thông tin & Bản quyền", @"About & Credits"],
            @"credit_author": @[@"Tác giả: Jinken Nguyen - 1989", @"Author: Jinken Nguyen - 1989"],
            @"respring": @[@"Respring SpringBoard", @"Respring SpringBoard"],
            @"respring_desc": @[@"Khởi động lại SpringBoard để áp dụng thay đổi.", @"Restart SpringBoard to apply modifications."],
            @"ok": @[@"Đồng ý", @"OK"],
            @"cancel": @[@"Huỷ", @"Cancel"]
        };
    });

    NSArray *pair = dict[key];
    if (!pair || pair.count < 2) return key;
    return QPIsVietnamese() ? pair[0] : pair[1];
}
