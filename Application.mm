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

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIKit.h>

#include <objc/objc-runtime.h>

#import <Preferences/PSRootController.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#include <substrate.h>
#include <mach-o/dyld.h>

static NSBundle *wbSettingsBundle;
static Class $WBSettingsController;

@interface UIApplication (Private)
- (void) terminateWithSuccess;
@end

@interface UIDevice (Private)
- (BOOL) isWildcat;
@end

@interface PSRootController (Compatibility)
- (id) _popController; // < 3.2
- (id) contentView; // < 3.2
- (id) lastController; // < 3.2
- (id) topViewController; // >= 3.2
@end

@interface PSListController (Compatibility)
- (void) viewWillBecomeVisible:(void *)specifier; // < 3.2
- (void) viewWillAppear:(BOOL)a; // >= 3.2
- (void) setSpecifier:(PSSpecifier *)spec; // >= 3.2
@end

@interface WBRootController : PSRootController {
    PSListController *_rootListController;
}

@property (readonly) PSListController *rootListController;

- (void) setupRootListForSize:(CGSize)size;
- (id) topViewController;
@end

@implementation WBRootController

@synthesize rootListController = _rootListController;

// < 3.2
- (void) setupRootListForSize:(CGSize)size {
    PSSpecifier *spec([[PSSpecifier alloc] init]);
    [spec setTarget:self];
    spec.name = @"WinterBoard";

    _rootListController = [[$WBSettingsController alloc] initForContentSize:size];
    _rootListController.rootController = self;
    _rootListController.parentController = self;
    [_rootListController viewWillBecomeVisible:spec];

    [spec release];

    [self pushController:_rootListController];
}

// >= 3.2
- (void) loadView {
    [super loadView];
    [self pushViewController:[self rootListController] animated:NO];
}

- (PSListController *) rootListController {
    if(!_rootListController) {
        PSSpecifier *spec([[PSSpecifier alloc] init]);
        [spec setTarget:self];
        spec.name = @"WinterBoard";
        _rootListController = [[$WBSettingsController alloc] initForContentSize:CGSizeZero];
        _rootListController.rootController = self;
        _rootListController.parentController = self;
        [_rootListController setSpecifier:spec];
        [spec release];
    }
    return _rootListController;
}

- (id) contentView {
    if ([[PSRootController class] instancesRespondToSelector:@selector(contentView)]) {
        return [super contentView];
    } else {
        return [super view];
    }
}

- (id) topViewController {
    if ([[PSRootController class] instancesRespondToSelector:@selector(topViewController)]) {
        return [super topViewController];
    } else {
        return [super lastController];
    }
}

- (void) _popController {
    // Pop the last controller = exit the application.
    // The only time the last controller should pop is when the user taps Respring/Cancel.
    // Which only gets displayed if the user has made changes.
    if ([self topViewController] == _rootListController)
        [[UIApplication sharedApplication] terminateWithSuccess];
    [super _popController];
}

@end

@interface WBApplication : UIApplication {
    WBRootController *_rootController;
}

@end

@implementation WBApplication

- (void) dealloc {
    [_rootController release];
    [super dealloc];
}

- (void) applicationWillTerminate:(UIApplication *)application {
    [_rootController.rootListController suspend];
}

- (void) applicationDidFinishLaunching:(id)unused {
    wbSettingsBundle = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/WinterBoardSettings.bundle"];
    [wbSettingsBundle load];
    $WBSettingsController = [wbSettingsBundle principalClass];

    CGRect applicationFrame(([UIDevice instancesRespondToSelector:@selector(isWildcat)]
                         && [[UIDevice currentDevice] isWildcat]) || objc_getClass("UIStatusBar") != nil
                          ? [UIScreen mainScreen].bounds
                          : [UIScreen mainScreen].applicationFrame);
    UIWindow *window([[UIWindow alloc] initWithFrame:applicationFrame]);
    _rootController = [[WBRootController alloc] initWithTitle:@"WinterBoard" identifier:[[NSBundle mainBundle] bundleIdentifier]];
    [window addSubview:[_rootController contentView]];
    [window makeKeyAndVisible];
}

@end

MSHook(int32_t, NSVersionOfLinkTimeLibrary, const char *name) {
    if (strcmp(name, "UIKit") == 0)
        return 0x6400000;
    return _NSVersionOfLinkTimeLibrary(name);
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool( [[NSAutoreleasePool alloc] init]);

    MSHookFunction(NSVersionOfLinkTimeLibrary, MSHake(NSVersionOfLinkTimeLibrary));

    int value = UIApplicationMain(argc, argv, @"WBApplication", @"WBApplication");

    [pool release];
    return value;
}
