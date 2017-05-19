/* WinterBoard - Theme Manager for the iPhone
 * Copyright (C) 2008-2014  Jay Freeman (saurik)
*/

/* GNU Lesser General Public License, Version 3 {{{ */
/*
 * WinterBoard is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * WinterBoard is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with WinterBoard.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */

//Aight time to split this whole thing
#import "headers.h"

static void (*$objc_setAssociatedObject)(id object, void *key, id value, objc_AssociationPolicy policy);
static id (*$objc_getAssociatedObject)(id object, void *key);
static void (*$objc_removeAssociatedObjects)(id object);

@protocol WinterBoard
- (void *) _node;
@end

Class $MPMoviePlayerController;
Class $MPVideoView;

MSClassHook(NSBundle)
MSClassHook(NSString)
MSClassHook(NSAttributedString)

MSClassHook(_UIAssetManager)
MSClassHook(UIImage)
MSMetaClassHook(UIImage)
MSClassHook(UINavigationBar)
MSClassHook(UISharedArtwork)
MSClassHook(UIToolbar)
MSClassHook(UIStatusBarTimeItemView)
MSClassHook(UIWebDocumentView)

MSClassHook(CKBalloonView)
MSClassHook(CKMessageCell)
MSClassHook(CKTimestampView)
MSClassHook(CKTranscriptCell)
MSClassHook(CKTranscriptController)
MSClassHook(CKTranscriptHeaderView)
MSClassHook(CKTranscriptTableView)

MSClassHook(SBApplication)
MSClassHook(SBApplicationIcon)
MSClassHook(SBAwayView)
MSClassHook(SBBookmarkIcon)
MSClassHook(SBButtonBar)
MSClassHook(SBCalendarApplicationIcon)
MSClassHook(SBCalendarIconContentsView)
MSClassHook(SBDockIconListView)
MSClassHook(SBIcon)
MSClassHook(SBIconAccessoryImage)
MSMetaClassHook(SBIconAccessoryImage)
MSClassHook(SBIconBadge)
MSClassHook(SBIconBadgeFactory)
MSClassHook(SBIconBadgeImage)
MSClassHook(SBIconBadgeView)
MSMetaClassHook(SBIconBadgeView)
MSClassHook(SBIconContentView)
MSClassHook(SBIconController)
MSClassHook(SBIconLabel)
MSClassHook(SBIconLabelImage)
MSMetaClassHook(SBIconLabelImage)
MSClassHook(SBIconLabelImageParameters)
MSClassHook(SBIconList)
MSClassHook(SBIconModel)
MSClassHook(SBIconView)
MSMetaClassHook(SBIconView)
//MSClassHook(SBImageCache)
MSClassHook(SBSearchView)
MSClassHook(SBSearchTableViewCell)
MSClassHook(SBSlidingAlertDisplay)
MSClassHook(SBStatusBarContentsView)
MSClassHook(SBStatusBarController)
MSClassHook(SBStatusBarOperatorNameView)
MSClassHook(SBStatusBarTimeView)
MSClassHook(SBUIController)
MSClassHook(SBWallpaperView)
MSClassHook(SBWidgetApplicationIcon)

extern "C" void WKSetCurrentGraphicsContext(CGContextRef);

static struct MSFixClass { MSFixClass() {
    $UIWebDocumentView = objc_getClass("UIWebBrowserView") ?: $UIWebDocumentView;
    $SBIcon = objc_getClass("SBIconView") ?: $SBIcon;

    if ($SBIconList == nil)
        $SBIconList = objc_getClass("SBIconListView");
    if ($CKTranscriptController == nil)
        $CKTranscriptController = objc_getClass("mSMSMessageTranscriptController");
} } MSFixClass;

static bool IsWild_;
static bool Four_($SBDockIconListView != nil);

static BOOL (*_GSFontGetUseLegacyFontMetrics)();
#define $GSFontGetUseLegacyFontMetrics() \
    (_GSFontGetUseLegacyFontMetrics == NULL ? YES : _GSFontGetUseLegacyFontMetrics())

static bool Debug_ = false;
static bool UIDebug_ = false;
static bool Engineer_ = false;
static bool SummerBoard_ = false;
static bool SpringBoard_;

static UIImage *(*_UIApplicationImageWithName)(NSString *name);
static UIImage *(*_UIImageWithNameInDomain)(NSString *name, NSString *domain);
static NSBundle *(*_UIKitBundle)();

static NSMutableDictionary *Images_ = [[NSMutableDictionary alloc] initWithCapacity:64];
static NSMutableDictionary *Cache_ = [[NSMutableDictionary alloc] initWithCapacity:64];
static NSMutableDictionary *Strings_ = [[NSMutableDictionary alloc] initWithCapacity:0];
static NSMutableDictionary *Bundles_ = [[NSMutableDictionary alloc] initWithCapacity:2];

static NSFileManager *Manager_;
static NSMutableArray *Themes_;

static NSDictionary *English_;
static NSMutableDictionary *Info_;

static NSMutableDictionary *Themed_ = [[NSMutableDictionary alloc] initWithCapacity:128];

static unsigned Scale_ = 0;

static unsigned $getScale$(NSString *path) {
    NSString *name(path);

    #define StripName(strip) \
        if ([name hasSuffix:@ strip]) \
            name = [name substringWithRange:NSMakeRange(0, [name length] - sizeof(strip) - 1)];

    StripName(".png");
    StripName(".jpg");
    StripName("~iphone");
    StripName("~ipad");

    if ([name hasSuffix:@"@3x"])
        return 3;
    if ([name hasSuffix:@"@2x"])
        return 2;
    return 1;
}

static NSArray *$useScale$(NSArray *files, bool use = true) {
    if (use && Scale_ == 0) {
        UIScreen *screen([UIScreen mainScreen]);
        if ([screen respondsToSelector:@selector(scale)])
            Scale_ = [screen scale];
        else
            Scale_ = 1;
    }

    NSString *idiom(IsWild_ ? @"ipad" : @"iphone");

    NSMutableArray *scaled([NSMutableArray arrayWithCapacity:([files count] * 6)]);

    for (NSString *file in files) {
        NSString *base([file stringByDeletingPathExtension]);
        NSString *extension([file pathExtension]);

#define WBScaleImage(scale) \
    if (scale == 1) { \
        [scaled addObject:[NSString stringWithFormat:@"%@~%@.%@", base, idiom, extension]]; \
        [scaled addObject:file]; \
    } else { \
        [scaled addObject:[NSString stringWithFormat:@"%@@%ux~%@.%@", base, scale, idiom, extension]]; \
        [scaled addObject:[NSString stringWithFormat:@"%@@%ux.%@", base, scale, extension]]; \
    }

        if (use) {
            WBScaleImage(Scale_);

            for (unsigned scale(3); scale >= 1; --scale) {
              if (scale != Scale_) {
                WBScaleImage(scale);
              }
            }
        } else if ([base hasSuffix: @"@2x"] || [base hasSuffix:@"@3x"]) {
            WBScaleImage(1);

            // XXX: this actually can't be used, as the person loading the file doesn't realize that the @2x changed
            /*NSString *rest([base substringWithRange:NSMakeRange(0, [base length] - 3)]);
            [scaled addObject:[NSString stringWithFormat:@"%@~%@.%@", rest, idiom, extension]];
            [scaled addObject:[rest stringByAppendingPathExtension:extension]];*/
        } else {
            // XXX: this code isn't really complete

            [scaled addObject:file];

            if ([base hasSuffix:[NSString stringWithFormat:@"~%@", idiom]])
                [scaled addObject:[[base substringWithRange:NSMakeRange(0, [base length] - 1 - [idiom length])] stringByAppendingPathExtension:extension]];
        }
    }

    return scaled;
}

