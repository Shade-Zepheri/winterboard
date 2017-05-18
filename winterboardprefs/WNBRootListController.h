#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

static NSString * const WNBPreferencePath = @"/var/mobile/Library/Preferences/com.saurik.WinterBoard.plist";

@interface WNBRootListController: PSListController {
    NSMutableDictionary *_settings;
}
- (instancetype)initForContentSize:(CGSize)size;
- (void)suspend;
- (void)navigationBarButtonClicked:(int)buttonIndex;
- (void)viewWillRedisplay;
- (void)pushController:(id)controller;
- (NSArray*)specifiers;
- (void)settingsChanged;
- (NSString *)title;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec;
- (id)readPreferenceValue:(PSSpecifier *)spec;

@end
