@interface NSBundle (WinterBoard)
+ (NSBundle *)wb$bundleWithFile:(NSString *)path;
@end

@interface NSString (WinterBoard)
- (NSString *)wb$themedPath;
@end