static NSString *$getTheme$(NSArray *files, NSArray *themes = Themes_) {
    // XXX: this is not reasonable; OMG
    id key(files);

    @synchronized (Themed_) {
        if (NSString *path = [Themed_ objectForKey:key])
            return reinterpret_cast<id>(path) == [NSNull null] ? nil : path;
    }

    if (Debug_)
        NSLog(@"WB:Debug: %@", [files description]);

    NSString *path;

    for (NSString *theme in Themes_)
        for (NSString *file in files) {
            path = [NSString stringWithFormat:@"%@/%@", theme, file];
            if ([Manager_ fileExistsAtPath:path]) {
                if ([[Manager_ destinationOfSymbolicLinkAtPath:path error:NULL] isEqualToString:@"/"])
                    path = nil;
                goto set;
            }
        }

    path = nil;
  set:

    @synchronized (Themed_) {
        [Themed_ setObject:(path == nil ? [NSNull null] : reinterpret_cast<id>(path)) forKey:key];
    }

    return path;
}
// }}}
// $pathForFile$inBundle$() {{{
static void $pathForFile$inBundle$(NSMutableArray *names, NSString *file, NSString *identifier, NSString *folder) {
    if (identifier != nil)
        [names addObject:[NSString stringWithFormat:@"Bundles/%@/%@", identifier, file]];
    if (folder != nil) {
        [names addObject:[NSString stringWithFormat:@"Folders/%@/%@", folder, file]];
        NSString *base([folder stringByDeletingPathExtension]);
        if ([base hasSuffix:@"~iphone"])
            [names addObject:[NSString stringWithFormat:@"Folders/%@.%@/%@", [base substringWithRange:NSMakeRange(0, [base length] - 7)], [folder pathExtension], file]];
        if ([base hasSuffix:@"~ipad"])
            [names addObject:[NSString stringWithFormat:@"Folders/%@.%@/%@", [base substringWithRange:NSMakeRange(0, [base length] - 5)], [folder pathExtension], file]];
    }

    #define remapResourceName(oldname, newname) \
        else if ([file isEqualToString:(oldname)]) \
            [names addObject:oldname ".png"];

    bool summer(SpringBoard_ && SummerBoard_);

    if (identifier == nil);
    else if ([identifier isEqualToString:@"com.apple.uikit.Artwork"])
        $pathForFile$inBundle$(names, file, @"com.apple.UIKit", @"UIKit.framework");
    else if ([identifier isEqualToString:@"com.apple.uikit.LegacyArtwork"])
        $pathForFile$inBundle$(names, file, @"com.apple.UIKit", @"UIKit.framework");
    else if ([identifier isEqualToString:@"com.apple.UIKit"])
        [names addObject:[NSString stringWithFormat:@"UIImages/%@", file]];
    else if ([identifier isEqualToString:@"com.apple.chatkit"])
        $pathForFile$inBundle$(names, file, @"com.apple.MobileSMS", @"MobileSMS.app");
    else if ([identifier isEqualToString:@"com.apple.calculator"])
        [names addObject:[NSString stringWithFormat:@"Files/Applications/Calculator.app/%@", file]];
    else if ([identifier isEqualToString:@"com.apple.Maps"] && [file isEqualToString:@"Icon-57@2x.png"])
        $pathForFile$inBundle$(names, @"icon.png", identifier, folder);
    else if (!summer);
        remapResourceName(@"FSO_BG.png", @"StatusBar")
        remapResourceName(Four_ ? @"SBDockBG-old.png" : @"SBDockBG.png", @"Dock")
        remapResourceName(@"SBWeatherCelsius.png", @"Icons/Weather")
}

static NSString *$pathForFile$inBundle$(NSString *file, NSString *identifier, NSURL *url, bool use) {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:8];
    $pathForFile$inBundle$(names, file, identifier, [url lastPathComponent]);
    [names addObject:[NSString stringWithFormat:@"Fallback/%@", file]];
    if (NSString *path = $getTheme$($useScale$(names, use)))
        return path;
    return nil;
}

// XXX: this cannot be merged due to WBBundle
static NSString *$pathForFile$inBundle$(NSString *file, NSBundle *bundle, bool use) {
    return $pathForFile$inBundle$(file, [bundle bundleIdentifier], [bundle bundleURL], use);
}

static NSString *$pathForFile$inBundle$(NSString *file, CFBundleRef bundle, bool use) {
    NSString *identifier((NSString *) CFBundleGetIdentifier(bundle));
    NSURL *url([(NSURL *) CFBundleCopyBundleURL(bundle) autorelease]);
    return $pathForFile$inBundle$(file, identifier, url, use);
}
// }}}

static NSString *$pathForIcon$(SBApplication *self, NSString *suffix = @"") {
    NSString *identifier = [self bundleIdentifier];
    NSString *path = [self path];
    NSString *folder = [path lastPathComponent];
    NSString *dname = [self displayName];

    NSString *didentifier;
    if ([self respondsToSelector:@selector(displayIdentifier)])
        didentifier = [self displayIdentifier];
    else
        didentifier = nil;

    if (Debug_)
        NSLog(@"WB:Debug: [SBApplication(%@:%@:%@:%@) pathForIcon]", identifier, folder, dname, didentifier);

    NSMutableArray *names = [NSMutableArray arrayWithCapacity:8];

    /* XXX: I might need to keep this for backwards compatibility
    if (identifier != nil)
        [names addObject:[NSString stringWithFormat:@"Bundles/%@/icon.png", identifier]];
    if (folder != nil)
        [names addObject:[NSString stringWithFormat:@"Folders/%@/icon.png", folder]]; */

    #define testForIcon(Name) \
        if (NSString *name = Name) \
            [names addObject:[NSString stringWithFormat:@"Icons%@/%@.png", suffix, name]];

    if (didentifier != nil && ![didentifier isEqualToString:identifier])
        testForIcon(didentifier);

    testForIcon(identifier);
    testForIcon(dname);

    if ([identifier isEqualToString:@"com.apple.MobileSMS"])
        testForIcon(@"SMS");

    if (didentifier != nil) {
        testForIcon([English_ objectForKey:didentifier]);

        NSArray *parts = [didentifier componentsSeparatedByString:@"-"];
        if ([parts count] != 1)
            if (NSDictionary *english = [[[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingString:@"/English.lproj/UIRoleDisplayNames.strings"]] autorelease])
                testForIcon([english objectForKey:[parts lastObject]]);
    }

    if (NSString *path = $getTheme$(names))
        return path;

    return nil;
}

// -[NSBundle wb$bundleWithFile] {{{
@interface NSBundle (WinterBoard)
+ (NSBundle *) wb$bundleWithFile:(NSString *)path;
@end

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
// }}}
// -[NSString wb$themedPath] {{{
@interface NSString (WinterBoard)
- (NSString *) wb$themedPath;
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
// }}}

