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
	sudo ./package.sh

.PHONY: all clean package
