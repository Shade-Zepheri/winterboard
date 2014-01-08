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

#include <dlfcn.h>
#include <objc/runtime.h>

static BOOL (*IsIconHiddenDisplayId)(NSString *);
static BOOL (*HideIconViaDisplayId)(NSString *);
static BOOL (*UnHideIconViaDisplayId)(NSString *);

static NSString *WinterBoardDisplayID = @"com.saurik.WinterBoard";

extern NSString *PSTableCellKey;
extern "C" UIImage *_UIImageWithName(NSString *);

static UIImage *checkImage;
static UIImage *uncheckedImage;

static BOOL settingsChanged;
static NSMutableDictionary *_settings;
static NSString *_plist;

/* [NSObject yieldToSelector:(withObject:)] {{{*/
@interface NSObject (wb$yieldToSelector)
- (id) wb$yieldToSelector:(SEL)selector withObject:(id)object;
- (id) wb$yieldToSelector:(SEL)selector;
@end

@implementation NSObject (Cydia)

- (void) wb$doNothing {
}

- (void) wb$_yieldToContext:(NSMutableArray *)context {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    SEL selector(reinterpret_cast<SEL>([[context objectAtIndex:0] pointerValue]));
    id object([[context objectAtIndex:1] nonretainedObjectValue]);
    volatile bool &stopped(*reinterpret_cast<bool *>([[context objectAtIndex:2] pointerValue]));

    /* XXX: deal with exceptions */
    id value([self performSelector:selector withObject:object]);

    NSMethodSignature *signature([self methodSignatureForSelector:selector]);
    [context removeAllObjects];
    if ([signature methodReturnLength] != 0 && value != nil)
        [context addObject:value];

    stopped = true;

    [self
        performSelectorOnMainThread:@selector(wb$doNothing)
        withObject:nil
        waitUntilDone:NO
    ];

    [pool release];
}

- (id) wb$yieldToSelector:(SEL)selector withObject:(id)object {
    /*return [self performSelector:selector withObject:object];*/

    volatile bool stopped(false);

    NSMutableArray *context([NSMutableArray arrayWithObjects:
        [NSValue valueWithPointer:selector],
        [NSValue valueWithNonretainedObject:object],
        [NSValue valueWithPointer:const_cast<bool *>(&stopped)],
    nil]);

    NSThread *thread([[[NSThread alloc]
        initWithTarget:self
        selector:@selector(wb$_yieldToContext:)
        object:context
    ] autorelease]);

    [thread start];

    NSRunLoop *loop([NSRunLoop currentRunLoop]);
    NSDate *future([NSDate distantFuture]);

    while (!stopped && [loop runMode:NSDefaultRunLoopMode beforeDate:future]);

    return [context count] == 0 ? nil : [context objectAtIndex:0];
}

- (id) wb$yieldToSelector:(SEL)selector {
    return [self wb$yieldToSelector:selector withObject:nil];
}

@end
/* }}} */

/* Theme Settings Controller {{{ */
@interface WBSThemesController: PSViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;
    NSMutableArray *_themes;
}

@property (nonatomic, retain) NSMutableArray *themes;

+ (void) load;

- (id) initForContentSize:(CGSize)size;
- (id) view;
- (id) navigationTitle;
- (void) themesChanged;

- (int) numberOfSectionsInTableView:(UITableView *)tableView;
- (id) tableView:(UITableView *)tableView titleForHeaderInSection:(int)section;
- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(int)section;
- (id) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation WBSThemesController

@synthesize themes = _themes;

+ (void) load {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    checkImage = [_UIImageWithName(@"UIPreferencesBlueCheck.png") retain];
    uncheckedImage = [[UIImage imageWithContentsOfFile:@"/System/Library/PreferenceBundles/WinterBoardSettings.bundle/SearchResultsCheckmarkClear.png"] retain];
    [pool release];
}

