//
//  BSAppStoreWindow.m
//  BSAppStoreWindow
//
//  Copyright (c) 2013 Bison Software
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "BSAppStoreWindow.h"
#import "JRSwizzle.h"

static CGFloat _defaultTitlebarHeight = 22.0;

@interface NSView (Private)
- (void)_resetTitleBarButtons;
@end

@interface NSView (Swizzle)
- (CGFloat)bs_titlebarHeight;
- (CGFloat)bs_minYTitlebarButtonsOffset;
- (BOOL)bs_canHaveToolbar;
@end

@implementation NSView (Swizzle)

- (CGFloat)bs_titlebarHeight {
    // store default height for traffic light offset calculation
    _defaultTitlebarHeight = [self bs_titlebarHeight];
    
    // only change for BSAppStoreWindow
    if ([[self window] isKindOfClass:[BSAppStoreWindow class]]) {
        return [(BSAppStoreWindow *)[self window] titlebarHeight];
    }
    
    return _defaultTitlebarHeight;
}

- (CGFloat)bs_minYTitlebarButtonsOffset {
    // find the height of the window buttons. only do this once to not kill performance
    static CGFloat titlebarButtonHeight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSButton *button = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:self.window.styleMask];
        titlebarButtonHeight = button.frame.size.height;
    });
    
    // only change for BSAppStoreWindow
    if ([[self window] isKindOfClass:[BSAppStoreWindow class]]) {
        BSAppStoreWindow *window = (BSAppStoreWindow *)[self window];
        if ([window centerTitlebarButtons]) {
            // center of titlebar
            return (-[window titlebarHeight] + titlebarButtonHeight) * 0.5;
        } else {
            // find the distance from the top for the default implementation and apply to new titlebar height
            CGFloat distance = _defaultTitlebarHeight + [self bs_minYTitlebarButtonsOffset];
            return -[window titlebarHeight] + distance;
        }
    }
    
    // return default implementation
    return [self bs_minYTitlebarButtonsOffset];
}

- (BOOL)bs_canHaveToolbar {
    // never allow toolbars
    if ([[self window] isKindOfClass:[BSAppStoreWindow class]]) {
        return NO;
    }
    
    return [self bs_canHaveToolbar];
}

@end

@implementation BSAppStoreWindow

+ (void)load {
    [NSClassFromString(@"NSThemeFrame") jr_swizzleMethod:NSSelectorFromString(@"_titlebarHeight") withMethod:@selector(bs_titlebarHeight) error:nil];
    [NSClassFromString(@"NSThemeFrame") jr_swizzleMethod:NSSelectorFromString(@"_minYTitlebarButtonsOffset") withMethod:@selector(bs_minYTitlebarButtonsOffset) error:nil];
    [NSClassFromString(@"NSThemeFrame") jr_swizzleMethod:NSSelectorFromString(@"_canHaveToolbar") withMethod:@selector(bs_canHaveToolbar) error:nil];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    // default values
    _titlebarHeight = _defaultTitlebarHeight;
    _centerTitlebarButtons = NO;
    
    return self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
}

- (void)setTitlebarHeight:(CGFloat)titlebarHeight {
    _titlebarHeight = MAX(_defaultTitlebarHeight, titlebarHeight);
    [[[self contentView] superview] _resetTitleBarButtons];
}

- (void)setCenterTitlebarButtons:(BOOL)centerTitlebarButtons {
    _centerTitlebarButtons = centerTitlebarButtons;
    [[[self contentView] superview] _resetTitleBarButtons];
}

@end
