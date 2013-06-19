//
//  BSAppStoreWindow.h
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

#import <Cocoa/Cocoa.h>
#import <Availability.h>

#define BS_USE_PRIVATE_API 0

#if __has_feature(objc_arc)
#define bs_retain self
#define bs_release self
#define bs_autorelease self
#define bs_dealloc self
#else
#define bs_retain retain
#define bs_release release
#define bs_autorelease autorelease
#define bs_dealloc dealloc
#endif

#if BS_USE_PRIVATE_API

@interface BSAppStoreWindow : NSWindow

@property (nonatomic, assign) CGFloat titlebarHeight;
@property (nonatomic, assign) BOOL centerTitlebarButtons;

@end

#else

@interface BSAppStoreWindow : NSWindow <NSToolbarDelegate> {
    NSToolbarItem *_item;
    NSView *_view;
    CGFloat _defaultTitlebarHeight;
    CGFloat _defaultToolbarHeight;
}

@property (nonatomic, assign) CGFloat titlebarHeight;
@property (nonatomic, assign) BOOL centerTitlebarButtons;

@end

#endif