- (id) initForContentSize:(CGSize)size {
    if ((self = [super initForContentSize:size]) != nil) {
        self.themes = [_settings objectForKey:@"Themes"];
        if (!_themes) {
            if (NSString *theme = [_settings objectForKey:@"Theme"]) {
                self.themes = [NSMutableArray arrayWithObject:
                         [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            theme, @"Name",
                                [NSNumber numberWithBool:YES], @"Active", nil]];
                [_settings removeObjectForKey:@"Theme"];
            }
            if (!_themes)
                self.themes = [NSMutableArray array];
            [_settings setObject:_themes forKey:@"Themes"];
        }

        NSMutableArray *themesOnDisk([NSMutableArray array]);

        [themesOnDisk
            addObjectsFromArray:[[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:@"/Library/Themes" error:NULL]
        ];

        [themesOnDisk addObjectsFromArray:[[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/Library/SummerBoard/Themes", NSHomeDirectory()]
            error:NULL
        ]];

        for (int i = 0, count = [themesOnDisk count]; i < count; i++) {
            NSString *theme = [themesOnDisk objectAtIndex:i];
            if ([theme hasSuffix:@".theme"])
                [themesOnDisk replaceObjectAtIndex:i withObject:[theme stringByDeletingPathExtension]];
        }

        NSMutableSet *themesSet([NSMutableSet set]);

        for (int i = 0, count = [_themes count]; i < count; i++) {
            NSDictionary *theme([_themes objectAtIndex:i]);
            NSString *name([theme objectForKey:@"Name"]);

            if (!name || ![themesOnDisk containsObject:name]) {
                [_themes removeObjectAtIndex:i];
                i--;
                count--;
            } else {
                [themesSet addObject:name];
            }
        }

        for (NSString *theme in themesOnDisk) {
            if ([themesSet containsObject:theme])
                continue;
            [themesSet addObject:theme];

            [_themes insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    theme, @"Name",
                    [NSNumber numberWithBool:NO], @"Active",
            nil] atIndex:0];
        }

        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:YES];
        [_tableView setAllowsSelectionDuringEditing:YES];
        if ([self respondsToSelector:@selector(setView:)])
            [self setView:_tableView];
    }
    return self;
}

- (void) dealloc {
    [_tableView release];
    [_themes release];
    [super dealloc];
}

- (id) navigationTitle {
    return @"Themes";
}

- (id) view {
    return _tableView;
}

- (void) themesChanged {
    settingsChanged = YES;
}

/* UITableViewDelegate / UITableViewDataSource Methods {{{ */
- (int) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (id) tableView:(UITableView *)tableView titleForHeaderInSection:(int)section {
    return nil;
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(int)section {
    return _themes.count;
}

- (id) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThemeCell"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100) reuseIdentifier:@"ThemeCell"] autorelease];
        //[cell setTableViewStyle:UITableViewCellStyleDefault];
    }

    NSDictionary *theme([_themes objectAtIndex:indexPath.row]);
    cell.text = [theme objectForKey:@"Name"];
    cell.hidesAccessoryWhenEditing = NO;
    NSNumber *active([theme objectForKey:@"Active"]);
    BOOL inactive(active == nil || ![active boolValue]);
    [cell setImage:(inactive ? uncheckedImage : checkImage)];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableDictionary *theme = [_themes objectAtIndex:indexPath.row];
    NSNumber *active = [theme objectForKey:@"Active"];
    BOOL inactive = active == nil || ![active boolValue];
    [theme setObject:[NSNumber numberWithBool:inactive] forKey:@"Active"];
    [cell setImage:(!inactive ? uncheckedImage : checkImage)];
    [tableView deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:YES];
    [self themesChanged];
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSUInteger fromIndex = [fromIndexPath row];
    NSUInteger toIndex = [toIndexPath row];
    if (fromIndex == toIndex)
        return;
    NSMutableDictionary *theme = [[[_themes objectAtIndex:fromIndex] retain] autorelease];
    [_themes removeObjectAtIndex:fromIndex];
    [_themes insertObject:theme atIndex:toIndex];
    [self themesChanged];
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
/* }}} */
@end
/* }}} */

@interface WBAdvancedController: PSListController {
}

- (id) specifiers;
- (void) settingsChanged;

@end

@implementation WBAdvancedController

- (id) specifiers {
    if (!_specifiers)
        _specifiers = [[self loadSpecifiersFromPlistName:@"Advanced" target:self] retain];
    return _specifiers;
}

- (void) settingsChanged {
    settingsChanged = YES;
}

- (void) setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {
    NSString *key([spec propertyForKey:@"key"]);
    if ([[spec propertyForKey:@"negate"] boolValue])
        value = [NSNumber numberWithBool:(![value boolValue])];
    [_settings setValue:value forKey:key];
    [self settingsChanged];
}

- (id) readPreferenceValue:(PSSpecifier *)spec {
    NSString *key([spec propertyForKey:@"key"]);
    id defaultValue([spec propertyForKey:@"default"]);
    id plistValue([_settings objectForKey:key]);
    if (!plistValue)
        return defaultValue;
    if ([[spec propertyForKey:@"negate"] boolValue])
        plistValue = [NSNumber numberWithBool:(![plistValue boolValue])];
    return plistValue;
}

