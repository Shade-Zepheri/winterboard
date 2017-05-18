#import "WBTimeLabel.h"

@implementation WBTimeLabel

- (instancetype)initWithTime:(NSString *)time view:(SBStatusBarTimeView *)view {
    time_ = [time retain];
    view_ = view;
    return self;
}

- (NSString *) description {
    return time_;
}

//WBDelegate(time_)

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont*)font lineBreakMode:(UILineBreakMode)mode {
    if (NSString *custom = [Info_ objectForKey:@"TimeStyle"]) {
        BOOL &_mode(MSHookIvar<BOOL>(view_, "_mode"));;

        [time_ drawAtPoint:point withStyle:[NSString stringWithFormat:@""
            "font-family: Helvetica; "
            "font-weight: bold; "
            "font-size: 14px; "
            "color: %@; "
        "%@", _mode ? @"white" : @"black", custom]];

        return CGSizeZero;
    }

    return [time_ drawAtPoint:point forWidth:width withFont:font lineBreakMode:mode];
}

@end
