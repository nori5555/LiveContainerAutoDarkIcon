TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES :=

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := AutoDarkIcon

AutoDarkIcon_FILES := Tweak.xm
AutoDarkIcon_CFLAGS := -fobjc-arc
AutoDarkIcon_FRAMEWORKS := UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
