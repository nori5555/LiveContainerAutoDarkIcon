#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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
// IMPORTANT: do NOT implement this with Theos %hook. A %hook build links
// /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate, which does
// not exist on a jailed device, so LiveContainer fails to dlopen the tweak
// ("Library not loaded: CydiaSubstrate"). This file therefore uses raw
// Objective-C runtime swizzling only, which needs no extra framework —
// the same reason ReturnToLiveContainer loads fine while a %hook build
// does not.
//
// Install: put the built dylib in the global Tweaks folder, sign it, then
// in LiveContainer Settings tap the version number 5 times and enable
// "Load Tweaks to LiveContainer Itself", and restart LiveContainer.
// While this tweak is loaded, the manual darkModeIcon switch has no effect
// on icons; removing the tweak restores manual control.

typedef UIImage * (*LCIconIMP)(id, SEL, BOOL);
static LCIconIMP origIconIsDarkIcon = NULL;

static UIImage *AutoDarkIconReplacement(id self, SEL _cmd, BOOL isDarkIcon) {
    // Ignore the manual setting; follow the live system appearance.
    BOOL dark = [UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    return origIconIsDarkIcon(self, _cmd, dark);
}

__attribute__((constructor))
static void AutoDarkIconInit(void) {
    Class cls = objc_getClass("LCAppInfo");
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, @selector(iconIsDarkIcon:));
    if (!m) return;
    origIconIsDarkIcon = (LCIconIMP)method_getImplementation(m);
    method_setImplementation(m, (IMP)AutoDarkIconReplacement);
}
