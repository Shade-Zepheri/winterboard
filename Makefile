export TARGET = iphone:9.3 #Making it iOS 8+ no ios 2.0 support

CFLAGS = -fobjc-arc -Wno-deprecated-declarations -ferror-limit=100

INSTALL_TARGET_PROCESSES = Preferences

ifeq ($(RESPRING),1)
INSTALL_TARGET_PROCESSES += SpringBoard
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Winterboard
Winterboard_FILES = $(wildcard *.x) $(wildcard *.m) Library.xm WBMarkup.mm
Winterboard_FRAMEWORKS = UIKit QuartzCore

SUBPROJECTS = winterboardprefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
