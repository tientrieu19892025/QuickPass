#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "QPCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface QPPrefs : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL allowDrag;
@property (nonatomic, assign) BOOL haptic;
@property (nonatomic, assign) BOOL specularGlow;
@property (nonatomic, assign) NSInteger positionPreset;
@property (nonatomic, assign) NSInteger buttonStyle;
@property (nonatomic, assign) NSInteger iconType;
@property (nonatomic, assign) CGFloat buttonSize;
@property (nonatomic, assign) NSInteger language; // 0: Auto, 1: VI, 2: EN

// Custom saved coordinate
@property (nonatomic, assign) BOOL hasCustomPosition;
@property (nonatomic, assign) CGFloat customX;
@property (nonatomic, assign) CGFloat customY;

+ (instancetype)shared;
- (void)reload;
- (void)setPref:(id)value forKey:(NSString *)key;
- (void)resetPosition;

@end

NS_ASSUME_NONNULL_END
