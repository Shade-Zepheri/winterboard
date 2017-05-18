#import "WNBThemesController.h"
#import "WNBThemesTableViewCell.h"

@implementation WNBThemesController

+ (void)initialize {
    @autoreleasepool {
        _checkImage = [_UIImageWithName(@"UIPreferencesBlueCheck.png") retain];
        _uncheckedImage = [[UIImage imageWithContentsOfFile:@"/System/Library/PreferenceBundles/WinterBoardSettings.bundle/SearchResultsCheckmarkClear.png"] retain];
    }
}

- (instancetype)initForContentSize:(CGSize)size {
    self = [super initForContentSize:size];
    if (self) {
        self.themes = [_settings objectForKey:@"Themes"];
        if (!self.themes) {
            if (NSString *theme = [_settings objectForKey:@"Theme"]) {
                self.themes = [NSMutableArray arrayWithObject:
                         [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            theme, @"Name",
                                [NSNumber numberWithBool:YES], @"Active", nil]];
                [_settings removeObjectForKey:@"Theme"];
            }
            if (!self.themes)
                self.themes = [NSMutableArray array];
            [_settings setObject:self.themes forKey:@"Themes"];
        }

        NSMutableArray *themesOnDisk([NSMutableArray array]);
        AddThemes(themesOnDisk, @"/Library/Themes");
        AddThemes(themesOnDisk, [NSString stringWithFormat:@"%@/Library/SummerBoard/Themes", NSHomeDirectory()]);

        for (int i = 0, count = [themesOnDisk count]; i < count; i++) {
            NSString *theme = [themesOnDisk objectAtIndex:i];
            if ([theme hasSuffix:@".theme"])
                [themesOnDisk replaceObjectAtIndex:i withObject:[theme stringByDeletingPathExtension]];
        }

        NSMutableSet *themesSet([NSMutableSet set]);

        for (int i = 0, count = [self.themes count]; i < count; i++) {
            NSDictionary *theme([self.themes objectAtIndex:i]);
            NSString *name([theme objectForKey:@"Name"]);

            if (!name || ![themesOnDisk containsObject:name]) {
                [self.themes removeObjectAtIndex:i];
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

            [self.themes insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    theme, @"Name",
                    [NSNumber numberWithBool:NO], @"Active",
            nil] atIndex:0];
        }

        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
        self.tableView.rowHeight = 48;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.editing = YES;
        self.tableView.allowsSelectionDuringEditing = YES;
        if ([self respondsToSelector:@selector(setView:)])
            [self setView:self.tableView];
    }

    return self;
}

- (id)navigationTitle {
    return @"Themes";
}

- (id)view {
    return self.tableView;
}

- (void) themesChanged {
    settingsChanged = YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.themes.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WNBThemesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThemeCell"];
    if (!cell) {
        cell = [[[WNBThemesTableViewCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100) reuseIdentifier:@"ThemeCell"] autorelease];
        //[cell setTableViewStyle:UITableViewCellStyleDefault];
    }

    NSDictionary *theme = [self.themes objectAtIndex:indexPath.row];
    [cell setTheme:theme];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableDictionary *theme = [self.themes objectAtIndex:indexPath.row];
    NSNumber *active = [theme objectForKey:@"Active"];
    BOOL inactive = active == nil || ![active boolValue];
    [theme setObject:[NSNumber numberWithBool:inactive] forKey:@"Active"];
    [cell setImage:(!inactive ? _uncheckedImage : _checkImage)];
    [tableView deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:YES];
    [self themesChanged];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSUInteger fromIndex = [fromIndexPath row];
    NSUInteger toIndex = [toIndexPath row];
    if (fromIndex == toIndex)
        return;
    NSMutableDictionary *theme = [[[self.themes objectAtIndex:fromIndex] retain] autorelease];
    [self.themes removeObjectAtIndex:fromIndex];
    [self.themes insertObject:theme atIndex:toIndex];
    [self themesChanged];
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
