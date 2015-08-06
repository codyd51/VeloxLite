ARCHS = armv7 arm64
export TARGET = iphone:clang:latest
export GO_EASY_ON_ME = 1
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = VeloxLite
VeloxLite_FILES = Tweak.xm 
VeloxLite_FILES += UIImage+Color.mm 
VeloxLite_FILES += UIImage+AverageColor.mm 
VeloxLite_FILES += VeloxNotificationController.xm 
VeloxLite_FILES += VeloxGenericNotificationView.xm 
VeloxLite_OBJ_FILES += $(wildcard FBKVOController/*.m.o)

#VeloxLite_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/VeloxLite/

#VeloxLite_LOGOSFLAGS = -c generator=internal
#TARGET = simulator

VeloxLite_FRAMEWORKS = UIKit 
VeloxLite_FRAMEWORKS += CoreGraphics 
VeloxLite_FRAMEWORKS += QuartzCore 
#VeloxLite_FRAMEWORKS += WebKit 
VeloxLite_FRAMEWORKS += Accounts 
VeloxLite_FRAMEWORKS += Social
VeloxLite_FRAMEWORKS += AudioToolbox

VeloxLite_CFLAGS=-D__ARM64__

include $(THEOS_MAKE_PATH)/tweak.mk

#internal-stage::
#	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/Velox$(ECHO_END)

after-stage::
	find $(FW_STAGING_DIR) -iname '*.plist' -or -iname '*.strings' -exec plutil -convert binary1 {} \;
	find $(FW_STAGING_DIR) -iname '*.png' -exec pincrush-osx -i {} \;
#after-stage::
#	$(ECHO_NOTHING)ssh root@$(THEOS_DEVICE_IP) -p $(THEOS_DEVICE_PORT) killall -9 MobileCydia || exit 0$(ECHO_END) #to stop those dpkg from being locked by cydia multitasking

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += Preferences

include $(THEOS_MAKE_PATH)/aggregate.mk
