@interface WBBundle : NSBundle
@property (copy, nonatomic) NSString *bundleIdentifier;
+ (instancetype)bundleWithIdentifier:(NSString*)identifier;
@end
