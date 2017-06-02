#import "NSDictionary.h"

@implementation NSDictionary (WinterBoard)

- (BOOL)wb$boolForKey:(NSString *)key {
    NSString *value = [self objectForKey:key]
    if (value) {
      return [value boolValue];
    }

    return NO;
}

@end
