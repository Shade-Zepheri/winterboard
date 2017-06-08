//SB hooks here
#import "headers.h"

/*
MSHook(id, $initWithStyle$reuseIdentifier$, SBSearchTableViewCell *self, SEL sel, int style, NSString *reuse) {
    if ((self = _SBSearchTableViewCell$initWithStyle$reuseIdentifier$(self, sel, style, reuse)) != nil) {
        [self setBackgroundColor:[UIColor clearColor]];
    } return self;
}


MSHook(UIImage *, SBApplicationIcon$generateIconImage$, SBApplicationIcon *self, SEL sel, int type) {
    if (type == 2)
        if (![Info_ wb$boolForKey:@"ComposeStoreIcons"]) {
            if (IsWild_ && false) // XXX: delete this code, it should not be supported
                if (NSString *path72 = $pathForIcon$([self application], @"-72"))
                    return [UIImage imageWithContentsOfFile:path72];
            if (NSString *path = $pathForIcon$([self application]))
                if (UIImage *image = [UIImage imageWithContentsOfFile:path]) {
                    CGFloat width;
                    if ([$SBIcon respondsToSelector:@selector(defaultIconImageSize)])
                        width = [$SBIcon defaultIconImageSize].width;
                    else
                        width = 59;
                    return width == 59 ? image : [image _imageScaledToProportion:(width / 59.0) interpolationQuality:5];
                }
        }
    return _SBApplicationIcon$generateIconImage$(self, sel, type);
}
*/

