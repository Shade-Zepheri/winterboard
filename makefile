cycc = cycc -i2.0 -o$@ -- -Iiphone-api

substrate := -I../substrate -L../substrate -lsubstrate

all: WinterBoard WinterBoard.dylib WinterBoardSettings Optimize

clean:
	rm -f WinterBoard WinterBoard.dylib

WinterBoardSettings: Settings.mm makefile
	$(cycc) -dynamiclib -g0 -O2 $(filter %.mm,$^) -framework UIKit -framework CoreFoundation -framework Foundation -lobjc -framework CoreGraphics -framework Preferences -F$(PKG_ROOT)/System/Library/PrivateFrameworks

WinterBoard.dylib: Library.mm WBMarkup.mm WBMarkup.h makefile ../substrate/substrate.h
	$(cycc) -dynamiclib -g0 -O2 $(filter %.mm,$^) -framework CoreFoundation -framework Foundation -lobjc -I/apl/inc/iPhoneOS-2.0 -framework CoreGraphics -framework ImageIO -framework GraphicsServices -framework Celestial $(substrate) -framework UIKit -framework WebCore -framework WebKit -F$(PKG_ROOT)/System/Library/PrivateFrameworks

WinterBoard: Application.mm makefile
	$(cycc) -g0 -O2 -Werror $(filter %.mm,$^) -framework UIKit -framework Foundation -framework CoreFoundation -lobjc -framework CoreGraphics -I/apl/sdk -framework Preferences -F$(PKG_ROOT)/System/Library/PrivateFrameworks $(substrate)

Optimize: Optimize.cpp makefile
	$(cycc) -g0 -O2 -Werror $(filter %.cpp,$^)

package: all
	rm -rf package
	mkdir -p package/DEBIAN
	mkdir -p package/Applications/WinterBoard.app
	mkdir -p package/Library/Themes
	mkdir -p package/Library/MobileSubstrate/DynamicLibraries
	mkdir -p package/Library/PreferenceLoader/Preferences
	mkdir -p package/System/Library/PreferenceBundles
	mkdir -p package/usr/libexec/package
	cp -a Optimize package/usr/libexec/package
	chmod 6755 package/usr/libexec/package/Optimize
	cp -a WinterBoardSettings.plist package/Library/PreferenceLoader/Preferences
	cp -a WinterBoardSettings.bundle package/System/Library/PreferenceBundles
	cp -a Icon-Small.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon.png
	cp -a Icon-Small@2x.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon@2x.png
	cp -a SearchResultsCheckmarkClear.png WinterBoardSettings package/System/Library/PreferenceBundles/WinterBoardSettings.bundle
	ln -s /Applications/WinterBoard.app/WinterBoard.dylib package/Library/MobileSubstrate/DynamicLibraries
	cp -a WinterBoard.plist package/Library/MobileSubstrate/DynamicLibraries
	cp -a *.theme package/Library/Themes
	find package -name .svn | while read -r line; do rm -rf "$${line}"; done
	cp -a extrainst_ preinst prerm package/DEBIAN
	sed -e 's/VERSION/$(shell ./version.sh)/g' control >package/DEBIAN/control
	cp -a Test.sh Default-568h@2x.png Icon-Small.png icon.png icon-72.png icon@2x.png WinterBoard.dylib WinterBoard Info.plist package/Applications/WinterBoard.app
	file="winterboard_$$(grep ^Version: package/DEBIAN/control | cut -d ' ' -f 2)_iphoneos-arm.deb"; echo "$$file"; ln -sf "$$file" winterboard.deb
	dpkg-deb -Zlzma -b package winterboard.deb

.PHONY: all clean package
