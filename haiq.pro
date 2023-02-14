MIN_QT_VERSION = 5.15.0

NAME        = "HAiQ"
DESCRIPTION = "$$NAME - QML based UIs for Home-Assistant."
COPYRIGHT   = "2004-2022 Robert Griebl"
GITHUB_URL  = "github.com/rgriebl/haiq"


##NOTE: The VERSION is set in the file "VERSION" and pre-processed in .qmake.conf


requires(linux|macos|win32:!winrt)
!versionAtLeast(QT_VERSION, $$MIN_QT_VERSION) {
    error("$$escape_expand(\\n\\n) *** $$NAME needs to be built against $$MIN_QT_VERSION or higher ***$$escape_expand(\\n\\n)")
}

TEMPLATE = app

TARGET = $$NAME
unix:!macos:TARGET = $$lower($$TARGET)

CONFIG *= no_private_qt_headers_warning no_include_pwd c++17

DESTDIR = bin

version_subst.input  = src/version.h.in
version_subst.output = src/version.h
QMAKE_SUBSTITUTES    = version_subst

INCLUDEPATH = $$OUT_PWD/src  # for version.h

static {
  win32:QTPLUGIN.scenegraph = -  ## get rid of hard D3D12 dependency
  QTPLUGIN *= qsvg
}

include(src/src.pri)

