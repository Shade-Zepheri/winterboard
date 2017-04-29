export TARGET = iphone:9.3

CFLAGS = -fobjc-arc

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Winterboard
Winterboard_FILES = Library.mm WBMarkup.mm
Winterboard_FRAMEWORKS = UIKit QuartzCore

BUNDLE_NAME = Winterboard-Default
Winterboard-Default_INSTALL_PATH = /Library/Themes/

SUBPROJECTS = winterboardprefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
