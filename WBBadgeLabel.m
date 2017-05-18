#import "WBBadgeLabel.h"

@implementation WBBadgeLabel

- (instancetype)initWithBadge:(NSString *)badge {
    self.badge = badge;
    return self;
}

- (NSString *)description {
    return [self.badge description];
}

WBDelegate(self.badge)

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font lineBreakMode:(UILineBreakMode)mode {
    if (NSString *custom = [Info_ objectForKey:@"BadgeStyle"]) {
        [self.badge drawAtPoint:point withStyle:[NSString stringWithFormat:@""
            "font-family: Helvetica; "
            "font-weight: bold; "
            "font-size: 17px; "
            "color: white; "
        "%@", custom]];

        return CGSizeZero;
    }

    return [self.badge drawAtPoint:point forWidth:width withFont:font lineBreakMode:mode];
}

@end
