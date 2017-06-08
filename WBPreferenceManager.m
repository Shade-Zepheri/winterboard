#import "WBPreferenceManager.h"

@implementation WBPreferenceManager

+ (instancetype)sharedPreferences {
    static WBPreferenceManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.themes = [NSMutableArray arrayWithCapacity:8];
        self.info = [NSMutableString dictionaryWithCapacity:16];

        [self loadSettings];
        [self loadInfo];
    }

    return self;
}

- (void)loadSettings {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.saurik.WinterBoard.plist"];
    if (!settings) {
        return;
    }

    if (NSNumber *value = [settings objectForKey:@"Debug"])
        Debug_ = [value boolValue];
    if (NSNumber *value = [settings objectForKey:@"RecordUI"])
        UIDebug_ = [value boolValue];

    NSArray *themes = [settings objectForKey:@"Themes"];
    if (!themes) {
        NSString *theme = [settings objectForKey:@"Theme"]
        if (theme) {
            themes = @[@{@"Name": theme, @"Active": @Yes}];
        }
    }

    if (themes) {
        for (NSDictionary *theme in themes) {
            NSNumber *active = [theme objectForKey:@"Active"];
            if (![active boolValue]) {
                continue;
            }

            NSString *name = [theme objectForKey:@"Name"];
            if (!name) {
                continue;
            }

            #define testForTheme(format...) \
                { \
                    NSString *path = [NSString stringWithFormat:format]; \
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { \
                        [self.themes addObject:path]; \
                        continue; \
                    } \
                }

            testForTheme(@"/Library/Themes/%@.theme", name)
            testForTheme(@"/Library/Themes/%@", name)
            testForTheme(@"%@/Library/SummerBoard/Themes/%@", NSHomeDirectory(), name)

        }
    }
}

- (void)loadInfo {
    for (NSString *theme in self.themes) {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", theme]];
        if (info) {
            for (NSString *key in [info allKeys]) {
                if (![self.info objectForKey:key]) {
                    [self.info setObject:[info objectForKey:key] forKey:key];
                }
            }
        }
    }
}
