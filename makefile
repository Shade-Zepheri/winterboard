CLANG = clang++ -std=gnu++14 -i2.0 -lobjc -g0 -O2 -Werror -marm -I../include -F../frameworks -iframework/System/Library/Frameworks

substrate := -I../substrate -L../substrate -lsubstrate

all: WinterBoard.dylib WinterBoardSettings

clean:
	rm -f WinterBoard.dylib WinterBoardSettings

WinterBoardSettings: Settings.mm Makefile
	$(CLANG) Settings.mm Makefile -dynamiclib \
			-framework UIKit \
			-framework CoreFoundation \
	    -framework Foundation \
	    -framework CoreGraphics \
	    -framework Preferences \

WinterBoard.dylib: Library.mm WBMarkup.mm WBMarkup.h Makefile ../substrate/substrate.h
	$(CLANG) Library.mm WBMarkup.mm Makefile -dynamiclib \
			-framework CoreFoundation \
	    -framework Foundation \
	    -framework CoreGraphics \
	    -framework Celestial \
	    -framework UIKit \
	    -framework WebCore \
	    -framework WebKit \
	    $(substrate)

package: all
	sudo ./package.sh

.PHONY: all clean package