void WBLogRect(const char *tag, struct CGRect rect) {
    NSLog(@"%s:{%f,%f+%f,%f}", tag, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

void WBLogHierarchy(UIView *view, unsigned index = 0, unsigned indent = 0) {
    CGRect frame([view frame]);
    NSLog(@"%*s|%2d:%p:%s : {%f,%f+%f,%f} (%@)", indent * 3, "", index, view, class_getName([view class]), frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, [view backgroundColor]);
    index = 0;
    for (UIView *child in [view subviews])
        WBLogHierarchy(child, index++, indent + 1);
}

UIImage *$cacheForImage$(UIImage *image) {
    CGColorSpaceRef space(CGColorSpaceCreateDeviceRGB());
    CGRect rect = {CGPointMake(1, 1), [image size]};
    CGSize size = {rect.size.width + 2, rect.size.height + 2};

    CGContextRef context(CGBitmapContextCreate(NULL, size.width, size.height, 8, 4 * size.width, space, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    CGColorSpaceRelease(space);

    CGContextDrawImage(context, rect, [image CGImage]);
    CGImageRef ref(CGBitmapContextCreateImage(context));
    CGContextRelease(context);

    UIImage *cache([UIImage imageWithCGImage:ref]);
    CGImageRelease(ref);

    return cache;
}

/*MSHook(id, SBImageCache$initWithName$forImageWidth$imageHeight$initialCapacity$, SBImageCache *self, SEL sel, NSString *name, unsigned width, unsigned height, unsigned capacity) {
    //if ([name isEqualToString:@"icons"]) return nil;
    return _SBImageCache$initWithName$forImageWidth$imageHeight$initialCapacity$(self, sel, name, width, height, capacity);
}*/


static UIImage *CachedImageAtPath(NSString *path) {
    path = [path stringByResolvingSymlinksInPath];
    UIImage *image = [Images_ objectForKey:path];
    if (image != nil)
        return reinterpret_cast<id>(image) == [NSNull null] ? nil : image;
    image = [[UIImage alloc] initWithContentsOfFile:path cache:true];
    if (image != nil)
        image = [image autorelease];
    [Images_ setObject:(image == nil ? [NSNull null] : reinterpret_cast<id>(image)) forKey:path];
    return image;
}

MSHook(UIImage *, _UIApplicationImageWithName, NSString *name) {
    NSBundle *bundle = [NSBundle mainBundle];
    if (Debug_)
        NSLog(@"WB:Debug: _UIApplicationImageWithName(\"%@\", %@)", name, bundle);
    if (NSString *path = $pathForFile$inBundle$(name, bundle, false))
        return CachedImageAtPath(path);
    return __UIApplicationImageWithName(name);
}

#define WBDelegate(delegate) \
    - (NSMethodSignature*) methodSignatureForSelector:(SEL)sel { \
        if (Engineer_) \
            NSLog(@"WB:MS:%s:(%s)", class_getName([self class]), sel_getName(sel)); \
        if (NSMethodSignature *sig = [delegate methodSignatureForSelector:sel]) \
            return sig; \
        NSLog(@"WB:Error: [%s methodSignatureForSelector:(%s)]", class_getName([self class]), sel_getName(sel)); \
        return nil; \
    } \
\
    - (void) forwardInvocation:(NSInvocation*)inv { \
        SEL sel = [inv selector]; \
        if ([delegate respondsToSelector:sel]) \
            [inv invokeWithTarget:delegate]; \
        else \
            NSLog(@"WB:Error: [%s forwardInvocation:(%s)]", class_getName([self class]), sel_getName(sel)); \
    }

// %hook CFBundleCopyResourceURL {{{
MSHook(CFURLRef, CFBundleCopyResourceURL, CFBundleRef bundle, CFStringRef resourceName, CFStringRef resourceType, CFStringRef subDirName) {
    NSString *file((NSString *) resourceName);
    if (resourceType != NULL)
        file = [NSString stringWithFormat:@"%@.%@", file, resourceType];
    if (subDirName != NULL)
        file = [NSString stringWithFormat:@"%@/%@", subDirName, resourceType];

    if (![file hasSuffix:@".png"]) {
        if (Debug_)
            NSLog(@"WB:Debug: CFBundleCopyResourceURL(<%@>, \"%@\", \"%@\", \"%@\")", CFBundleGetIdentifier(bundle), resourceName, resourceType, subDirName);
        if (NSString *path = $pathForFile$inBundle$(file, bundle, false))
            return (CFURLRef) [[NSURL alloc] initFileURLWithPath:path];
    }

    return _CFBundleCopyResourceURL(bundle, resourceName, resourceType, subDirName);
}
// }}}

static void $drawLabel$(NSString *label, CGRect rect, NSString *style, NSString *custom) {
    bool ellipsis(false);
    CGFloat max = rect.size.width - 11, width;
  width:
    width = [(ellipsis ? [label stringByAppendingString:@"..."] : label) sizeWithStyle:style forWidth:320].width;

    if (width > max) {
        size_t length([label length]);
        CGFloat spacing((width - max) / (length - 1));

        if (spacing > 1.25) {
            ellipsis = true;
            label = [label substringToIndex:(length - 1)];
            goto width;
        }

        style = [style stringByAppendingString:[NSString stringWithFormat:@"letter-spacing: -%f; ", spacing]];
    }

    if (ellipsis)
        label = [label stringByAppendingString:@"..."];

    if (custom != nil)
        style = [style stringByAppendingString:custom];

    CGSize size = [label sizeWithStyle:style forWidth:rect.size.width];
    [label drawAtPoint:CGPointMake((rect.size.width - size.width) / 2 + rect.origin.x, rect.origin.y) withStyle:style];
}

static struct WBStringDrawingState {
    WBStringDrawingState *next_;
    unsigned count_;
    NSString *base_;
    NSString *info_;
} *stringDrawingState_;

extern "C" CGColorSpaceRef CGContextGetFillColorSpace(CGContextRef);
extern "C" void CGContextGetFillColor(CGContextRef, CGFloat[]);

static NSString *WBColorMarkup(size_t number, const CGFloat *components) {
    CGFloat r, g, b, a;

    switch (number) {
        case 1:
            r = components[0];
            g = components[0];
            b = components[0];
            a = components[1];
        break;

        case 3:
            r = components[0];
            g = components[1];
            b = components[2];
            a = components[3];
        break;

        default:
            return @"";
    }

    return [NSString stringWithFormat:@"color: rgba(%g, %g, %g, %g)", r * 255, g * 255, b * 255, a];
}

static NSString *WBColorMarkup() {
    CGContextRef context(UIGraphicsGetCurrentContext());
    //NSLog(@"XXX:1:%p", context);
    if (context == NULL)
        return @"";

    CGColorSpaceRef space(CGContextGetFillColorSpace(context));
    //NSLog(@"XXX:2:%p", space);
    if (space == NULL)
        return @"";

    size_t number(CGColorSpaceGetNumberOfComponents(space));
    //NSLog(@"XXX:3:%u", number);
    if (number == 0)
        return @"";

    CGFloat components[number + 1];
    CGContextGetFillColor(context, components);
    return WBColorMarkup(number, components);
}

static NSString *WBColorMarkup(UIColor *uicolor) {
    if (uicolor == nil)
        return @"";
    CGColorRef cgcolor([uicolor CGColor]);
    if (cgcolor == NULL)
        return @"";

    CGColorSpaceRef space(CGColorGetColorSpace(cgcolor));
    //NSLog(@"XXX:2:%p", space);
    if (space == NULL)
        return @"";

    size_t number(CGColorGetNumberOfComponents(cgcolor));
    //NSLog(@"XXX:3:%u", number);
    if (number == 0)
        return @"";

    const CGFloat *components(CGColorGetComponents(cgcolor));
    return WBColorMarkup(number, components);
}

extern "C" NSString *NSStringFromCGPoint(CGPoint rect);

MSInstanceMessage6(CGSize, NSString, drawAtPoint,forWidth,withFont,lineBreakMode,letterSpacing,includeEmoji, CGPoint, point, CGFloat, width, UIFont *, font, UILineBreakMode, mode, CGFloat, spacing, BOOL, emoji) {
    //NSLog(@"XXX: @\"%@\" %@ %g \"%@\" %u %g %u", self, NSStringFromCGPoint(point), width, font, mode, spacing, emoji);

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(point, width, font, mode, spacing, emoji);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(point, width, font, mode, spacing, emoji);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(point, width, font, mode, spacing, emoji);

    NSString *base(state->base_ ?: @"");
    NSString *extra([NSString stringWithFormat:@"letter-spacing: %gpx", spacing]);
    [self drawAtPoint:point withStyle:[NSString stringWithFormat:@"%@;%@;%@;%@;%@", [font markupDescription], WBColorMarkup(), extra, base, info]];
    return CGSizeZero;
}

MSInstanceMessage1(void, NSAttributedString, drawAtPoint, CGPoint, point) {
    //NSLog(@"XXX: @\"%@\" %@", self, NSStringFromCGPoint(point));

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(point);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(point);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(point);

    NSDictionary *attributes([self attributesAtIndex:0 effectiveRange:NULL]);

    UIFont *font([attributes objectForKey:@"NSFont"]);

    NSString *base(state->base_ ?: @"");
    [[self string] drawAtPoint:point withStyle:[NSString stringWithFormat:@"%@;%@;%@;%@", [font markupDescription], WBColorMarkup(), base, info]];
}

extern "C" NSString *NSStringFromCGRect(CGRect rect);

MSInstanceMessageHook7(CGSize, NSString, _drawInRect,withFont,lineBreakMode,alignment,lineSpacing,includeEmoji,truncationRect, CGRect, rect, UIFont *, font, UILineBreakMode, mode, UITextAlignment, alignment, float, spacing, BOOL, emoji, CGRect, truncation) {
    //NSLog(@"XXX: @\"%@\" %@ \"%@\" %u %u %g %u %@", self, NSStringFromCGRect(rect), font, mode, alignment, spacing, emoji, NSStringFromCGRect(truncation));

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(rect, font, mode, alignment, spacing, emoji, truncation);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(rect, font, mode, alignment, spacing, emoji, truncation);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(rect, font, mode, alignment, spacing, emoji, truncation);

    NSString *textAlign;
    switch (alignment) {
        default:
        case UITextAlignmentLeft:
            textAlign = @"left";
            break;
        case UITextAlignmentCenter:
            textAlign = @"center";
            break;
        case UITextAlignmentRight:
            textAlign = @"right";
            break;
    }

    NSString *base(state->base_ ?: @"");
    NSString *extra([NSString stringWithFormat:@"text-align: %@", textAlign]);

    if (true)
        $drawLabel$(self, rect, [NSString stringWithFormat:@"%@;%@;%@", [font markupDescription], WBColorMarkup(), base], info);
    else
        [self drawInRect:rect withStyle:[NSString stringWithFormat:@"%@;%@;%@;%@;%@", [font markupDescription], WBColorMarkup(), extra, base, info]];

    return CGSizeZero;
}

MSInstanceMessage2(void, NSString, drawInRect,withAttributes, CGRect, rect, NSDictionary *, attributes) {
    //NSLog(@"XXX: *\"%@\" %@", self, attributes);

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(rect, attributes);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(rect, attributes);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(rect, attributes);

    NSString *base(state->base_ ?: @"");

    UIFont *font([attributes objectForKey:@"NSFont"]);
    UIColor *color([attributes objectForKey:@"NSColor"]);

    [self drawInRect:rect withStyle:[NSString stringWithFormat:@"%@;%@;%@;%@", [font markupDescription], WBColorMarkup(color), base, info]];
}

extern "C" NSString *NSStringFromCGSize(CGSize size);

MSInstanceMessage4(CGRect, NSString, boundingRectWithSize,options,attributes,context, CGSize, size, NSInteger, options, NSDictionary *, attributes, id, context) {
    //NSLog(@"XXX: $\"%@\" %@ 0x%x %@ %@", self, NSStringFromCGSize(size), unsigned(options), attributes, context);

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(size, options, attributes, context);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(size, options, attributes, context);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(size, options, attributes, context);

    NSString *base(state->base_ ?: @"");

    UIFont *font([attributes objectForKey:@"NSFont"]);
    UIColor *color([attributes objectForKey:@"NSColor"]);

    return (CGRect) {{0, 0}, [self sizeWithStyle:[NSString stringWithFormat:@"%@;%@;%@;%@", [font markupDescription], WBColorMarkup(color), base, info] forWidth:size.width]};
}

MSInstanceMessage3(CGRect, NSAttributedString, boundingRectWithSize,options,context, CGSize, size, NSInteger, options, id, context) {
    //NSLog(@"XXX: $\"%@\" %@ 0x%x %@", self, NSStringFromCGSize(size), unsigned(options), context);

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(size, options, context);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(size, options, context);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(size, options, context);

    NSString *base(state->base_ ?: @"");

    NSDictionary *attributes([self attributesAtIndex:0 effectiveRange:NULL]);

    UIFont *font([attributes objectForKey:@"NSFont"]);
    UIColor *color([attributes objectForKey:@"NSColor"]);

    MSOldCall(size, options, context);
    return (CGRect) {{0, 0}, [[self string] sizeWithStyle:[NSString stringWithFormat:@"%@;%@;%@;%@", [font markupDescription], WBColorMarkup(color), base, info] forWidth:size.width]};
}

MSInstanceMessage4(CGSize, NSString, sizeWithFont,forWidth,lineBreakMode,letterSpacing, UIFont *, font, CGFloat, width, UILineBreakMode, mode, CGFloat, spacing) {
    //NSLog(@"XXX: #\"%@\" \"%@\" %g %u %g", self, font, width, mode, spacing);

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(font, width, mode, spacing);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(font, width, mode, spacing);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(font, width, mode, spacing);

    NSString *base(state->base_ ?: @"");
    NSString *extra([NSString stringWithFormat:@"letter-spacing: %gpx", spacing]);
    return [self sizeWithStyle:[NSString stringWithFormat:@"%@;%@;%@;%@;%@", [font markupDescription], WBColorMarkup(), extra, base, info] forWidth:width];
}

MSInstanceMessage1(CGSize, NSString, sizeWithFont, UIFont *, font) {
    //NSLog(@"XXX: ?\"%@\"", self);

    WBStringDrawingState *state(stringDrawingState_);
    if (state == NULL)
        return MSOldCall(font);

    if (state->count_ != 0 && --state->count_ == 0)
        stringDrawingState_ = state->next_;
    if (state->info_ == nil)
        return MSOldCall(font);

    NSString *info([Info_ objectForKey:state->info_]);
    if (info == nil)
        return MSOldCall(font);

    NSString *base(state->base_ ?: @"");
    return [self sizeWithStyle:[NSString stringWithFormat:@"%@;%@;%@;%@", [font markupDescription], WBColorMarkup(), base, info] forWidth:65535];
}

MSClassMessageHook2(id, SBIconBadgeView, checkoutAccessoryImagesForIcon,location, id, icon, int, location) {
    WBStringDrawingState badgeState = {NULL, 0, @""
    , @"BadgeStyle"};

    stringDrawingState_ = &badgeState;

    id images(MSOldCall(icon, location));

    stringDrawingState_ = NULL;
    return images;
}

MSClassMessageHook2(UIImage *, SBIconAccessoryImage, checkoutAccessoryImageForIcon,location, id, icon, int, location) {
    if ([self _imageClassForIcon:icon location:location] != $SBIconBadgeImage)
        return MSOldCall(icon, location);

    WBStringDrawingState badgeState = {NULL, 0, @""
    , @"BadgeStyle"};

    stringDrawingState_ = &badgeState;

    UIImage *image(MSOldCall(icon, location));

    stringDrawingState_ = NULL;
    return image;
}

MSInstanceMessageHook1(UIImage *, SBIconBadgeFactory, checkoutBadgeImageForText, NSString *, text) {
    WBStringDrawingState badgeState = {NULL, 0, @""
    , @"BadgeStyle"};

    stringDrawingState_ = &badgeState;

    UIImage *image(MSOldCall(text));

    stringDrawingState_ = NULL;
    return image;
}

MSInstanceMessageHook1(UIImage *, SBCalendarApplicationIcon, generateIconImage, int, type) {
    WBStringDrawingState dayState = {NULL, unsigned(kCFCoreFoundationVersionNumber >= 1200 ? 3 : 2), @""
        // XXX: this is only correct on an iPod dock
        "text-shadow: rgba(0, 0, 0, 0.2) -1px -1px 2px;"
    , @"CalendarIconDayStyle"};

    unsigned skips;
    if (kCFCoreFoundationVersionNumber < 800)
        skips = 7;
    else if (kCFCoreFoundationVersionNumber < 1200)
        skips = 16;
    else
        skips = 7;

    WBStringDrawingState skipState = {&dayState, skips, nil, nil};

    WBStringDrawingState dateState = {&skipState, 2, @""
    , @"CalendarIconDateStyle"};

    stringDrawingState_ = &dateState;

    UIImage *image(MSOldCall(type));

    stringDrawingState_ = NULL;
    return image;
}

MSInstanceMessageHook1(UIImage *, UIStatusBarTimeItemView, contentsImageForStyle, int, style) {
    WBStringDrawingState timeState = {NULL, 0, @""
    , @"TimeStyle"};

    stringDrawingState_ = &timeState;

    UIImage *image(MSOldCall(style));

    stringDrawingState_ = NULL;
    return image;
}

// %hook -[{NavigationBar,Toolbar} setBarStyle:] {{{
void $setBarStyle$_(NSString *name, int &style) {
    if (Debug_)
        NSLog(@"WB:Debug:%@Style:%d", name, style);
    NSNumber *number = nil;
    if (number == nil)
        number = [Info_ objectForKey:[NSString stringWithFormat:@"%@Style-%d", name, style]];
    if (number == nil)
        number = [Info_ objectForKey:[NSString stringWithFormat:@"%@Style", name]];
    if (number != nil) {
        style = [number intValue];
        if (Debug_)
            NSLog(@"WB:Debug:%@Style=%d", name, style);
    }
}

MSInstanceMessageHook1(void, UIToolbar, setBarStyle, int, style) {
    $setBarStyle$_(@"Toolbar", style);
    return MSOldCall(style);
}

MSInstanceMessageHook1(void, UINavigationBar, setBarStyle, int, style) {
    $setBarStyle$_(@"NavigationBar", style);
    return MSOldCall(style);
}
// }}}


static NSArray *Wallpapers_;
static bool Papered_;
static bool Docked_;
static bool SMSBackgrounded_;
static NSString *WallpaperFile_;
static UIImageView *WallpaperImage_;
static UIWebDocumentView *WallpaperPage_;
static NSURL *WallpaperURL_;

#define _release(object) \
    do if (object != nil) { \
        [object release]; \
        object = nil; \
    } while (false)

static UIImage *$getImage$(NSString *path) {
    UIImage *image([UIImage imageWithContentsOfFile:path]);

    unsigned scale($getScale$(path));
    if (scale != 1 && [image respondsToSelector:@selector(setScale)])
        [image setScale:scale];

    return image;
}

template <typename Original_, typename Modified_>
_finline UIImage *WBCacheImage(const Modified_ &modified, const Original_ &original, NSString *key) {
    UIImage *image([Images_ objectForKey:key]);
    if (image != nil)
        return reinterpret_cast<id>(image) == [NSNull null] ? original() : image;
    if (NSString *path = modified())
        image = $getImage$(path);
    [Images_ setObject:(image == nil ? [NSNull null] : reinterpret_cast<id>(image)) forKey:key];
    return image == nil ? original() : image;
}

static UIImage *$getDefaultDesktopImage$() {
    if (NSString *path = $getTheme$($useScale$([NSArray arrayWithObjects:@"LockBackground.png", @"LockBackground.jpg", nil])))
        return $getImage$(path);
    return nil;
}

MSClassMessageHook0(UIImage *, UIImage, defaultDesktopImage) {
    return $getDefaultDesktopImage$() ?: MSOldCall();
}

// %hook -[SBUIController init] {{{
// }}}
\

/*extern "C" CGColorRef CGGStateGetSystemColor(void *);
extern "C" CGColorRef CGGStateGetFillColor(void *);
extern "C" CGColorRef CGGStateGetStrokeColor(void *);
extern "C" NSString *UIStyleStringFromColor(CGColorRef);*/

/* WBBadgeLabel {{{ */


/* }}} */

// IconAlpha {{{
// }}}

/*MSHook(id, SBStatusBarContentsView$initWithStatusBar$mode$, SBStatusBarContentsView *self, SEL sel, id bar, int mode) {
    if (NSNumber *number = [Info_ objectForKey:@"StatusBarContentsMode"])
        mode = [number intValue];
    return _SBStatusBarContentsView$initWithStatusBar$mode$(self, sel, bar, mode);
}*/

@interface UIView (WinterBoard)
- (bool) wb$isWBImageView;
- (void) wb$logHierarchy;
- (void) wb$setBackgroundColor:(UIColor *)color;
@end

@implementation UIView (WinterBoard)

- (bool) wb$isWBImageView {
    return false;
}

- (void) wb$logHierarchy {
    WBLogHierarchy(self);
}

- (void) wb$setBackgroundColor:(UIColor *)color {
    [self setBackgroundColor:color];
    for (UIView *child in [self subviews])
        [child wb$setBackgroundColor:color];
}

@end

@interface WBImageView : UIImageView {
}

- (bool) wb$isWBImageView;
- (void) wb$updateFrame;
@end

@implementation WBImageView

- (bool) wb$isWBImageView {
    return true;
}

- (void) wb$updateFrame {
    CGRect frame([self frame]);
    frame.origin.y = 0;

    for (UIView *view(self); ; ) {
        view = [view superview];
        if (view == nil)
            break;
        frame.origin.y -= [view frame].origin.y;
    }

    [self setFrame:frame];
}

@end

static void $addPerPageView$(unsigned i, UIView *list) {
    NSString *path($getTheme$([NSArray arrayWithObject:[NSString stringWithFormat:@"Page%u.png", i]]));
    if (path == nil)
        return;

    NSArray *subviews([list subviews]);

    WBImageView *view([subviews count] == 0 ? nil : [subviews objectAtIndex:0]);
    if (view == nil || ![view wb$isWBImageView]) {
        view = [[[WBImageView alloc] init] autorelease];
        [list insertSubview:view atIndex:0];
    }

    UIImage *image([UIImage imageWithContentsOfFile:path]);

    CGRect frame([view frame]);
    frame.size = [image size];
    [view setFrame:frame];

    [view setImage:image];
    [view wb$updateFrame];
}

static void $addPerPageViews$(NSArray *lists) {
    for (unsigned i(0), e([lists count]); i != e; ++i)
        $addPerPageView$(i, [lists objectAtIndex:i]);
}

// %hook -[NSBundle localizedStringForKey:value:table:] {{{
MSInstanceMessageHook3(NSString *, NSBundle, localizedStringForKey,value,table, NSString *, key, NSString *, value, NSString *, table) {
    NSString *identifier = [self bundleIdentifier];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *language = [locale objectForKey:NSLocaleLanguageCode];
    if (Debug_)
        NSLog(@"WB:Debug:[NSBundle(%@) localizedStringForKey:\"%@\" value:\"%@\" table:\"%@\"] (%@)", identifier, key, value, table, language);
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
    return MSOldCall(key, value, table);
}
// }}}
// %hook -[WebCoreFrameBridge renderedSizeOfNode:constrainedToWidth:] {{{
MSClassHook(WebCoreFrameBridge)

MSInstanceMessageHook2(CGSize, WebCoreFrameBridge, renderedSizeOfNode,constrainedToWidth, id, node, float, width) {
    if (node == nil)
        return CGSizeZero;
    void **core(reinterpret_cast<void **>([node _node]));
    if (core == NULL || core[6] == NULL)
        return CGSizeZero;
    return MSOldCall(node, width);
}
// }}}

// ChatKit {{{
MSInstanceMessageHook2(id, CKBalloonView, initWithFrame,delegate, CGRect, frame, id, delegate) {
    if ((self = MSOldCall(frame, delegate)) != nil) {
        [self setBackgroundColor:[UIColor clearColor]];
    } return self;
}

MSInstanceMessageHook0(BOOL, CKBalloonView, _canUseLayerBackedBalloon) {
    return SMSBackgrounded_ ? NO : MSOldCall();
}

MSInstanceMessageHook0(void, CKTranscriptHeaderView, layoutSubviews) {
    [self wb$setBackgroundColor:[UIColor clearColor]];
    return MSOldCall();
}

MSInstanceMessageHook1(void, CKMessageCell, addBalloonView, CKBalloonView *, balloon) {
    MSOldCall(balloon);
    [balloon setBackgroundColor:[UIColor clearColor]];
}

MSInstanceMessageHook1(void, CKTranscriptCell, setBackgroundColor, UIColor *, color) {
    MSOldCall([UIColor clearColor]);
    [[self contentView] wb$setBackgroundColor:[UIColor clearColor]];
}

// iOS >= 5.0
MSInstanceMessageHook2(id, CKTranscriptCell, initWithStyle,reuseIdentifier, int, style, NSString *, reuse) {
    if ((self = MSOldCall(style, reuse)) != nil) {
        [self setBackgroundColor:[UIColor clearColor]];
        [[self contentView] wb$setBackgroundColor:[UIColor clearColor]];
    } return self;
}

// iOS << 5.0
MSInstanceMessageHook2(id, CKMessageCell, initWithStyle,reuseIdentifier, int, style, NSString *, reuse) {
    if ((self = MSOldCall(style, reuse)) != nil) {
        [self setBackgroundColor:[UIColor clearColor]];
        [[self contentView] setBackgroundColor:[UIColor clearColor]];
    } return self;
}

MSInstanceMessageHook2(id, CKTimestampView, initWithStyle,reuseIdentifier, int, style, NSString *, reuse) {
    if ((self = MSOldCall(style, reuse)) != nil) {
        UILabel *&_label(MSHookIvar<UILabel *>(self, "_label"));
        [_label setBackgroundColor:[UIColor clearColor]];
    } return self;
}

MSInstanceMessageHook1(void, CKTranscriptTableView, setSeparatorStyle, int, style) {
    MSOldCall(UITableViewCellSeparatorStyleNone);
}

MSInstanceMessageHook2(id, CKTranscriptTableView, initWithFrame,style, CGRect, frame, int, style) {
    if ((self = MSOldCall(frame, style)) != nil) {
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } return self;
}

MSInstanceMessageHook0(void, CKTranscriptController, loadView) {
    MSOldCall();

    if (NSString *path = $getTheme$($useScale$([NSArray arrayWithObjects:@"SMSBackground.png", @"SMSBackground.jpg", nil])))
        if (UIImage *image = $getImage$(path)) {
            SMSBackgrounded_ = true;

            UIView *_transcriptTable(MSHookIvar<UIView *>(self, "_transcriptTable"));
            UIView *_transcriptLayer(MSHookIvar<UIView *>(self, "_transcriptLayer"));
            UIView *table;
            if (_transcriptTable) {
              table = _transcriptTable;
            } else if (_transcriptLayer) {
              table = _transcriptLayer;
            } else {
              table = nil;
            }
            UIView *placard(table != nil ? [table superview] : MSHookIvar<UIView *>(self, "_backPlacard"));
            UIImageView *background([[[UIImageView alloc] initWithImage:image] autorelease]);

            if (table == nil)
                [placard insertSubview:background atIndex:0];
            else {
                [table setBackgroundColor:[UIColor clearColor]];
                [placard insertSubview:background belowSubview:table];
            }
        }
}
// }}}

template <typename Original_>
static UIImage *WBCacheImage(NSBundle *bundle, NSString *name, const Original_ &original, NSString *key) {
    if (name == nil) {
      return original();
    }
    NSUInteger period([name rangeOfString:@"."].location);
    NSUInteger length([name length]);
    if (period == NSNotFound || length < 4 || period > length - 4) {
      name = [name stringByAppendingString:@".png"];
    }
    return WBCacheImage(
        [=](){ return $pathForFile$inBundle$(name, bundle, true); },
    [bundle, &original, name](){
        UIImage *image(original());
        if (image != nil && UIDebug_) {
            NSString *path([@"/tmp/WBImages/" stringByAppendingString:[bundle bundleIdentifier]]);
            [Manager_ createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0777} error:NULL];
            path = [NSString stringWithFormat:@"%@/%@", path, name];
            if (![Manager_ fileExistsAtPath:path]) {
              [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
            }
        }
        return image;
    },
    key);
}

// %hook _UIImageWithName() {{{
MSHook(UIImage *, _UIImageWithName, NSString *name) {
    if (name == nil)
        return nil;
    if (Debug_)
        NSLog(@"WB:Debug: _UIImageWithName(\"%@\")", name);
    return WBCacheImage(_UIKitBundle(), name,
        [=](){ return __UIImageWithName(name); },
    [NSString stringWithFormat:@"I:%@", name]);
}
// }}}
// %hook _UIImageWithNameInDomain() {{{
MSHook(UIImage *, _UIImageWithNameInDomain, NSString *name, NSString *domain) {
    if (Debug_)
        NSLog(@"WB:Debug: _UIImageWithNameInDomain(\"%@\", \"%@\")", name, domain);
    return WBCacheImage(
        [=](){ return $getTheme$($useScale$([NSArray arrayWithObject:[NSString stringWithFormat:@"Domains/%@/%@", domain, name]])); },
        [=](){ return __UIImageWithNameInDomain(name, domain); },
    [NSString stringWithFormat:@"D:%zu:%@%@", size_t([domain length]), domain, name]);
}
// }}}

// UISharedArtwork (iOS 6) {{{
MSInstanceMessageHook2(UISharedArtwork *, UISharedArtwork, initWithName,inBundle, NSString *, name, NSBundle *, bundle) {
    if ((self = MSOldCall(name, bundle)) != nil) {
        $objc_setAssociatedObject(self, @selector(wb$bundle), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } return self;
}

MSInstanceMessageHook2(UIImage *, UISharedArtwork, imageNamed,device, NSString *, name, NSInteger, device) {
    NSBundle *bundle($objc_getAssociatedObject(self, @selector(wb$bundle)));
    if (Debug_)
        NSLog(@"WB:Debug: -[UISharedArtwork(%@) imageNamed:@\"%@\" device:%li]", [bundle bundleIdentifier], name, (long) device);
    return WBCacheImage(bundle, name,
        [=](){ return MSOldCall(name, device); },
    [NSString stringWithFormat:@"M:%p:%@:%li", self, name, (long) device]);
}
// }}}
// _UIAssetManager (iOS 7) {{{
MSInstanceMessageHook3(_UIAssetManager *, _UIAssetManager, initWithName,inBundle,idiom, NSString *, name, NSBundle *, bundle, NSInteger, idiom) {
    if ((self = MSOldCall(name, bundle, idiom)) != nil) {
        $objc_setAssociatedObject(self, @selector(wb$bundle), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } return self;
}

MSInstanceMessageHook5(UIImage *, _UIAssetManager, imageNamed,scale,idiom,subtype,cachingOptions, NSString *, name, CGFloat, scale, NSInteger, idiom, NSUInteger, subtype, NSUInteger, caching) {
    NSBundle *bundle($objc_getAssociatedObject(self, @selector(wb$bundle)));
    if (Debug_)
        NSLog(@"WB:Debug: -[_UIAssetManager(%@/%@) imageNamed:@\"%@\" scale:%g idiom:%li subtype:%lu cachingOptions:%lu]",
            [bundle bundleIdentifier], [self carFileName],
            name, scale, (long) idiom,
            (unsigned long) subtype,
            (unsigned long) caching
        );

    if (bundle == _UIKitBundle()) {
        NSString *name([self carFileName]);
        if (false);
        else if ([name isEqualToString:@"UIKit_NewArtwork"])
            bundle = [WBBundle bundleWithIdentifier:@"com.apple.uikit.Artwork"];
        else if ([name isEqualToString:@"UIKit_OriginalArtwork"])
            bundle = [WBBundle bundleWithIdentifier:@"com.apple.uikit.LegacyArtwork"];
    }

    return WBCacheImage(bundle, name,
        [=](){ return MSOldCall(name, scale, idiom, subtype, caching); },
    [NSString stringWithFormat:@"M:%p:%@:%g:%li:%lu", self, name, scale, (long) idiom, (unsigned long) subtype]);
}
// }}}
// _UIAssetManager (iOS 8) {{{
struct SizeClassPair {
    NSInteger first;
    NSInteger second;
};

MSInstanceMessageHook7(UIImage *, _UIAssetManager, imageNamed,scale,idiom,subtype,cachingOptions,sizeClassPair,attachCatalogImage, NSString *, name, CGFloat, scale, NSInteger, idiom, NSUInteger, subtype, NSUInteger, caching, SizeClassPair, size, BOOL, attach) {
    NSBundle *bundle([self bundle]);
    if (Debug_)
        NSLog(@"WB:Debug: -[_UIAssetManager(%@/%@) imageNamed:@\"%@\" scale:%g idiom:%li subtype:%lu cachingOptions:%lu sizeClassPair:[%li %li] attachCatalogImage:%s]",
            [bundle bundleIdentifier], [self carFileName],
            name, scale, (long) idiom,
            (unsigned long) subtype,
            (unsigned long) caching,
            (long) size.first, (long) size.second,
            attach ? "YES" : "NO"
        );
    return WBCacheImage(bundle, name,
        [=](){ return MSOldCall(name, scale, idiom, subtype, caching, size, attach); },
    [NSString stringWithFormat:@"M:%p:%@:%g:%li:%lu:%li:%li:%c", self, name, scale, (long) idiom, (unsigned long) subtype, (long) size.first, (long) size.second, attach ? 'Y' : 'N']);
}
// }}}

// %hook GSFontCreateWithName() {{{
MSHook(GSFontRef, GSFontCreateWithName, const char *name, GSFontSymbolicTraits traits, float size) {
    if (Debug_)
        NSLog(@"WB:Debug: GSFontCreateWithName(\"%s\", %f)", name, size);
    if (NSString *font = [Info_ objectForKey:[NSString stringWithFormat:@"FontName-%s", name]])
        name = [font UTF8String];
    //if (NSString *scale = [Info_ objectForKey:[NSString stringWithFormat:@"FontScale-%s", name]])
    //    size *= [scale floatValue];
    return _GSFontCreateWithName(name, traits, size);
}
// }}}

#define AudioToolbox "/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox"

static bool GetFileNameForThisAction$(bool value, unsigned long a0, char *a1, unsigned long a2, bool &a3) {
    if (Debug_)
        NSLog(@"WB:Debug:GetFileNameForThisAction(%lu, %s, %lu, %u) = %u", a0, value ? a1 : NULL, a2, a3, value);

    if (value) {
        NSString *path = [NSString stringWithUTF8String:a1];
        if ([path hasPrefix:@"/System/Library/Audio/UISounds/"]) {
            NSString *file = [path substringFromIndex:31];
            for (NSString *theme in Themes_) {
                NSString *path([NSString stringWithFormat:@"%@/UISounds/%@", theme, file]);
                if ([Manager_ fileExistsAtPath:path]) {
                    strcpy(a1, [path UTF8String]);
                    break;
                }
            }
        }
    }
    return value;
}

MSHook(bool, _Z24GetFileNameForThisActionmPcRb, unsigned long a0, char *a1, bool &a3) {
    bool value(__Z24GetFileNameForThisActionmPcRb(a0, a1, a3));
    return GetFileNameForThisAction$(value, a0, a1, 0, a3);
}

#ifdef __LP64__
MSHook(bool, _Z24GetFileNameForThisActionjPcjRb, unsigned int a0, char *a1, unsigned int a2, bool &a3) {
    bool value(__Z24GetFileNameForThisActionjPcjRb(a0, a1, a2, a3));
    return GetFileNameForThisAction$(value, a0, a1, a2, a3);
}
#else
MSHook(bool, _Z24GetFileNameForThisActionmPcmRb, unsigned long a0, char *a1, unsigned long a2, bool &a3) {
    bool value(__Z24GetFileNameForThisActionmPcmRb(a0, a1, a2, a3));
    return GetFileNameForThisAction$(value, a0, a1, a2, a3);
}
#endif

static void ChangeWallpaper(
    CFNotificationCenterRef center,
    void *observer,
    CFStringRef name,
    const void *object,
    CFDictionaryRef info
) {
    if (Debug_)
        NSLog(@"WB:Debug:ChangeWallpaper!");

    UIImage *image;
    if (WallpaperFile_ != nil) {
        image = [[UIImage alloc] initWithContentsOfFile:WallpaperFile_];
        if (image != nil)
            image = [image autorelease];
    } else image = nil;

    if (WallpaperImage_ != nil)
        [WallpaperImage_ setImage:image];
    if (WallpaperPage_ != nil)
        [WallpaperPage_ loadRequest:[NSURLRequest requestWithURL:WallpaperURL_]];

}

MSHook(NSArray *, CPBitmapCreateImagesFromPath, NSString *path, CFTypeRef *names, void *arg2, void *arg3) {
    NSArray *images(_CPBitmapCreateImagesFromPath(path, names, arg2, arg3));
    if (images == nil)
        return nil;
    if (names == NULL || *names == nil)
        return images;

    NSBundle *bundle([NSBundle wb$bundleWithFile:path]);
    if (bundle == nil)
        return images;

    NSString *file([path stringByResolvingSymlinksInPath]);
    NSString *prefix([[bundle bundlePath] stringByResolvingSymlinksInPath]);
    // XXX: why do I care about this?
    if (![file hasPrefix:prefix])
        return images;

    NSMutableArray *copy([images mutableCopy]);
    [images release];
    images = copy;

    NSDictionary *indexes;
    NSEnumerator *enumerator;

    if (CFGetTypeID((CFTypeRef) *names) == CFDictionaryGetTypeID()) {
        indexes = (NSDictionary *) *names;
        enumerator = [indexes keyEnumerator];
    } else {
        indexes = nil;
        enumerator = [(NSArray *) *names objectEnumerator];
    }

    for (NSUInteger index(0); NSString *name = [enumerator nextObject]; ++index)
        if (NSString *themed = $pathForFile$inBundle$([name stringByAppendingString:@".png"], bundle, true)) {
            if (indexes != nil)
                index = [[indexes objectForKey:name] intValue];
            if (UIImage *image = $getImage$(themed))
                [copy replaceObjectAtIndex:index withObject:(id)[image CGImage]];
        }

    return images;
}

MSHook(void, BKSDisplayServicesSetSystemAppExitedImagePath, NSString *path) {
    if (NSString *themed = $getTheme$($useScale$([NSArray arrayWithObject:@"SystemAppExited.png"])))
        path = themed;
    _BKSDisplayServicesSetSystemAppExitedImagePath(path);
}

#define WBRename(name, sel, imp) \
    MSHookMessage($ ## name, @selector(sel), &$ ## name ## $ ## imp, &_ ## name ## $ ## imp)

template <typename Type_>
static void msset(Type_ &function, MSImageRef image, const char *name) {
    function = reinterpret_cast<Type_>(MSFindSymbol(image, name));
}

#define WBHookSymbol(image, function) \
    msset(function, image, "_" #function)

template <typename Type_>
static void dlset(Type_ &function, const char *name) {
    function = reinterpret_cast<Type_>(dlsym(RTLD_DEFAULT, name));
}

// %hook CGImageReadCreateWithFile() {{{
MSHook(void *, CGImageReadCreateWithFile, NSString *path, int flag) {
    if (Debug_)
        NSLog(@"WB:Debug: CGImageReadCreateWithFile(%@, %d)", path, flag);
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    void *value(_CGImageReadCreateWithFile([path wb$themedPath], flag));
    [pool release];
    return value;
}

MSHook(void *, CGImageSourceCreateWithFile, NSString *path, NSDictionary *options) {
    if (Debug_)
        NSLog(@"WB:Debug: CGImageSourceCreateWithFile(%@, %@)", path, options);
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    void *value(_CGImageSourceCreateWithFile([path wb$themedPath], options));
    [pool release];
    return value;
}

MSHook(void *, CGImageSourceCreateWithURL, NSURL *url, NSDictionary *options) {
    if (Debug_)
        NSLog(@"WB:Debug: CGImageSourceCreateWithURL(%@, %@)", url, options);
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    if ([url isFileURL])
        url = [NSURL fileURLWithPath:[[url path] wb$themedPath]];
    void *value(_CGImageSourceCreateWithURL(url, options));
    [pool release];
    return value;
}
// }}}

static void NSString$drawAtPoint$withStyle$(NSString *self, SEL _cmd, CGPoint point, NSString *style) {
    WKSetCurrentGraphicsContext(UIGraphicsGetCurrentContext());
    if (style == nil || [style length] == 0)
        style = @"font-family: Helvetica; font-size: 12px";
    //NSLog(@"XXX:drawP(%@ | %@)", self, [style stringByReplacingOccurrencesOfString:@"\n" withString:@" "]);
    [[WBMarkup sharedMarkup] drawString:self atPoint:point withStyle:style];
}

static void NSString$drawInRect$withStyle$(NSString *self, SEL _cmd, CGRect rect, NSString *style) {
    WKSetCurrentGraphicsContext(UIGraphicsGetCurrentContext());
    if (style == nil || [style length] == 0)
        style = @"font-family: Helvetica; font-size: 12px";
    //NSLog(@"XXX:drawR(%@ | %@)", self, [style stringByReplacingOccurrencesOfString:@"\n" withString:@" "]);
    return [[WBMarkup sharedMarkup] drawString:self inRect:rect withStyle:style];
}

static CGSize NSString$sizeWithStyle$forWidth$(NSString *self, SEL _cmd, NSString *style, CGFloat width) {
    if (style == nil || [style length] == 0)
        style = @"font-family: Helvetica; font-size: 12px";
    CGSize size([[WBMarkup sharedMarkup] sizeOfString:self withStyle:style forWidth:width]);
    //NSLog(@"XXX:size(%@ | %@) = [%g %g]", self, [style stringByReplacingOccurrencesOfString:@"\n" withString:@" "], size.width, size.height);
    return size;
}

/*MSHook(int, open, const char *path, int oflag, mode_t mode) {
    int fd(_open(path, oflag, mode));

    static bool no(false);
    if (no) return fd;
    no = true;

    if (strstr(path, "/icon") != NULL)
        *reinterpret_cast<void *volatile *>(NULL) = NULL;

    if (fd == -1 && errno == EFAULT)
        NSLog(@"open(%p, %#x, %#o) = %d\n", path, oflag, mode, fd);
    else
        NSLog(@"open(\"%s\", %#x, %#o) = %d\n", path, oflag, mode, fd);

    no = false;
    return fd;
}*/

%ctor {
    $objc_setAssociatedObject = reinterpret_cast<void (*)(id, void *, id value, objc_AssociationPolicy)>(dlsym(RTLD_DEFAULT, "objc_setAssociatedObject"));
    $objc_getAssociatedObject = reinterpret_cast<id (*)(id, void *)>(dlsym(RTLD_DEFAULT, "objc_getAssociatedObject"));
    $objc_removeAssociatedObjects = reinterpret_cast<void (*)(id)>(dlsym(RTLD_DEFAULT, "objc_removeAssociatedObjects"));

    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    NSString *identifier([[NSBundle mainBundle] bundleIdentifier]);
    SpringBoard_ = [identifier isEqualToString:@"com.apple.springboard"];

    Manager_ = [[NSFileManager defaultManager] retain];
    Themes_ = [[NSMutableArray alloc] initWithCapacity:8];

    dlset(_GSFontGetUseLegacyFontMetrics, "GSFontGetUseLegacyFontMetrics");

    // Initialize IsWild_ {{{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = new char[size];

    if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == -1) {
        perror("sysctlbyname(\"hw.machine\", ?)");
        delete [] machine;
        machine = NULL;
    }

    IsWild_ = machine != NULL && strncmp(machine, "iPad", 4) == 0;
    // }}}
    // Load Settings.plist {{{
    if (NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/User/Library/Preferences/com.saurik.WinterBoard.plist"]]) {
        if (kCFCoreFoundationVersionNumber >= 1000)
            SummerBoard_ = false;
        else if (NSNumber *value = [settings objectForKey:@"SummerBoard"])
            SummerBoard_ = [value boolValue];
        else
            SummerBoard_ = true;

        if (NSNumber *value = [settings objectForKey:@"Debug"])
            Debug_ = [value boolValue];
        if (NSNumber *value = [settings objectForKey:@"RecordUI"])
            UIDebug_ = [value boolValue];

        NSArray *themes([settings objectForKey:@"Themes"]);
        if (themes == nil)
            if (NSString *theme = [settings objectForKey:@"Theme"])
                themes = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    theme, @"Name",
                    [NSNumber numberWithBool:true], @"Active",
                nil]];

        if (themes != nil)
            for (NSDictionary *theme in themes) {
                NSNumber *active([theme objectForKey:@"Active"]);
                if (![active boolValue])
                    continue;

                NSString *name([theme objectForKey:@"Name"]);
                if (name == nil)
                    continue;

                #define testForTheme(format...) \
                    { \
                        NSString *path = [NSString stringWithFormat:format]; \
                        if ([Manager_ fileExistsAtPath:path]) { \
                            [Themes_ addObject:path]; \
                            continue; \
                        } \
                    }

                testForTheme(@"/Library/Themes/%@.theme", name)
                testForTheme(@"/Library/Themes/%@", name)
                testForTheme(@"%@/Library/SummerBoard/Themes/%@", NSHomeDirectory(), name)

            }
    }
    // }}}
    // Merge Info.plist {{{
    Info_ = [[NSMutableDictionary dictionaryWithCapacity:16] retain];

    for (NSString *theme in Themes_)
        if (NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", theme]])
            for (NSString *key in [info allKeys])
                if ([Info_ objectForKey:key] == nil)
                    [Info_ setObject:[info objectForKey:key] forKey:key];
    // }}}

    // AppSupport {{{
    if (MSImageRef image = MSGetImageByName("/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport")) {
        NSArray *(*CPBitmapCreateImagesFromPath)(NSString *, CFTypeRef *, void *, void *);
        msset(CPBitmapCreateImagesFromPath, image, "_CPBitmapCreateImagesFromPath");
        MSHookFunction(CPBitmapCreateImagesFromPath, MSHake(CPBitmapCreateImagesFromPath));
    }
    // }}}
    // AudioToolbox {{{
    if (MSImageRef image = MSGetImageByName(AudioToolbox)) {
        bool (*_Z24GetFileNameForThisActionmPcRb)(unsigned long, char *, bool &);
        msset(_Z24GetFileNameForThisActionmPcRb, image, "__Z24GetFileNameForThisActionmPcRb");
        MSHookFunction(_Z24GetFileNameForThisActionmPcRb, &$_Z24GetFileNameForThisActionmPcRb, &__Z24GetFileNameForThisActionmPcRb);

#ifdef __LP64__
        bool (*_Z24GetFileNameForThisActionjPcjRb)(unsigned int, char *, unsigned int, bool &);
        msset(_Z24GetFileNameForThisActionjPcjRb, image, "__Z24GetFileNameForThisActionjPcjRb");
        MSHookFunction(_Z24GetFileNameForThisActionjPcjRb, &$_Z24GetFileNameForThisActionjPcjRb, &__Z24GetFileNameForThisActionjPcjRb);
#else
        bool (*_Z24GetFileNameForThisActionmPcmRb)(unsigned long, char *, unsigned long, bool &);
        msset(_Z24GetFileNameForThisActionmPcmRb, image, "__Z24GetFileNameForThisActionmPcmRb");
        MSHookFunction(_Z24GetFileNameForThisActionmPcmRb, &$_Z24GetFileNameForThisActionmPcmRb, &__Z24GetFileNameForThisActionmPcmRb);
#endif
    }
    // }}}
    // BackBoardServices {{{
    if (MSImageRef image = MSGetImageByName("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices")) {
        void (*BKSDisplayServicesSetSystemAppExitedImagePath)(NSString *path);
        msset(BKSDisplayServicesSetSystemAppExitedImagePath, image, "_BKSDisplayServicesSetSystemAppExitedImagePath");
        MSHookFunction(BKSDisplayServicesSetSystemAppExitedImagePath, MSHake(BKSDisplayServicesSetSystemAppExitedImagePath));
    }
    // }}}
    // Foundation {{{
    if (true) {
        if (![identifier isEqualToString:@"com.apple.backupd"]) // XXX: rethink
        MSHookFunction(CFBundleCopyResourceURL, MSHake(CFBundleCopyResourceURL));
    }
    // }}}
    // GraphicsServices {{{
    if (true) {
        MSHookFunction(&GSFontCreateWithName, &$GSFontCreateWithName, &_GSFontCreateWithName);
    }
    // }}}
    // ImageIO {{{
    MSImageRef imageio = MSGetImageByName("/System/Library/Frameworks/ImageIO.framework/ImageIO");
    if (imageio == NULL)
        imageio = MSGetImageByName("/System/Library/PrivateFrameworks/ImageIO.framework/ImageIO");
    if (MSImageRef image = imageio) {
        void *(*CGImageReadCreateWithFile)(NSString *, int) = NULL;
        if (kCFCoreFoundationVersionNumber > 700) // XXX: iOS 6.x
            CGImageReadCreateWithFile = NULL;
        else {
            msset(CGImageReadCreateWithFile, image, "_CGImageReadCreateWithFile");
            MSHookFunction(CGImageReadCreateWithFile, MSHake(CGImageReadCreateWithFile));
        }

        if (CGImageReadCreateWithFile == NULL) {
            void *(*CGImageSourceCreateWithFile)(NSString *, NSDictionary *);
            msset(CGImageSourceCreateWithFile, image, "_CGImageSourceCreateWithFile");
            MSHookFunction(CGImageSourceCreateWithFile, MSHake(CGImageSourceCreateWithFile));

            void *(*CGImageSourceCreateWithURL)(NSURL *, NSDictionary *);
            msset(CGImageSourceCreateWithURL, image, "_CGImageSourceCreateWithURL");
            MSHookFunction(CGImageSourceCreateWithURL, MSHake(CGImageSourceCreateWithURL));
        }
    }
    // }}}
    // SpringBoard {{{

    // }}}
    // UIKit {{{
    if (MSImageRef image = MSGetImageByName("/System/Library/Frameworks/UIKit.framework/UIKit")) {
#ifdef __LP64__
        class_addMethod($NSString, @selector(drawAtPoint:withStyle:), (IMP) &NSString$drawAtPoint$withStyle$, "v40@0:8{CGPoint=dd}16@32");
        class_addMethod($NSString, @selector(drawInRect:withStyle:), (IMP) &NSString$drawInRect$withStyle$, "v56@0:8{CGRect={CGSize=dd}{CGSize=dd}}16@48");
        class_addMethod($NSString, @selector(sizeWithStyle:forWidth:), (IMP) &NSString$sizeWithStyle$forWidth$, "{CGSize=dd}32@0:8@16d24");
#else
        class_addMethod($NSString, @selector(drawAtPoint:withStyle:), (IMP) &NSString$drawAtPoint$withStyle$, "v20@0:4{CGPoint=ff}8@16");
        class_addMethod($NSString, @selector(drawInRect:withStyle:), (IMP) &NSString$drawInRect$withStyle$, "v28@0:4{CGRect={CGSize=ff}{CGSize=ff}}8@24");
        class_addMethod($NSString, @selector(sizeWithStyle:forWidth:), (IMP) &NSString$sizeWithStyle$forWidth$, "{CGSize=ff}16@0:4@8f12");
#endif

        WBHookSymbol(image, _UIKitBundle);

        if (kCFCoreFoundationVersionNumber < 700)
            MSHookFunction(_UIImageWithName, MSHake(_UIImageWithName));

        WBHookSymbol(image, _UIApplicationImageWithName);
        MSHookFunction(_UIApplicationImageWithName, MSHake(_UIApplicationImageWithName));

        WBHookSymbol(image, _UIImageWithNameInDomain);
        MSHookFunction(_UIImageWithNameInDomain, MSHake(_UIImageWithNameInDomain));

        SEL includeEmoji(@selector(_legacy_drawAtPoint:forWidth:withFont:lineBreakMode:letterSpacing:includeEmoji:));
        if (![@"" respondsToSelector:includeEmoji])
            includeEmoji = @selector(drawAtPoint:forWidth:withFont:lineBreakMode:letterSpacing:includeEmoji:);
        MSHookMessage($NSString, includeEmoji, MSHake(NSString$drawAtPoint$forWidth$withFont$lineBreakMode$letterSpacing$includeEmoji$));

        SEL letterSpacing(@selector(_legacy_sizeWithFont:forWidth:lineBreakMode:letterSpacing:));
        if (![@"" respondsToSelector:letterSpacing])
            letterSpacing = @selector(sizeWithFont:forWidth:lineBreakMode:letterSpacing:);
        MSHookMessage($NSString, letterSpacing, MSHake(NSString$sizeWithFont$forWidth$lineBreakMode$letterSpacing$));

        SEL sizeWithFont(@selector(_legacy_sizeWithFont:));
        if (![@"" respondsToSelector:sizeWithFont])
            sizeWithFont = @selector(sizeWithFont:);
        MSHookMessage($NSString, sizeWithFont, MSHake(NSString$sizeWithFont$));

        MSHookMessage($NSAttributedString, @selector(drawAtPoint:), MSHake(NSAttributedString$drawAtPoint$));
        MSHookMessage($NSAttributedString, @selector(boundingRectWithSize:options:context:), MSHake(NSAttributedString$boundingRectWithSize$options$context$));
    }
    // }}}

    //MSHookFunction(reinterpret_cast<int (*)(const char *, int, mode_t)>(&open), MSHake(open));

    [pool release];
}

///Yay 2745 lines to convert
