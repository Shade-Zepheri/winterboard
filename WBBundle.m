#import "WBBundle.h"

@implementation WBBundle

+ (instancetype)bundleWithIdentifier:(NSString *)identifier {
    return [[self alloc] initWithIdentifier:identifier];
}

- (instancetype)initWithIdentifier:(NSString*)identifier {
    self = [super init];
    if (self){
        self.bundleIdentifier = identifier;
    }

    return self;
}

@end
