#import <UIKit/UIKit.h>

// LiveContainer's app list, banner, multitask dock and storage views all ask
// LCAppInfo for an icon with the manual "darkModeIcon" setting. That setting
// defaults to OFF and never follows the system appearance, so guest icons
// stay light even in dark mode unless the user flips it by hand.
//
// This tweak makes the choice automatic: whenever LiveContainer asks for an
// icon, answer with the dark variant if the system is currently in dark
// mode, and the light variant otherwise. LiveContainer already generates
// both variants on demand (LCAppIconDark.png / LCAppIconLight.png), so
// switching is instant after the first generation.
//
// Install: put the built dylib in the global Tweaks folder, sign it, then
// in LiveContainer Settings tap the version number 5 times and enable
// "Load Tweaks to LiveContainer Itself", and restart LiveContainer.
// While this tweak is loaded, the manual darkModeIcon switch has no effect
// on icons; removing the tweak restores manual control.

@interface LCAppInfo : NSObject
- (UIImage *)iconIsDarkIcon:(BOOL)isDarkIcon;
@end

%hook LCAppInfo

- (UIImage *)iconIsDarkIcon:(BOOL)isDarkIcon {
    // Ignore the manual setting; follow the live system appearance.
    BOOL dark = [UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    return %orig(dark);
}

%end
