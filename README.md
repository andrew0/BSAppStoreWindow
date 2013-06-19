BSAppStoreWindow
================

BSAppStoreWindow is a NSWindow subclass that has an adjustable title bar height and center the traffic light buttons, just like the Mac App Store. There's an option to use private APIs, which uses method swizzling to modify the _titlebarHeight property of NSThemeFrame. The benefit of this implementation is that it does not mimic the OS X title bar, but just resizes the actual native one.

If the option to use private APIs is disabled, it will instead make an NSToolbar and use a dummy toolbar item to stretch out the titlebar. The downside of this is that the titlebar height must be at least 41.

Here's an example usage after setting the window's class to BSAppStoreWindow in Interface Builder:
``` objc
BSAppStoreWindow *window = (BSAppStoreWindow *)[self window];
[window setTitlebarHeight:45.0];
[window setCenterTitlebarButtons:YES];
```

![Example](http://i.imgur.com/ZhGuVEY.png)

This is released under the zlib license.