OTHER_FILES += \
    src/version.h.in \
    icons/haiq.ico \
    utils/haiq.iss \
    utils/haiq.service \
    utils/create-debian-changelog.sh \
    icons/oa/*.svg \
    debian/* \
    LICENSE.GPL \
    README.md \
    VERSION \
    icons/COPYING-ICONS \
    sounds/*.wav \
    .gitignore \
    .github/workflows/*.yml \

DISTFILES += \
    android/AndroidManifest.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew \
    android/gradlew.bat \
    android/res/values/libs.xml \
    android/src/org/griebl/haiq/OpenUrlClient.java \

RESOURCES += \
    sounds.qrc \

live_reload {
    android:error("Live reloading is not working on Android")
    log("Resources are accessed directly")

    BASE_PATH = "$$SOURCE_DIR"
    DEFINES *= HAIQ_LIVE_RELOAD
} else {
    log("Resources are accessed indirectly via QRC")

    BASE_PATH = ":/"

    RESOURCES += \
        qml.qrc \
        icons.qrc \
}

DEFINES *= HAIQ_BASE_PATH=\\\"$$BASE_PATH\\\"

#
# Unix specific
#

unix:!android {
  debug:OBJECTS_DIR   = $$OUT_PWD/.obj/debug
  release:OBJECTS_DIR = $$OUT_PWD/.obj/release
  debug:MOC_DIR       = $$OUT_PWD/.moc/debug
  release:MOC_DIR     = $$OUT_PWD/.moc/release
  UI_DIR              = $$OUT_PWD/.uic
  RCC_DIR             = $$OUT_PWD/.rcc

  QMAKE_CXXFLAGS *= -Wno-deprecated-declarations
}

#
# Android specific
#

android {
  ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
  ANDROID_VERSION_CODE=$$num_add("$${VERSION_MAJOR}000000", "$${VERSION_MINOR}000", $$VERSION_PATCH)
  ANDROID_VERSION_NAME=$$VERSION

  # We expect KDAB's OpenSSL libs in $ANDROID_SDK_ROOT/android_openssl
  # cd $ANDROID_SDK_ROOT && git clone https://github.com/KDAB/android_openssl.git
  OPENSSL_PRI=$$(ANDROID_SDK_ROOT)/android_openssl/openssl.pri
  !exists($$OPENSSL_PRI):error("$$OPENSSL_PRI is missing - please clone KDAB's android_openssl into $$(ANDROID_SDK_ROOT)")
  include($$OPENSSL_PRI)

  HEADERS += \
      src/openurlclient.h \

  SOURCES += \
      src/openurlclient.cpp \

  package.depends = apk
  package.commands = cp $$OUT_PWD/android-build/build/outputs/apk/debug/android-build-debug.apk $$OUT_PWD/$${TARGET}-$${VERSION}.apk
  QMAKE_EXTRA_TARGETS += package

}


#
# Windows specific
#

win32 {
  RC_ICONS = icons/haiq.ico

  # qmake uses these to generate a FILEVERSION record
  QMAKE_TARGET_COPYRIGHT   = "Copyright (c) $$COPYRIGHT"
  QMAKE_TARGET_COMPANY     = "https://$$GITHUB_URL"
  QMAKE_TARGET_DESCRIPTION = "$$DESCRIPTION"

  build_pass:CONFIG(release, debug|release) {
    ISCC="iscc.exe"
    !system(where /Q $$ISCC) {
      INNO_PATH=$$(INNO_SETUP_PATH)
      !exists("$$INNO_PATH\\$$ISCC") {
        INNO_PATH="$$getenv(ProgramFiles(x86))\\Inno Setup 6"
        !exists("$$INNO_PATH\\$$ISCC"):error("Please set %INNO_SETUP_PATH% to point to the directory containing the '$$ISCC' binary.")
      }
      ISCC="$$INNO_PATH\\$$ISCC"
    }

    deploy.depends += $(DESTDIR_TARGET)
    deploy.commands += $$shell_path($$[QT_HOST_BINS]/windeployqt.exe) --qmldir $$SOURCE_DIR/qml --no-virtualkeyboard --no-translations --no-webchannel --no-webenginecore --no-webengine --no-serialport --no-positioning $(DESTDIR_TARGET)

    installer.depends += deploy
    installer.commands += $$shell_quote($$shell_path($$ISCC)) \
                            /DSOURCE_DIR=$$shell_quote($$shell_path($$OUT_PWD/$$DESTDIR)) \
                            /O$$shell_quote($$shell_path($$OUT_PWD)) \
                            /F$$shell_quote($${TARGET}-$${VERSION}) \
                            $$shell_quote($$shell_path($$PWD/utils/haiq.iss))
  } else {
    deploy.CONFIG += recursive
    installer.CONFIG += recursive
  }

  QMAKE_EXTRA_TARGETS += deploy installer
}

#
# Mac OS X specific
#

macos {
  QMAKE_FULL_VERSION = $$VERSION
  QMAKE_INFO_PLIST = macos/Info.plist
  bundle_icons.path = Contents/Resources
  bundle_icons.files = $$files("macos/*.icns")
  bundle_locversions.path = Contents/Resources
  for(l, LANGUAGES) {
    outpath = $$OUT_PWD/.locversions/$${l}.lproj
    mkpath($$outpath)
    system(sed -e "s,@LANG@,$$l," < "$$PWD/macos/locversion.plist.in" > "$$outpath/locversion.plist")
    bundle_locversions.files += $$outpath
  }

  QMAKE_BUNDLE_DATA += bundle_icons bundle_locversions

  CONFIG(release, debug|release) {
    deploy.depends += $(DESTDIR_TARGET)
    deploy.commands += ( cd $$shell_path($$[QT_HOST_BINS]) && ./macdeployqt $$OUT_PWD/$$DESTDIR/$${TARGET}.app -qmldir=$$PWD/qml)

    installer.depends += deploy
    installer.commands += rm -rf $$OUT_PWD/dmg
    installer.commands += && mkdir $$OUT_PWD/dmg
    installer.commands += && cp -a $$OUT_PWD/$$DESTDIR/$${TARGET}.app $$OUT_PWD/dmg/
    installer.commands += && ln -s /Applications "$$OUT_PWD/dmg/"
    installer.commands += && hdiutil create \"$$OUT_PWD/$${TARGET}-$${VERSION}.dmg\" -volname \"$$TARGET $$VERSION\" -fs \"HFS+\" -srcdir \"$$OUT_PWD/dmg\" -quiet -format UDBZ -ov
  } else {
    deploy.CONFIG += recursive
    installer.CONFIG += recursive
  }

  QMAKE_EXTRA_TARGETS += deploy installer
}

#
# Linux specific
#

linux:!android {
  isEmpty(PREFIX):PREFIX = /usr/local
  DEFINES += INSTALL_PREFIX=\"$$PREFIX\"
  target.path = $$PREFIX/bin
  INSTALLS += target

  systemd_service.path  = /etc/systemd/system/
  systemd_service.files = utils/haiq.service

  INSTALLS += systemd_service

  package.depends = $(TARGET)
  package.commands = utils/create-debian-changelog.sh $$VERSION > debian/changelog
  package.commands += && export QMAKE_BIN=\"$$QMAKE_QMAKE\"
  package.commands += && dpkg-buildpackage --build=binary --check-builddeps --jobs=auto --root-command=fakeroot \
                                           --unsigned-source --unsigned-changes --compression=xz \
                                           --no-pre-clean
  package.commands += && mv ../haiq*.deb .

  QMAKE_EXTRA_TARGETS += package
}
