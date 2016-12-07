#!/bin/bash

# WinterBoard - Theme Manager for the iPhone
# Copyright (C) 2008-2014  Jay Freeman (saurik)

# GNU Lesser General Public License, Version 3 {{{ */
#
# WinterBoard is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# WinterBoard is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with WinterBoard.  If not, see <http://www.gnu.org/licenses/>.
# }}}


set -e
rm -rf package
mkdir -p package/DEBIAN
mkdir -p package/Library/Themes
mkdir -p package/Library/MobileSubstrate/DynamicLibraries
mkdir -p package/Library/PreferenceLoader/Preferences
mkdir -p package/System/Library/PreferenceBundles
mkdir -p package/usr/libexec/winterboard
cp -a WinterBoardSettings.plist package/Library/PreferenceLoader/Preferences
cp -a WinterBoardSettings7.plist package/Library/PreferenceLoader/Preferences
cp -a WinterBoardSettings.bundle package/System/Library/PreferenceBundles
cp -a Icon-Small.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon.png
cp -a Icon-Small@2x.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon@2x.png
cp -a Icon-Small7.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon7.png
cp -a Icon-Small7@2x.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon7@2x.png
cp -a Icon-Small7@3x.png package/System/Library/PreferenceBundles/WinterBoardSettings.bundle/icon7@3x.png
cp -a SearchResultsCheckmarkClear.png WinterBoardSettings package/System/Library/PreferenceBundles/WinterBoardSettings.bundle
cp -a WinterBoard.dylib package/Library/MobileSubstrate/DynamicLibraries
cp -a WinterBoard.plist package/Library/MobileSubstrate/DynamicLibraries
cp -a *.theme package/Library/Themes
find package -name .svn | while read -r line; do rm -rf "${line}"; done
cp -a extrainst_ preinst prerm package/DEBIAN
sed -e "s/VERSION/$(./version.sh)/g" control >package/DEBIAN/control
chown -R 0:0 package
file="winterboard_$(grep ^Version: package/DEBIAN/control | cut -d ' ' -f 2)_iphoneos-arm.deb"; echo "$file"; ln -sf "$file" winterboard.deb
dpkg-deb -Zlzma -b package winterboard.deb
