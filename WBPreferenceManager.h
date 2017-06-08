#import "headers.h"

@interface WBPreferenceManager : NSObject
@property (strong, nonatomic) NSMutableArray *themes;
@property (strong, nonatomic) NSMutableDictionary *info;
+ (instancetype)sharedPreferences;
@end