// Oh FFS Saurik y u do dis
MSInstanceMessageHook0(id, SBUIController, init) {
    self = MSOldCall();
    if (self == nil)
        return nil;

    NSString *paper($getTheme$(Wallpapers_));
    if (paper != nil)
        paper = [paper stringByDeletingLastPathComponent];

    if (Debug_)
        NSLog(@"WB:Debug:Info = %@", [Info_ description]);

    if (paper != nil) {
        UIImageView *_wallpaperView(MSHookIvar<UIImageView *>(self, "_wallpaperView"));
        if (_wallpaperView) {
            [_wallpaperView removeFromSuperview];
            [_wallpaperView release];
            _wallpaperView = nil;
        }
    }

    UIView *_contentView(MSHookIvar<UIView *>(self, "_contentView"));

    UIView **player;
    if (_contentLayer) {
      player = &_contentLayer;
    } else if (_contentView) {
      player = &_contentView;
    } else {
        player = NULL;
    }
    UIView *layer(player == NULL ? nil : *player);

    UIWindow *window([[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]);
    UIView *content([[[UIView alloc] initWithFrame:[window frame]] autorelease]);
    [window setContentView:content];

    UIWindow *&_window(MSHookIvar<UIWindow *>(self, "_window"));
    [window setBackgroundColor:[_window backgroundColor]];
    [_window setBackgroundColor:[UIColor clearColor]];

    [window setLevel:-1000];
    [window setHidden:NO];

    /*if (player != NULL)
        *player = content;*/

    [content setBackgroundColor:[layer backgroundColor]];
    [layer setBackgroundColor:[UIColor clearColor]];

    UIView *indirect;
    if (!SummerBoard_ || !IsWild_)
        indirect = content;
    else {
        CGRect bounds([content bounds]);
        bounds.origin.y = -30;
        indirect = [[[UIView alloc] initWithFrame:bounds] autorelease];
        [content addSubview:indirect];
        [indirect zoomToScale:2.4];
    }

    if (paper != nil) {
        NSArray *themes([NSArray arrayWithObject:paper]);

        if (NSString *path = $getTheme$([NSArray arrayWithObject:@"Wallpaper.mp4"], themes)) {
#if UseAVController
            NSError *error;

            static AVController *controller_(nil);
            if (controller_ == nil) {
                AVQueue *queue([AVQueue avQueue]);
                controller_ = [[AVController avControllerWithQueue:queue error:&error] retain];
            }

            AVQueue *queue([controller_ queue]);

            UIView *video([[[UIView alloc] initWithFrame:[indirect bounds]] autorelease]);
            [controller_ setLayer:[video _layer]];

            AVItem *item([[[AVItem alloc] initWithPath:path error:&error] autorelease]);
            [queue appendItem:item error:&error];

            [controller_ play:&error];
#elif UseMPMoviePlayerController
            NSURL *url([NSURL fileURLWithPath:path]);
            MPMoviePlayerController *controller = [[$MPMoviePlayerController alloc] initWithContentURL:url];
            controller.movieControlMode = MPMovieControlModeHidden;
            [controller play];
#else
            MPVideoView *video = [[[$MPVideoView alloc] initWithFrame:[indirect bounds]] autorelease];
            [video setMovieWithPath:path];
            [video setRepeatMode:1];
            [video setRepeatGap:-1];
            [video playFromBeginning];;
#endif

            [indirect addSubview:video];
        }

        if (NSString *path = $getTheme$($useScale$([NSArray arrayWithObjects:@"Wallpaper.png", @"Wallpaper.jpg", nil]), themes)) {
            if (UIImage *image = $getImage$(path)) {
                WallpaperFile_ = [path retain];
                WallpaperImage_ = [[UIImageView alloc] initWithImage:image];
                if (NSNumber *number = [Info_ objectForKey:@"WallpaperAlpha"])
                    [WallpaperImage_ setAlpha:[number floatValue]];
                [indirect addSubview:WallpaperImage_];
            }
        }

        if (NSString *path = $getTheme$([NSArray arrayWithObject:@"Wallpaper.html"], themes)) {
            CGRect bounds = [indirect bounds];

            UIWebDocumentView *view([[[$UIWebDocumentView alloc] initWithFrame:bounds] autorelease]);
            [view setAutoresizes:true];

            WallpaperPage_ = [view retain];
            WallpaperURL_ = [[NSURL fileURLWithPath:path] retain];

            [WallpaperPage_ loadRequest:[NSURLRequest requestWithURL:WallpaperURL_]];

            [view setBackgroundColor:[UIColor clearColor]];
            if ([view respondsToSelector:@selector(setDrawsBackground:)])
                [view setDrawsBackground:NO];
            [[view webView] setDrawsBackground:NO];

            [indirect addSubview:view];
        }
    }

    for (size_t i(0), e([Themes_ count]); i != e; ++i) {
        NSString *theme = [Themes_ objectAtIndex:(e - i - 1)];
        NSString *html = [theme stringByAppendingPathComponent:@"Widget.html"];
        if ([Manager_ fileExistsAtPath:html]) {
            CGRect bounds = [indirect bounds];

            UIWebDocumentView *view([[[$UIWebDocumentView alloc] initWithFrame:bounds] autorelease]);
            [view setAutoresizes:true];

            NSURL *url = [NSURL fileURLWithPath:html];
            [view loadRequest:[NSURLRequest requestWithURL:url]];

            [view setBackgroundColor:[UIColor clearColor]];
            if ([view respondsToSelector:@selector(setDrawsBackground:)])
                [view setDrawsBackground:NO];
            [[view webView] setDrawsBackground:NO];

            [indirect addSubview:view];
        }
    }

    return self;
}

MSInstanceMessageHook0(void, SBIconContentView, layoutSubviews) {
    MSOldCall();

    if (SBIconController *controller = [$SBIconController sharedInstance]) {
        UIView *&_dockContainerView(MSHookIvar<UIView *>(controller, "_dockContainerView"));
        if (_dockContainerView) {
          [[_dockContainerView superview] bringSubviewToFront:_dockContainerView];
        }
    }
}

static bool wb$inDock(id parameters) {
    return [$objc_getAssociatedObject(parameters, @selector(wb$inDock)) boolValue];
}

MSInstanceMessage0(NSUInteger, SBIconLabelImageParameters, hash) {
    return MSOldCall() + (wb$inDock(self) ? 0xdeadbeef : 0xd15ea5e);
}

MSInstanceMessage0(id, SBIconView, _labelImageParameters) {
    if (id parameters = MSOldCall()) {
        int &location(MSHookIvar<int>(self, "_iconLocation"));
        if (location) {
            $objc_setAssociatedObject(parameters, @selector(wb$inDock), [NSNumber numberWithBool:(location == 3)], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return parameters;
    } return nil;
}

MSClassMessage1(UIImage *, SBIconLabelImage, _drawLabelImageForParameters, id, parameters) {
    bool docked(wb$inDock(parameters));

    WBStringDrawingState labelState = {NULL, 0, @""
    , docked ? @"DockedIconLabelStyle" : @"UndockedIconLabelStyle"};

    stringDrawingState_ = &labelState;

    //NSLog(@"XXX: +");
    UIImage *image(MSOldCall(parameters));
    //NSLog(@"XXX: -");

    stringDrawingState_ = NULL;
    return image;
}

MSClassMessageHook2(id, SBIconBadgeView, checkoutAccessoryImagesForIcon,location, id, icon, int, location) {
    WBStringDrawingState badgeState = {NULL, 0, @""
    , @"BadgeStyle"};

    stringDrawingState_ = &badgeState;

    id images(MSOldCall(icon, location));

    stringDrawingState_ = NULL;
    return images;
}

MSInstanceMessageHook1(UIImage *, SBCalendarApplicationIcon, generateIconImage, int, type) {
    WBStringDrawingState dayState = {NULL, unsigned(kCFCoreFoundationVersionNumber >= 1200 ? 3 : 2), @""
        // XXX: this is only correct on an iPod dock
        "text-shadow: rgba(0, 0, 0, 0.2) -1px -1px 2px;"
    , @"CalendarIconDayStyle"};

    unsigned skips;
    if (kCFCoreFoundationVersionNumber < 800)
        skips = 7;
    else if (kCFCoreFoundationVersionNumber < 1200)
        skips = 16;
    else
        skips = 7;

    WBStringDrawingState skipState = {&dayState, skips, nil, nil};

    WBStringDrawingState dateState = {&skipState, 2, @""
    , @"CalendarIconDateStyle"};

    stringDrawingState_ = &dateState;

    UIImage *image(MSOldCall(type));

    stringDrawingState_ = NULL;
    return image;
}

%hook SBSearchTableViewCell
- (instancetype)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    orig = %orig;
    if (orig) {
        self.backgroundColor = [UIColor clearColor];
    }

    return orig;
}
%end

%hook SBApplicationIcon
- (id)generateIconImage:(int)arg1 {
    if (type == 2) {
        if (![Info_ wb$boolForKey:@"ComposeStoreIcons"]) {
            if (NSString *path = $pathForIcon$([self application])) {
                if (UIImage *image = [UIImage imageWithContentsOfFile:path]) {
                    CGFloat width;
                    if ([%c(SBIcon) respondsToSelector:@selector(defaultIconImageSize)]) {
                        width = [%c(SBIcon) defaultIconImageSize].width;
                    } else {
                        width = 59;
                    }
                    return width == 59 ? image : [image _imageScaledToProportion:(width / 59.0) interpolationQuality:5];
                }
            }
        }
    }

    return %orig;
}
%end

%hook SBUIController
- (instancetype)init {
    orig = %orig;
    if (orig) {

    }

    return orig;
}
%end

static inline void respring_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (IS_IOS_OR_NEWER(iOS_9_3)) {
        SBSRelaunchAction *restartAction = [%c(SBSRelaunchAction) actionWithReason:@"RestartRenderServer" options:SBSRelaunchOptionsFadeToBlack targetURL:nil];
        [[%c(FBSSystemService) sharedService] sendActions:[NSSet setWithObject:restartAction] withResult:nil];
    } else {
        [(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
    }
}

%ctor {
    if (!IN_SPRINGBOARD) {
        return;
    }

    Wallpapers_ = [[NSArray arrayWithObjects:@"Wallpaper.mp4", @"Wallpaper@3x.png", @"Wallpaper@3x.jpg", @"Wallpaper@2x.png", @"Wallpaper@2x.jpg", @"Wallpaper.png", @"Wallpaper.jpg", @"Wallpaper.html", nil] retain];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &ChangeWallpaper, (CFStringRef) @"com.saurik.winterboard.lockbackground", NULL, CFNotificationSuspensionBehaviorCoalesce);

    if ($getTheme$([NSArray arrayWithObject:@"Wallpaper.mp4"]) != nil) {
        NSBundle *MediaPlayer([NSBundle bundleWithPath:@"/System/Library/Frameworks/MediaPlayer.framework"]);
        if (MediaPlayer != nil)
            [MediaPlayer load];

        $MPMoviePlayerController = %c(MPMoviePlayerController);
        $MPVideoView = %c(MPVideoView);
    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &respring_notification, CFSTR("com.saurik.WinterBoard/Respring"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
