#import "WNBAdvancedController.h"
#import "WNBRootListController.h"

extern BOOL settingsChanged;

@implementation WNBAdvancedController

- (NSArray*)specifiers {
    if (!_specifiers) {
      _specifiers = [self loadSpecifiersFromPlistName:@"Advanced" target:self];
    }

    return _specifiers;
}

- (void)settingsChanged {
    settingsChanged = YES;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:WNBPreferencePath];
    if (!settings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return settings[specifier.properties[@"key"]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:WNBPreferencePath]];
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:WNBPreferencePath atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
      CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

- (void)restartSpringBoard {
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
    system("rm -rf /User/Library/Caches/com.apple.UIStatusBar");

    system("rm -rf /User/Library/Caches/BarDialer");
    system("rm -rf /User/Library/Caches/BarDialer_selected");
    system("rm -rf /User/Library/Caches/BarRecents");
    system("rm -rf /User/Library/Caches/BarRecents_selected");
    system("rm -rf /User/Library/Caches/BarVM");
    system("rm -rf /User/Library/Caches/BarVM_selected");

    system("killall -9 lsd");

    //TODO: Use proper respring methods
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.saurik.WinterBoard/Respring"), nil, nil, YES);
}

- (void)__optimizeThemes {
    system("/usr/bin/find -P /Library/Themes/ -name '*.png' -not -xtype l -print0 | /usr/bin/xargs -0 pincrush -i");
}

- (void)optimizeThemes {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Optimize Themes" message:@"Please note that this setting /replaces/ the PNG files that came with the theme. PNG files that have been iPhone-optimized cannot be viewed on a normal computer unless they are first deoptimized. You can use Cydia to reinstall themes that have been optimized in order to revert to the original PNG files." preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *optimize = [UIAlertAction actionWithTitle:@"Optimize" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self performSelector:@selector(_optimizeThemes) withObject:nil afterDelay:0];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];

    [alert addAction:optimize];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)_optimizeThemes {
    UIView *view = [self view];
    UIWindow *window = [view window];

    UIProgressHUD *hud = [[[UIProgressHUD alloc] initWithWindow:window] autorelease];
    [hud setText:@"Reticulating Splines\nPlease Wait (Minutes)"];

    [window setUserInteractionEnabled:NO];

    [window addSubview:hud];
    [hud show:YES];
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ //I think this is what yieldToSelector does
        [self __optimizeThemes];
    });
    [hud removeFromSuperview];

    [window setUserInteractionEnabled:YES];

    [self settingsChanged];
}

@end
