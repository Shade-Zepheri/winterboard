@interface WBTimeLabel : NSProxy {
    NSString *time_;
    SBStatusBarTimeView *view_;
}
- (instancetype)initWithTime:(NSString *)time view:(SBStatusBarTimeView *)view;
@end
