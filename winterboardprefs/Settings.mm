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
#import <UIKit/UIKit.h>
#import <Preferences/PSRootController.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UINavigationButton.h>

#include <cmath>
#include <dlfcn.h>
#include <objc/runtime.h>

extern NSString *PSTableCellKey;
extern "C" UIImage *_UIImageWithName(NSString *);

static UIImage *checkImage;
static UIImage *uncheckedImage;

static BOOL settingsChanged;
static NSMutableDictionary *_settings;
static NSString *_plist;

void AddThemes(NSMutableArray *themesOnDisk, NSString *folder) {
    NSArray *themes([[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:NULL]);
    for (NSString *theme in themes) {
        if (NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/Info.plist", folder, theme]]) {
            if (NSArray *version = [info objectForKey:@"CoreFoundationVersion"]) {
                size_t count([version count]);
                if (count == 0 || count > 2)
                    continue;

                double lower([[version objectAtIndex:0] doubleValue]);
                if (kCFCoreFoundationVersionNumber < lower)
                    continue;

                if (count != 1) {
                    double upper([[version objectAtIndex:1] doubleValue]);
                    if (upper <= kCFCoreFoundationVersionNumber)
                        continue;
                }
            }
        }

        [themesOnDisk addObject:theme];
    }
}

/* Theme Settings Controller {{{ */





/* }}} */

//



//



#define WBSAddMethod(_class, _sel, _imp, _type) \
    if (![[_class class] instancesRespondToSelector:@selector(_sel)]) \
        class_addMethod([_class class], @selector(_sel), (IMP)_imp, _type)
void $PSRootController$popController(PSRootController *self, SEL _cmd) {
    [self popViewControllerAnimated:YES];
}

void $PSViewController$hideNavigationBarButtons(PSRootController *self, SEL _cmd) {
}

id $PSViewController$initForContentSize$(PSRootController *self, SEL _cmd, CGRect contentSize) {
    return [self init];
}

static __attribute__((constructor)) void __wbsInit() {
    WBSAddMethod(PSRootController, popController, $PSRootController$popController, "v@:");
    WBSAddMethod(PSViewController, hideNavigationBarButtons, $PSViewController$hideNavigationBarButtons, "v@:");
    WBSAddMethod(PSViewController, initForContentSize:, $PSViewController$initForContentSize$, "@@:{ff}");
}
