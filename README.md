BSAppStoreWindow
================

BSAppStoreWindow is a NSWindow subclass that has an adjustable title bar height and center the traffic light buttons, just like the Mac App Store. Note that this does use method swizzling and private APIs, so it will probably not be allowed for use in the Mac App Store. This is an alternative solution to INAppStoreWindow if you aren't concerned about using private APIs. The benefit of this implementation is that it does not mimic the OS X title bar, but just resizes the actual native one.

This is released under the zlib license.