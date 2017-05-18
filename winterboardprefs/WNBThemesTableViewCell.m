#import "WNBThemesTableViewCell.h"

@implementation WNBThemesTableViewCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuse {
    self = [super initWithFrame:frame reuseIdentifier:reuse];
    if (self) {
        CGFloat border = 48, check = 40, icon = 64;
        UIView *content = [self contentView];
        CGSize size = [content frame].size;

        self.checkmark = [[UIImageView alloc] initWithFrame:CGRectMake(std::floor((border - check) / 2), 0, check, size.height)];
        self.checkmark.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [content addSubview:self.checkmark];

        self.name = [[UILabel alloc] initWithFrame:CGRectMake(border, 0, 0, size.height)];
        self.name.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [content addSubview:self.name];

        self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(size.width - icon - 48, 0, icon, icon)];
        [content addSubview:self.icon];
    }

    return self;
}

- (void) setCheck:(BOOL)inactive {
    [self setImage:(inactive ? uncheckedImage : checkImage)];
}

- (void) setTheme:(NSDictionary *)theme {
    [self.name setText:[theme objectForKey:@"Name"]];

    NSNumber *active = [theme objectForKey:@"Active"]);
    BOOL inactive = !active || ![active boolValue];
    [self setCheck:inactive];

    CGRect area = [self.name frame];
    area.size.width = (![self.icon image] ? self.contentView.frame.size.width : self.icon.frame.origin.x) - area.origin.x - 9;
    self.name.frame = area;
}

@end
