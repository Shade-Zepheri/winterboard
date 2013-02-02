ifndef PKG_TARG
target :=
else
target := $(PKG_TARG)-
endif

substrate := -I../mobilesubstrate -L../mobilesubstrate -lsubstrate

all: WinterBoard WinterBoard.dylib WinterBoardSettings Optimize

clean:
	rm -f WinterBoard WinterBoard.dylib

WinterBoardSettings: Settings.mm makefile
	$(target)g++ -dynamiclib -g0 -O2 -Wall -o $@ $(filter %.mm,$^) -framework UIKit -framework CoreFoundation -framework Foundation -lobjc -framework CoreGraphics -framework Preferences -F$(PKG_ROOT)/System/Library/PrivateFrameworks
	ldid -S $@

WinterBoard.dylib: Library.mm WBMarkup.mm WBMarkup.h makefile ../mobilesubstrate/substrate.h
	$(target)g++ -dynamiclib -g0 -O2 -Wall -o $@ $(filter %.mm,$^) -framework CoreFoundation -framework Foundation -lobjc -I/apl/inc/iPhoneOS-2.0 -framework CoreGraphics -framework ImageIO -framework GraphicsServices -framework Celestial $(substrate) -framework UIKit -framework WebCore -framework WebKit -F$(PKG_ROOT)/System/Library/PrivateFrameworks
	ldid -S $@

WinterBoard: Application.mm makefile
	$(target)g++ -g0 -O2 -Wall -Werror -o $@ $(filter %.mm,$^) -framework UIKit -framework Foundation -framework CoreFoundation -lobjc -framework CoreGraphics -I/apl/sdk -framework Preferences -F$(PKG_ROOT)/System/Library/PrivateFrameworks $(substrate)
	ldid -S $@

Optimize: Optimize.cpp makefile
	$(target)g++ -g0 -O2 -Wall -Werror -o $@ $(filter %.cpp,$^)
	ldid -S $@

package: all
	rm -rf winterboard
	mkdir -p winterboard/DEBIAN
	mkdir -p winterboard/Applications/WinterBoard.app
	mkdir -p winterboard/Library/Themes
	mkdir -p winterboard/Library/MobileSubstrate/DynamicLibraries
	mkdir -p winterboard/Library/PreferenceLoader/Preferences
	mkdir -p winterboard/System/Library/PreferenceBundles
	mkdir -p winterboard/usr/libexec/winterboard
	cp -a Optimize winterboard/usr/libexec/winterboard
	chmod 6755 winterboard/usr/libexec/winterboard/Optimize
	cp -a WinterBoardSettings.plist winterboard/Library/PreferenceLoader/Preferences
	cp -a WinterBoardSettings.bundle winterboard/System/Library/PreferenceBundles
	cp -a Icon-Small.png winterboard/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon.png
	cp -a Icon-Small@2x.png winterboard/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon@2x.png
	cp -a SearchResultsCheckmarkClear.png WinterBoardSettings winterboard/System/Library/PreferenceBundles/WinterBoardSettings.bundle
	ln -s /Applications/WinterBoard.app/WinterBoard.dylib winterboard/Library/MobileSubstrate/DynamicLibraries
	cp -a WinterBoard.plist winterboard/Library/MobileSubstrate/DynamicLibraries
	cp -a *.theme winterboard/Library/Themes
	find winterboard -name .svn | while read -r line; do rm -rf "$${line}"; done
	cp -a extrainst_ preinst prerm winterboard/DEBIAN
	sed -e 's/VERSION/$(shell ./version.sh)/g' control >winterboard/DEBIAN/control
	cp -a Test.sh Default-568h@2x.png Icon-Small.png icon.png icon-72.png icon@2x.png WinterBoard.dylib WinterBoard Info.plist winterboard/Applications/WinterBoard.app
	file="winterboard_$$(grep ^Version: winterboard/DEBIAN/control | cut -d ' ' -f 2)_iphoneos-arm.deb"; echo "$$file"; ln -sf "$$file" winterboard.deb
	dpkg-deb -b winterboard winterboard.deb

.PHONY: all clean package
