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

#if BS_USE_PRIVATE_API

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

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
    // default values
    _titlebarHeight = _defaultTitlebarHeight;
    _centerTitlebarButtons = NO;
    
    return self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen];
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

#else

/** Minimum height of a toolbar item to increase the titlebar height */
const CGFloat BSMinimumToolbarHeight = 11.0;

@interface BSAppStoreWindow ()
- (void)initialSetup;
- (CGFloat)realTitlebarHeight;
- (void)setupToolbar;
- (void)layoutTitlebarButtons;
@end

@implementation BSAppStoreWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self) {
        [self initialSetup];
    }
    
    return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen];
    if (self) {
        [self initialSetup];
    }
    
    return self;
}

- (void)initialSetup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutTitlebarButtons) name:NSWindowDidResizeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutTitlebarButtons) name:NSWindowDidMoveNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutTitlebarButtons) name:NSWindowDidEndSheetNotification object:self];
    
    // find titlebar height
    _defaultTitlebarHeight = [self realTitlebarHeight];
    
    _item = [[NSToolbarItem alloc] initWithItemIdentifier:@"DummyToolbarItem"];
    _view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
    [_item setView:_view];
    
    [self setToolbar:[[NSToolbar alloc] initWithIdentifier:@"BSAppStoreWindowToolbar"]];
    [self setTitlebarHeight:50.0];
    [self setCenterTitlebarButtons:YES];
}

- (void)dealloc {
    [_item bs_release];
    [_view bs_release];
    [super bs_dealloc];
}

- (void)setToolbar:(NSToolbar *)toolbar {
    [super setToolbar:toolbar];
    [self setupToolbar];
}

- (CGFloat)realTitlebarHeight {
    CGFloat contentHeight = NSHeight([[self contentView] frame]);
    CGFloat windowHeight = NSHeight([self frame]);
    return windowHeight - contentHeight;
}

- (void)setupToolbar {
    NSToolbar *toolbar = [self toolbar];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeDefault];
    
    // get height before adding item
    _defaultToolbarHeight = [self realTitlebarHeight] - _defaultTitlebarHeight;
    _titlebarHeight = _defaultTitlebarHeight + _defaultToolbarHeight;
    
    [self setTitlebarHeight:_titlebarHeight];
}

- (void)setTitlebarHeight:(CGFloat)titlebarHeight {
    if (titlebarHeight < _defaultTitlebarHeight + _defaultToolbarHeight) {
        NSLog(@"%@ titlebar height must be at least %f", NSStringFromSelector(_cmd), _defaultTitlebarHeight + _defaultToolbarHeight);
    }
    
    _titlebarHeight = titlebarHeight;
    
    NSToolbar *toolbar = [self toolbar];
    
    // remove all current items
    NSUInteger count = [[toolbar items] count];
    for (NSUInteger i = 0; i < count; ++i) {
        [toolbar removeItemAtIndex:i];
    }
    
    [toolbar insertItemWithItemIdentifier:@"DummyToolbarItem" atIndex:0];
}

- (void)setCenterTitlebarButtons:(BOOL)centerTitlebarButtons {
    _centerTitlebarButtons = centerTitlebarButtons;
    [self layoutTitlebarButtons];
}

- (NSToolbarItem *)toolbarItemWithHeight:(CGFloat)height {
    height = MAX(1.0, height - _defaultToolbarHeight - _defaultTitlebarHeight + BSMinimumToolbarHeight);
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:@"DummyToolbarItem"];
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1, height)];
    [item setView:view];
    [view bs_release];
    
    return [item bs_autorelease];
}

- (void)layoutTitlebarButtons {
    if (!_centerTitlebarButtons) {
        return;
    }
    
    NSArray *siblings = [[[self contentView] superview] subviews];
    
    if ([siblings count] >= 3) {
        NSView *closeButton = [siblings objectAtIndex:0];
        NSRect closeButtonFrame = [closeButton frame];
        
        NSView *minimizeButton = [siblings objectAtIndex:2];
        NSRect minimizeButtonFrame = [minimizeButton frame];
        
        NSView *zoomButton = [siblings objectAtIndex:1];
        NSRect zoomButtonFrame = [zoomButton frame];
        
        if (![closeButton isKindOfClass:[NSButton class]] ||
            ![minimizeButton isKindOfClass:[NSButton class]] ||
            ![zoomButton isKindOfClass:[NSButton class]]) {
            return;
        }
        
        closeButtonFrame.origin.y = minimizeButtonFrame.origin.y = zoomButtonFrame.origin.y = NSHeight([self frame]) -
        ([self realTitlebarHeight] + NSHeight(closeButtonFrame)) * 0.5;
        
        [[[self contentView] superview] viewWillStartLiveResize];
        [closeButton setFrame:closeButtonFrame];
        [minimizeButton setFrame:minimizeButtonFrame];
        [zoomButton setFrame:zoomButtonFrame];
        [[[self contentView] superview] viewDidEndLiveResize];
    }
}

#pragma mark - Toolbar Delegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    return [self toolbarItemWithHeight:_titlebarHeight];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObject:@"DummyToolbarItem"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObject:@"DummyToolbarItem"];
}

@end

#endif
