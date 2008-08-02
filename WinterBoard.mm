/* WinterBoard - Theme Manager for the iPhone
 * Copyright (C) 2008  Jay Freeman (saurik)
*/

/*
 *        Redistribution and use in source and binary
 * forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer in the documentation
 *    and/or other materials provided with the
 *    distribution.
 * 3. The name of the author may not be used to endorse
 *    or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <objc/runtime.h>
#include <objc/message.h>

#import <Foundation/Foundation.h>

#import <UIKit/UIColor.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIView-Hierarchy.h>

#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBAppWindow.h>
#import <SpringBoard/SBContentLayer.h>
#import <SpringBoard/SBUIController.h>

#import <CoreGraphics/CGGeometry.h>

/* WinterBoard Backend {{{ */
#define WBPrefix "wb_"

void WBInject(const char *classname, const char *oldname, IMP newimp, const char *type) {
    Class _class = objc_getClass(classname);
    if (_class == nil)
        return;
    if (!class_addMethod(_class, sel_registerName(oldname), newimp, type))
        NSLog(@"WB: failed to inject [%s %s]", classname, oldname);
}

void WBRename(const char *classname, const char *oldname, IMP newimp) {
    Class _class = objc_getClass(classname);
    if (_class == nil)
        return;
    size_t namelen = strlen(oldname);
    char newname[sizeof(WBPrefix) + namelen];
    memcpy(newname, WBPrefix, sizeof(WBPrefix) - 1);
    memcpy(newname + sizeof(WBPrefix) - 1, oldname, namelen + 1);
    Method method = class_getInstanceMethod(_class, sel_getUid(oldname));
    if (method == nil)
        return;
    const char *type = method_getTypeEncoding(method);
    if (!class_addMethod(_class, sel_registerName(newname), method_getImplementation(method), type))
        NSLog(@"WB: failed to rename [%s %s]", classname, oldname);
    unsigned int count;
    Method *methods = class_copyMethodList(_class, &count);
    for (unsigned int index(0); index != count; ++index)
        if (methods[index] == method)
            goto found;
    if (newimp != NULL)
        if (!class_addMethod(_class, sel_getUid(oldname), newimp, type))
            NSLog(@"WB: failed to rename [%s %s]", classname, oldname);
    goto done;
  found:
    if (newimp != NULL)
        method_setImplementation(method, newimp);
  done:
    free(methods);
}

static NSString *Dylib_ = @"/System/Library/PrivateFrameworks/WinterBoard.framework/WinterBoard.dylib";
/* }}} */

@protocol WinterBoard
- (NSString *) wb_pathForIcon;
- (NSString *) wb_pathForResource:(NSString *)resource ofType:(NSString *)type;
- (id) wb_initWithSize:(CGSize)size;
- (void) wb_setBackgroundColor:(id)color;
@end

NSString *Themes_ = @"/System/Library/Themes";
NSString *theme_ = @"Litho";

NSString *SBApplication$pathForIcon(SBApplication<WinterBoard> *self, SEL sel) {
    NSFileManager *manager([NSFileManager defaultManager]);
    NSString *path;
    path = [NSString stringWithFormat:@"%@/%@/Icons/%@.png", Themes_, theme_, [self displayName]];
    if ([manager fileExistsAtPath:path])
        return path;
    path = [NSString stringWithFormat:@"%@/%@/Icons/%@.png", Themes_, theme_, [self bundleIdentifier]];
    if ([manager fileExistsAtPath:path])
        return path;
    return [self wb_pathForIcon];
}

NSString *NSBundle$pathForResource$ofType$(NSBundle<WinterBoard> *self, SEL sel, NSString *resource, NSString *type) {
    if ([resource isEqualToString:@"SBDockBG"] && [type isEqualToString:@"png"]) {
        NSFileManager *manager([NSFileManager defaultManager]);
        NSString *path = [NSString stringWithFormat:@"%@/%@/Dock.png", Themes_, theme_];
        if ([manager fileExistsAtPath:path])
            return path;
    }

    return [self wb_pathForResource:resource ofType:type];
}

void SBAppWindow$setBackgroundColor$(SBAppWindow<WinterBoard> *self, SEL sel, id color) {
    [self wb_setBackgroundColor:[UIColor clearColor]];
}

id SBContentLayer$initWithSize$(SBContentLayer<WinterBoard> *self, SEL sel, CGSize size) {
    self = [self wb_initWithSize:size];
    if (self == nil)
        return nil;

    NSFileManager *manager([NSFileManager defaultManager]);
    NSString *path = [NSString stringWithFormat:@"%@/%@/Wallpaper.png", Themes_, theme_];
    if ([manager fileExistsAtPath:path])
        if (UIImage *image = [[UIImage alloc] initWithContentsOfFile:path]) {
            /*window_ = [[UIWindow alloc] initWithContentRect:CGRectMake(0, 0, 320, 480)];
            [window_ setHidden:NO];*/
            UIImageView *view = [[[UIImageView alloc] initWithImage:image] autorelease];
            //[view setFrame:CGRectMake(0, -10, 320, 480)];
            [self addSubview:view];
        }

    return self;
}

extern "C" void WBInitialize() {
    /* WinterBoard FrontEnd {{{ */
    if (NSClassFromString(@"SpringBoard") == nil)
        return;
    NSLog(@"WB: installing WinterBoard...");

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    char *dil = getenv("DYLD_INSERT_LIBRARIES");
    if (dil == NULL)
        NSLog(@"WB: DYLD_INSERT_LIBRARIES is unset?");
    else {
        NSArray *dylibs = [[NSString stringWithUTF8String:dil] componentsSeparatedByString:@":"];
        int index = [dylibs indexOfObject:Dylib_];
        if (index == INT_MAX)
            NSLog(@"WB: dylib not in DYLD_INSERT_LIBRARIES?");
        else if ([dylibs count] == 1)
            unsetenv("DYLD_INSERT_LIBRARIES");
        else {
            NSMutableArray *value = [[NSMutableArray alloc] init];
            [value setArray:dylibs];
            [value removeObjectAtIndex:index];
            setenv("DYLD_INSERT_LIBRARIES", [[value componentsJoinedByString:@":"] UTF8String], !0);
        }
    }
    /* }}} */

    WBRename("SBApplication", "pathForIcon", (IMP) &SBApplication$pathForIcon);
    WBRename("NSBundle", "pathForResource:ofType:", (IMP) &NSBundle$pathForResource$ofType$);
    WBRename("SBAppWindow", "setBackgroundColor:", (IMP) &SBAppWindow$setBackgroundColor$);
    WBRename("SBContentLayer", "initWithSize:", (IMP) &SBContentLayer$initWithSize$);

    [pool release];
}