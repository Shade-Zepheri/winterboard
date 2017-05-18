#include "WNBRootListController.h"

BOOL settingsChanged;

@implementation WNBRootListController

- (void)loadSettings {
		_settings = [NSMutableDictionary dictionaryWithContentsOfFile:WNBPreferencePath];

		BOOL set;
		if (_settings) {
				set = YES;
		} else {
				set = NO;
				_settings = [NSMutableDictionary dictionary];
		}

		if (![_settings objectForKey:@"SummerBoard"]) {
				[_settings setObject:[NSNumber numberWithBool:set] forKey:@"SummerBoard"];
		}
}

- (instancetype)initForContentSize:(CGSize)size {
		self = [super initForContentSize:size];
		if (self) {
				[self loadSettings];
		}

		return self;
}

- (void)suspend {
		if (!settingsChanged) {
				return;
		}

		NSData *data = [NSPropertyListSerialization dataFromPropertyList:_settings format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
		if (!data) {
				return;
		}
		if (![data writeToFile:WNBPreferencePath options:NSAtomicWrite error:NULL]) {
				return;
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
		if (kCFCoreFoundationVersionNumber > 700) { // XXX: iOS 6.x
				system("killall backboardd");
		} else {
				system("killall SpringBoard");
		}
}

- (void)cancelChanges {
		[self loadSettings];

		[self reloadSpecifiers];
		if (![[PSViewController class] instancesRespondToSelector:@selector(showLeftButton:withStyle:rightButton:withStyle:)]) {
				[[self navigationItem] setLeftBarButtonItem:nil];
				[[self navigationItem] setRightBarButtonItem:nil];
		} else {
				[self showLeftButton:nil withStyle:0 rightButton:nil withStyle:0];
		}
		settingsChanged = NO;
}

- (void)navigationBarButtonClicked:(NSInteger)buttonIndex {
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

- (void)settingsConfirmButtonClicked:(UIBarButtonItem *)button {
		[self navigationBarButtonClicked:button.tag];
}

- (void)viewWillRedisplay {
		if (settingsChanged) {
				[self settingsChanged];
		}
		[super viewWillRedisplay];
}

- (void)viewWillAppear:(BOOL)animated {
		if (settingsChanged) {
				[self settingsChanged];
		}
		if ([super respondsToSelector:@selector(viewWillAppear:)]) {
				[super viewWillAppear:animated];
		}
}

- (void)pushController:(id)controller {
		[self hideNavigationBarButtons];
		[super pushController:controller];
}

- (NSArray*)specifiers {
		if (!_specifiers) {
				NSMutableArray *specifiers = [NSMutableArray array];
				for (PSSpecifier *specifier in [self loadSpecifiersFromPlistName:@"WinterBoard" target:self]) {
						if (NSArray *version = [specifier propertyForKey:@"wb$filter"]) {
								size_t count = [version count];
								if (count == 0 || count > 2) {
										continue;
								}

								double lower = [[version objectAtIndex:0] doubleValue];
								if (kCFCoreFoundationVersionNumber < lower) {
									continue;
								}

								if (count != 1) {
										double upper = [[version objectAtIndex:1] doubleValue];
										if (upper <= kCFCoreFoundationVersionNumber) {
												continue;
										}
								}
						}
						[specifiers addObject:specifier];
				}
				_specifiers = specifiers;
		}

		return _specifiers;
}

- (void)settingsChanged {
		if (![[PSViewController class] instancesRespondToSelector:@selector(showLeftButton:withStyle:rightButton:withStyle:)]) {
				UIBarButtonItem *respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(settingsConfirmButtonClicked:)];
				UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(settingsConfirmButtonClicked:)];
				cancelButton.tag = 0;
				respringButton.tag = 1;
				[self.navigationItem setLeftBarButtonItem:respringButton];
				[self.navigationItem setRightBarButtonItem:cancelButton];
		} else {
				[self showLeftButton:@"Respring" withStyle:2 rightButton:@"Cancel" withStyle:0];
		}
		settingsChanged = YES;
}

- (NSString *)title {
		return @"WinterBoard";
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

@end
