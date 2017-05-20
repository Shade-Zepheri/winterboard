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
        [cachedBundles setObject:bundle == nil ? [NSNull null] : bundle forKey:path];
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
