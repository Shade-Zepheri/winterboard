@interface WBBadgeLabel : NSProxy
@property (copy, nonatomic) NSString *badge;
- (instancetype)initWithBadge:(NSString *)badge;
- (NSString *)description;
@end