- (void) __optimizeThemes {
    system("/usr/libexec/winterboard/Optimize");
}

- (void) optimizeThemes {
    UIAlertView *alert([[[UIAlertView alloc]
        initWithTitle:@"Optimize Themes"
        message:@"Please note that this setting /replaces/ the PNG files that came with the theme. PNG files that have been iPhone-optimized cannot be viewed on a normal computer unless they are first deoptimized. You can use Cydia to reinstall themes that have been optimized in order to revert to the original PNG files."
        delegate:self
        cancelButtonTitle:@"Cancel"
        otherButtonTitles:@"Optimize", nil
    ] autorelease]);

    [alert setContext:@"optimize"];
    [alert setNumberOfRows:1];
    [alert show];
}

- (void) _optimizeThemes {
    UIView *view([self view]);
    UIWindow *window([view window]);

    UIProgressHUD *hud([[[UIProgressHUD alloc] initWithWindow:window] autorelease]);
    [hud setText:@"Reticulating Splines\nPlease Wait (Minutes)"];

    [window setUserInteractionEnabled:NO];

    [window addSubview:hud];
    [hud show:YES];
    [self wb$yieldToSelector:@selector(__optimizeThemes)];
    [hud removeFromSuperview];

    [window setUserInteractionEnabled:YES];

    [self settingsChanged];
}

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)button {
    NSString *context([alert context]);

    if ([context isEqualToString:@"optimize"]) {
        if (button == [alert firstOtherButtonIndex]) {
            [self performSelector:@selector(_optimizeThemes) withObject:nil afterDelay:0];
        }

        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    }
    /*else if ([super respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
        [super alertView:alert clickedButtonAtIndex:button];*/
}

@end

@interface WBSettingsController: PSListController {
}

- (id) initForContentSize:(CGSize)size;
- (void) dealloc;
- (void) suspend;
- (void) navigationBarButtonClicked:(int)buttonIndex;
- (void) viewWillRedisplay;
- (void) pushController:(id)controller;
- (id) specifiers;
- (void) settingsChanged;
- (NSString *) title;
- (void) setPreferenceValue:(id)value specifier:(PSSpecifier *)spec;
- (id) readPreferenceValue:(PSSpecifier *)spec;

@end

@implementation WBSettingsController

+ (void) load {
    void *libhide(dlopen("/usr/lib/hide.dylib", RTLD_LAZY));
    IsIconHiddenDisplayId = reinterpret_cast<BOOL (*)(NSString *)>(dlsym(libhide, "IsIconHiddenDisplayId"));
    HideIconViaDisplayId = reinterpret_cast<BOOL (*)(NSString *)>(dlsym(libhide, "HideIconViaDisplayId"));
    UnHideIconViaDisplayId = reinterpret_cast<BOOL (*)(NSString *)>(dlsym(libhide, "UnHideIconViaDisplayId"));
}

- (void) _wb$loadSettings {
    _plist = [[NSString stringWithFormat:@"%@/Library/Preferences/com.saurik.WinterBoard.plist", NSHomeDirectory()] retain];
    _settings = [NSMutableDictionary dictionaryWithContentsOfFile:_plist];

    bool set;
    if (_settings != nil)
        set = true;
    else {
        set = false;
        _settings = [NSMutableDictionary dictionary];
    }

    _settings = [_settings retain];

    if ([_settings objectForKey:@"SummerBoard"] == nil)
        [_settings setObject:[NSNumber numberWithBool:set] forKey:@"SummerBoard"];

    [_settings setObject:[NSNumber numberWithBool:IsIconHiddenDisplayId(WinterBoardDisplayID)] forKey:@"IconHidden"];
}

- (id) initForContentSize:(CGSize)size {
    if ((self = [super initForContentSize:size]) != nil) {
        [self _wb$loadSettings];
    } return self;
}

- (void) dealloc {
    [_settings release];
    [_plist release];
    [super dealloc];
}

