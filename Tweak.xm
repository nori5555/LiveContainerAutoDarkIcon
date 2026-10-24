#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// LiveContainer's app list, banner, multitask dock and storage views all ask
// LCAppInfo for an icon with the manual "darkModeIcon" setting. That setting
// defaults to OFF and never follows the system appearance, so guest icons
// stay light even in dark mode unless the user flips it by hand.
//
// This tweak makes the choice automatic in two places, because the icon and
// the dynamic banner colors are decided separately:
//  1. Icon: whenever LiveContainer asks for an icon, answer with the dark
//     variant if the system is currently in dark mode, and the light
//     variant otherwise. LiveContainer already generates both variants on
//     demand (LCAppIconDark.png / LCAppIconLight.png), so switching is
//     instant after the first generation.
//  2. Dynamic colors: the banner/card colors are NOT derived from the icon
//     on the fly — LCAppBannerView reads the same manual "darkModeIcon"
//     setting and picks the cached light or dark color accordingly. Hooking
//     the icon alone therefore changes the icons but leaves the dynamic
//     colors on the light set. So this tweak also writes the setting
//     itself, following the live system appearance, in the app-group
//     defaults (via LCSharedUtils.appGroupID, so it works for both
//     SideStore and AltStore installs). The write is guarded so observers
//     only fire when the value actually changes.
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
// While this tweak is loaded, the manual darkModeIcon switch is driven by
// the tweak (a manual flip gets overwritten on the next sync); removing
// the tweak leaves the setting at its last synced value and restores
// manual control.

@interface LCSharedUtils : NSObject
+ (NSString *)appGroupID;
@end

typedef UIImage * (*LCIconIMP)(id, SEL, BOOL);
static LCIconIMP origIconIsDarkIcon = NULL;

static BOOL AutoDarkIconIsSystemDark(void) {
    return [UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

static void AutoDarkIconSyncSetting(void) {
    Class cls = objc_getClass("LCSharedUtils");
    if (!cls) return;
    NSString *groupID = [cls appGroupID];
    if (!groupID || [groupID isEqualToString:@"Unknown"]) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:groupID];
    if (!defaults) return;
    BOOL dark = AutoDarkIconIsSystemDark();
    if ([defaults boolForKey:@"darkModeIcon"] != dark) {
        [defaults setBool:dark forKey:@"darkModeIcon"];
    }
}

static UIImage *AutoDarkIconReplacement(id self, SEL _cmd, BOOL isDarkIcon) {
    // Ignore the manual setting; follow the live system appearance.
    // Syncing here too propagates runtime appearance changes to the
    // @AppStorage-backed views (banner colors included).
    AutoDarkIconSyncSetting();
    return origIconIsDarkIcon(self, _cmd, AutoDarkIconIsSystemDark());
}

__attribute__((constructor))
static void AutoDarkIconInit(void) {
    // Sync before any view reads the setting, so a fresh launch already
    // shows dark icons AND dark dynamic colors.
    AutoDarkIconSyncSetting();

    Class cls = objc_getClass("LCAppInfo");
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, @selector(iconIsDarkIcon:));
    if (!m) return;
    origIconIsDarkIcon = (LCIconIMP)method_getImplementation(m);
    method_setImplementation(m, (IMP)AutoDarkIconReplacement);
}
