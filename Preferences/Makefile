GO_EASY_ON_ME = 1
ARCHS = armv7 arm64
TARGET = iphone:clang

include theos/makefiles/common.mk

BUNDLE_NAME = VeloxPrefs
VeloxPrefs_FILES = $(wildcard *.mm) $(wildcard AFNetworking/*.m)
VeloxPrefs_INSTALL_PATH = /Library/PreferenceBundles
VeloxPrefs_FRAMEWORKS = UIKit Social AVFoundation AudioToolbox MobileCoreServices CoreGraphics Security SystemConfiguration
VeloxPrefs_PRIVATE_FRAMEWORKS = Preferences
VeloxPrefs_CFLAGS = -fobjc-arc
VeloxPrefs_LIBRARIES = applist MobileGestalt
VeloxPrefs_OBJ_FILES += $(wildcard AFNetworking/*.o)

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/VeloxPrefs.plist$(ECHO_END)
