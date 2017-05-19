#import "Bundle.h"

@implementation NSBundle (WinterBoard)

+ (NSBundle *) _wb$bundleWithFile:(NSString *)path {
    path = [path stringByDeletingLastPathComponent];
    if (path == nil || [path length] == 0 || [path isEqualToString:@"/"])
        return nil;

    NSBundle *bundle;
    @synchronized (Bundles_) {
        bundle = [Bundles_ objectForKey:path];
    }

    if (reinterpret_cast<id>(bundle) == [NSNull null])
        return nil;
    else if (bundle == nil) {
        if ([Manager_ fileExistsAtPath:[path stringByAppendingPathComponent:@"Info.plist"]])
            bundle = [NSBundle bundleWithPath:path];
        if (bundle == nil)
            bundle = [NSBundle _wb$bundleWithFile:path];
        if (Debug_)
            NSLog(@"WB:Debug:PathBundle(%@, %@)", path, bundle);

        @synchronized (Bundles_) {
            [Bundles_ setObject:(bundle == nil ? [NSNull null] : reinterpret_cast<id>(bundle)) forKey:path];
        }
    }

    return bundle;
}

+ (NSBundle *) wb$bundleWithFile:(NSString *)path {
    if ([path hasPrefix:@"/Library/Themes"])
        return nil;
    return [self _wb$bundleWithFile:path];
}

@end


@implementation NSString (WinterBoard)

- (NSString *) wb$themedPath {
    if (Debug_)
        NSLog(@"WB:Debug:Bypass(\"%@\")", self);

    if (NSBundle *bundle = [NSBundle wb$bundleWithFile:self]) {
        NSString *file([self stringByResolvingSymlinksInPath]);
        NSString *prefix([[bundle bundlePath] stringByResolvingSymlinksInPath]);
        if ([file hasPrefix:prefix]) {
            NSUInteger length([prefix length]);
            if (length != [file length])
                if (NSString *path = $pathForFile$inBundle$([file substringFromIndex:(length + 1)], bundle, false))
                    return path;
        }
    }

    return self;
}

@end
