#import "Bundle.h"

static NSMutableDictionary *cachedBundles = nil;

@implementation NSBundle (WinterBoard)

+ (NSBundle *)_wb$bundleWithFile:(NSString *)path {
    path = [path stringByDeletingLastPathComponent];
    if (!path || [path length] == 0 || [path isEqualToString:@"/"]) {
        return nil;
    }

    NSBundle *bundle = nil;
    if (!cachedBundles) {
        cachedBundles = [[NSMutableDictionary alloc] initWithCapacity:5];
    }

    bundle = [cachedBundles objectForKey:path];
    if ((NSNull*)bundle == [NSNull null]) {
        return nil;
    } else if (!bundle) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"Info.plist"]]) {
            bundle = [NSBundle bundleWithPath:path];
        }
        if (!bundle) {
            bundle = [NSBundle _wb$bundleWithFile:path];
        }
        [cachedBundles setObject:!bundle ? [NSNull null] : bundle forKey:path];
    }

    return bundle;
}

+ (NSBundle *)wb$bundleWithFile:(NSString *)path {
    if ([path hasPrefix:@"/Library/Themes"]) {
        return nil;
    }

    return [self _wb$bundleWithFile:path];
}

@end


@implementation NSString (WinterBoard)

- (NSString *)wb$themedPath {
    NSBundle *bundle = [NSBundle wb$bundleWithFile:self];
    if (bundle) {
        NSString *file = [self stringByResolvingSymlinksInPath];
        NSString *prefix = [bundle.bundlePath stringByResolvingSymlinksInPath];
        if ([file hasPrefix:prefix]) {
            NSUInteger length = [prefix length];
            if (length != [file length]) {
                NSString *path = $pathForFile$inBundle$([file substringFromIndex:(length + 1)], bundle, false)
                if (path) {
                    return path;
                }
            }
        }
    }

    return self;
}

@end


%hook NSBundle
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
  NSString *identifier = [self bundleIdentifier];
  NSLocale *locale = [NSLocale currentLocale];
  NSString *language = [locale objectForKey:NSLocaleLanguageCode];
  NSString *file = table == nil ? @"Localizable" : table;
  NSString *name = [NSString stringWithFormat:@"%@:%@", identifier, file];
  NSDictionary *strings;
  if ((strings = [Strings_ objectForKey:name]) != nil) {
      if (static_cast<id>(strings) != [NSNull null]) strings:
          if (NSString *value = [strings objectForKey:key])
              return value;
  } else if (NSString *path = $pathForFile$inBundle$([NSString stringWithFormat:@"%@.lproj/%@.strings",
      language, file
  ], self, false)) {
      if ((strings = [[NSDictionary alloc] initWithContentsOfFile:path]) != nil) {
          [Strings_ setObject:[strings autorelease] forKey:name];
          goto strings;
      } else goto null;
  } else null:
      [Strings_ setObject:[NSNull null] forKey:name];
  return %orig(key, value, table);
}
%end
