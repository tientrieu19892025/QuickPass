#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

@interface QPBaseListController : PSListController
@property (nonatomic, strong) NSArray *qpHold;
- (NSString *)qpPlistName;
@end

@interface QPRootListController : QPBaseListController
@end

@interface QPSubListController : QPBaseListController
@property (nonatomic, copy) NSString *plistName;
@end

@interface QPDonateController : QPSubListController
@end

@interface QPAboutController : QPSubListController
@end

@interface QPHeaderCell : PSTableCell
@end