- (void) suspend {
    if (!settingsChanged)
        return;

    NSData *data([NSPropertyListSerialization dataFromPropertyList:_settings format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]);
    if (!data)
        return;
    if (![data writeToFile:_plist options:NSAtomicWrite error:NULL])
        return;

    ([[_settings objectForKey:@"IconHidden"] boolValue] ? HideIconViaDisplayId : UnHideIconViaDisplayId)(WinterBoardDisplayID);

    unlink("/User/Library/Caches/com.apple.springboard-imagecache-icons");
    unlink("/User/Library/Caches/com.apple.springboard-imagecache-icons.plist");
    unlink("/User/Library/Caches/com.apple.springboard-imagecache-smallicons");
    unlink("/User/Library/Caches/com.apple.springboard-imagecache-smallicons.plist");

    unlink("/User/Library/Caches/com.apple.SpringBoard.folderSwitcherLinen");
    unlink("/User/Library/Caches/com.apple.SpringBoard.notificationCenterLinen");

    unlink("/User/Library/Caches/com.apple.SpringBoard.folderSwitcherLinen.0");
    unlink("/User/Library/Caches/com.apple.SpringBoard.folderSwitcherLinen.1");
    unlink("/User/Library/Caches/com.apple.SpringBoard.folderSwitcherLinen.2");
    unlink("/User/Library/Caches/com.apple.SpringBoard.folderSwitcherLinen.3");

    system("rm -rf /User/Library/Caches/SpringBoardIconCache");
    system("rm -rf /User/Library/Caches/SpringBoardIconCache-small");
    system("rm -rf /User/Library/Caches/com.apple.IconsCache");
    system("rm -rf /User/Library/Caches/com.apple.newsstand");
    system("rm -rf /User/Library/Caches/com.apple.springboard.sharedimagecache");

    system("killall -9 lsd");

    if (kCFCoreFoundationVersionNumber > 700) // XXX: iOS 6.x
        system("killall backboardd");
    else
        system("killall SpringBoard");
}

- (void) cancelChanges {
    [_settings release];
    [_plist release];

    [self _wb$loadSettings];

    [self reloadSpecifiers];
    if (![[PSViewController class] instancesRespondToSelector:@selector(showLeftButton:withStyle:rightButton:withStyle:)]) {
        [[self navigationItem] setLeftBarButtonItem:nil];
        [[self navigationItem] setRightBarButtonItem:nil];
    } else {
        [self showLeftButton:nil withStyle:0 rightButton:nil withStyle:0];
    }
    settingsChanged = NO;
}

- (void) navigationBarButtonClicked:(int)buttonIndex {
    if (!settingsChanged) {
        [super navigationBarButtonClicked:buttonIndex];
        return;
    }

    if (buttonIndex == 0) {
        [self cancelChanges];
        return;
    }

    [self suspend];
    [self.rootController popController];
}

- (void) settingsConfirmButtonClicked:(UIBarButtonItem *)button {
    [self navigationBarButtonClicked:button.tag];
}

- (void) viewWillRedisplay {
    if (settingsChanged)
        [self settingsChanged];
    [super viewWillRedisplay];
}

- (void) viewWillAppear:(BOOL)animated {
    if (settingsChanged)
        [self settingsChanged];
    if ([super respondsToSelector:@selector(viewWillAppear:)])
        [super viewWillAppear:animated];
}

- (void) pushController:(id)controller {
    [self hideNavigationBarButtons];
    [super pushController:controller];
}

- (id) specifiers {
    if (!_specifiers)
        _specifiers = [[self loadSpecifiersFromPlistName:@"WinterBoard" target:self] retain];
    return _specifiers;
}

- (void) settingsChanged {
    if (![[PSViewController class] instancesRespondToSelector:@selector(showLeftButton:withStyle:rightButton:withStyle:)]) {
        UIBarButtonItem *respringButton([[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(settingsConfirmButtonClicked:)]);
        UIBarButtonItem *cancelButton([[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(settingsConfirmButtonClicked:)]);
        cancelButton.tag = 0;
        respringButton.tag = 1;
        [[self navigationItem] setLeftBarButtonItem:respringButton];
        [[self navigationItem] setRightBarButtonItem:cancelButton];
        [respringButton release];
        [cancelButton release];
    } else {
        [self showLeftButton:@"Respring" withStyle:2 rightButton:@"Cancel" withStyle:0];
    }
    settingsChanged = YES;
}

- (NSString *) title {
    return @"WinterBoard";
}

- (void) setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {
    NSString *key([spec propertyForKey:@"key"]);
    if ([[spec propertyForKey:@"negate"] boolValue])
        value = [NSNumber numberWithBool:(![value boolValue])];
    [_settings setValue:value forKey:key];
    [self settingsChanged];
}

- (id) readPreferenceValue:(PSSpecifier *)spec {
    NSString *key([spec propertyForKey:@"key"]);
    id defaultValue([spec propertyForKey:@"default"]);
    id plistValue([_settings objectForKey:key]);
    if (!plistValue)
        return defaultValue;
    if ([[spec propertyForKey:@"negate"] boolValue])
        plistValue = [NSNumber numberWithBool:(![plistValue boolValue])];
    return plistValue;
}

@end

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
