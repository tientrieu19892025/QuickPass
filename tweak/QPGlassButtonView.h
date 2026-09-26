#import <UIKit/UIKit.h>
#import "QPCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface QPGlassButtonView : UIView

@property (nonatomic, assign) QPButtonStyle buttonStyle;
@property (nonatomic, assign) QPIconType iconType;
@property (nonatomic, assign) BOOL specularGlow;
@property (nonatomic, copy, nullable) void (^onTap)(void);
@property (nonatomic, copy, nullable) void (^onDragEnd)(CGPoint center);

- (void)updateStyle;

@end

NS_ASSUME_NONNULL_END
