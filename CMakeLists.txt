# Copyright (C) 2017-2024 Robert Griebl
# SPDX-License-Identifier: GPL-3.0-only

cmake_minimum_required(VERSION 3.19.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_INCLUDE_CURRENT_DIR OFF)
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# for QtCreator
set(QML_IMPORT_PATH ${CMAKE_SOURCE_DIR}/src ${CMAKE_BINARY_DIR}/imports CACHE STRING "" FORCE)

option(FORCE_MOBILE "Force a mobile build on desktop" OFF)
option(SANITIZE     "Build with ASAN" OFF)
option(MODELTEST    "Build with modeltest" OFF)

set(NAME           "HAiQ")
set(DESCRIPTION    "${NAME} - QML based UIs for Home-Assistant")
set(COPYRIGHT      "2017-2024 Robert Griebl")
set(GITHUB_URL     "github.com/rgriebl/haiq")
set(BUILD_NUMBER   "$ENV{BUILD_NUMBER}")
if (NOT BUILD_NUMBER)
    set(BUILD_NUMBER   "custom")
endif()

file(STRINGS "VERSION_NUMBER" VERSION)
string(REPLACE "." ";" VERSION_LIST ${VERSION})
list(GET VERSION_LIST 0 VERSION_MAJOR)
list(GET VERSION_LIST 1 VERSION_MINOR)
list(GET VERSION_LIST 2 VERSION_PATCH)

project(HAiQ
    VERSION ${VERSION}
    DESCRIPTION ${DESCRIPTION}
    HOMEPAGE_URL "https://${GITHUB_URL}"
    LANGUAGES CXX C
)
find_package(Qt6 CONFIG QUIET COMPONENTS Core REQUIRED)
include(QtPlatformSupport) # load all the platform names

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

if (NOT (ANDROID OR APPLE))
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY bin)
endif()

qt_add_executable(${PROJECT_NAME} WIN32 MACOSX_BUNDLE)

if (NOT IOS) # somehow this tries to access the wrong build dir on iOS
    include(SeparateDebugInfo)
    enable_separate_debug_info(${PROJECT_NAME})
endif()

# Use LTO, if available
include(CheckIPOSupported)
check_ipo_supported(RESULT HAS_LTO OUTPUT LTO_STATUS)
if (HAS_LTO)
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(LTO_STATUS OFF)
    else()
        set_property(TARGET ${PROJECT_NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
        set(LTO_STATUS ON)
    endif()
endif()

add_compile_definitions(
    QT_STRICT_ITERATORS
    QT_STRICT_QLIST_ITERATORS
    QT_NO_CAST_TO_ASCII
    QT_NO_CAST_FROM_ASCII
    QT_MESSAGELOGCONTEXT
    QT_USE_QSTRINGBUILDER
)

find_package(Qt6 CONFIG QUIET
    REQUIRED Core Gui Xml Network Qml Quick Svg QuickControls2 WebSockets
)

if (${Qt6_VERSION} VERSION_GREATER_EQUAL "6.8.0")
    add_compile_definitions(
        "QT_WARN_DEPRECATED_UP_TO=QT_VERSION_CHECK(6,7,0)"
    )
endif()

set(MIN_QT_VERSION 6.6.3)

if (ANDROID OR IOS OR FORCE_MOBILE)
    set(HAIQ_MOBILE ON)
    set(HAIQ_TYPE "Mobile")
    add_compile_definitions(HAIQ_MOBILE)
    set(QUICK_CONTROLS "QtQuick.Controls.Universal")

else()
    set(HAIQ_DESKTOP ON)
    set(HAIQ_TYPE "Desktop")
    add_compile_definitions(HAIQ_DESKTOP)
    find_package(Qt6 CONFIG QUIET REQUIRED Widgets)
    set(QUICK_CONTROLS "QtQuick.Controls.Fusion")

endif()

if (${Qt6_VERSION} VERSION_LESS "${MIN_QT_VERSION}")
    message(FATAL_ERROR "Qt ${MIN_QT_VERSION} or newer is required for building this variant")
endif()

if (MODELTEST)
    find_package(Qt6 REQUIRED Test)
    add_compile_definitions(MODELTEST)
endif()

if (NOT APPLE AND NOT WIN32 AND NOT ANDROID)
    set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "haiq")
endif()

if (CLANG OR GCC)
    # cmake's RelWithDebInfo is hardcoded to O2, while Release has O3
    string(REGEX REPLACE "([\\/\\-]O)2" "\\13" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
endif()

if (SANITIZE)
    add_compile_definitions(SANITIZER_ENABLED)
    if (MSVC)
        set(ECM_ENABLE_SANITIZERS address)
    else()
        set(ECM_ENABLE_SANITIZERS address undefined)
    endif()
    include(${Qt6_DIR}/3rdparty/extra-cmake-modules/modules/ECMEnableSanitizers.cmake)
endif()

file(GLOB_RECURSE ICONS_QRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} icons/*)
file(GLOB_RECURSE SOUNDS_QRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} sounds/*)

qt_add_resources(${PROJECT_NAME} icons PREFIX / FILES ${ICONS_QRC})
qt_add_resources(${PROJECT_NAME} sounds PREFIX / FILES ${SOUNDS_QRC})

add_subdirectory(src)

if (WIN32)
    # Windows resources: icons and file-version record
    configure_file(windows/haiq.rc.in generated/haiq.rc @ONLY)
    target_sources(${PROJECT_NAME} PUBLIC generated/haiq.rc)

    # always link against widgets
    find_package(Qt6 REQUIRED Widgets)
    target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Widgets)

    target_link_libraries(${PROJECT_NAME} PRIVATE user32 advapi32 wininet)
endif()

if (APPLE)
    set(EXECUTABLE ${PROJECT_NAME})
    if (CMAKE_OSX_DEPLOYMENT_TARGET)
        set(MACOSX_DEPLOYMENT_TARGET ${CMAKE_OSX_DEPLOYMENT_TARGET})
    endif()
    find_library(SECURITY_LIB Security)
    target_link_libraries(${PROJECT_NAME} PRIVATE ${SECURITY_LIB})
    if (LTO_STATUS)
        set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-Wl,-object_path_lto -Wl,lto.o")
    endif()
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/macos/Info.plist"
        MACOSX_BUNDLE_GUI_IDENTIFIER "org.griebl.haiq"
    )
    set(MACOS_RESOURCES
        macos/haiq.icns
        #macos/macos.entitlements
    )
    target_sources(${PROJECT_NAME} PUBLIC ${MACOS_RESOURCES})
    set_source_files_properties(${MACOS_RESOURCES} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
endif()

if (ANDROID)
    if (BUILD_NUMBER STREQUAL "custom")
        set(VERSION_CODE "0")
    else()
        set(VERSION_CODE "${BUILD_NUMBER}")
    endif()
    set_target_properties(${PROJECT_NAME} PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android"
        QT_ANDROID_VERSION_CODE ${VERSION_CODE}
        QT_ANDROID_VERSION_NAME ${VERSION}
    )

    if (QT_ANDROID_SDK_BUILD_TOOLS_REVISION) # this has to be set as a target property to stick
        set_target_properties(${PROJECT_NAME} PROPERTIES
            QT_ANDROID_SDK_BUILD_TOOLS_REVISION "${QT_ANDROID_SDK_BUILD_TOOLS_REVISION}"
        )
    endif()

    if (QT_ANDROID_TARGET_SDK_VERSION) # this has to be set as a target property to stick
        set_target_properties(${PROJECT_NAME} PROPERTIES
            QT_ANDROID_TARGET_SDK_VERSION "${QT_ANDROID_TARGET_SDK_VERSION}"
        )
    endif()

    include(FetchContent)

    FetchContent_Declare(
        android_openssl
        GIT_REPOSITORY https://github.com/KDAB/android_openssl.git
        GIT_TAG master
        GIT_SHALLOW YES
    )
    FetchContent_MakeAvailable(android_openssl)
    FetchContent_GetProperties(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(${PROJECT_NAME})

    # Mixing pre-NDK23 objects (e.g. Qt) and (post-)NDK23 objects will crash when unwinding:
    # https://android.googlesource.com/platform/ndk/+/master/docs/BuildSystemMaintainers.md#Unwinding
    if (ANDROID_NDK_MAJOR GREATER 22)
        target_link_libraries(${PROJECT_NAME} PRIVATE -lunwind)
    endif()
endif()

add_custom_target("Other-Files" SOURCES
    .gitignore
    .github/workflows/build_qmake.yml
    CHANGELOG.md
    LICENSE.GPL
    README.md
    VERSION_NUMBER
    example-config.json
    android/AndroidManifest.xml
    android/build.gradle
    android/gradle.properties
    android/gradle/wrapper/gradle-wrapper.jar
    android/gradle/wrapper/gradle-wrapper.properties
    android/gradlew
    android/gradlew.bat
    android/res/values/libs.xml
    android/src/org/griebl/haiq/OpenUrlClient.java
    cmake/SeparateDebugInfo.cmake
    cmake/SeparateDebugInfo.Info.plist.in
    macos/dmg-background.png
    macos/dmg-ds_store
    macos/Info.plist
    macos/locversion.plist.in
    macos/haiq.icns
    scripts/git-release.sh
    unix/org.griebl.HAiQ.desktop
    unix/org.griebl.HAiQ.metainfo.xml.in
    unix/flatpak.yaml.in
    unix/snapcraft.yaml.in
    windows/haiq.iss
    windows/haiq.rc.in
    windows/haiq.ico
)

## Installers, Bundles, etc.

if (MACOS)
    install(TARGETS ${PROJECT_NAME} BUNDLE DESTINATION .)

    set(DMG_DIR "${CMAKE_BINARY_DIR}/dmg")
    set(DMG_FILE "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${VERSION}.dmg")

    set(MACOS_SIGN_ARGS "")
    if (MACOS_SIGNING_IDENTITY)
        set(MACOS_SIGN_ARGS "-sign-for-notarization=${MACOS_SIGNING_IDENTITY}")
    endif()

    # We cannot use CPack here: macdeployqt signs all binaries, but the installation step when
    # running CPack's DragNDrop generator would try to mess with the rpaths and in turn nullify
    # the code signatures.
    # Also: macdeployqt has to be run on the bundle in the build location. If we copy to the dmg
    # staging directory first, we get weird errors because the tool thinks that all Qt frameworks
    # are "outside of the bundle"

    add_custom_command(
        OUTPUT ${DMG_FILE}
        COMMENT "Creating macOS DMG. Please wait..."
        DEPENDS ${PROJECT_NAME}
        COMMAND "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}/macdeployqt" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../.."
                "-qmldir=${CMAKE_CURRENT_SOURCE_DIR}"
                "-verbose=2"
                ${MACOS_SIGN_ARGS}
        COMMAND rm -rf "${DMG_DIR}"
        COMMAND mkdir -p "${DMG_DIR}/.background"
        COMMAND cp "${CMAKE_SOURCE_DIR}/macos/dmg-ds_store" "${DMG_DIR}/.DS_Store"
        COMMAND cp "${CMAKE_SOURCE_DIR}/macos/dmg-background.png" "${DMG_DIR}/.background/background.png"
        COMMAND ln -s /Applications "${DMG_DIR}"
        COMMAND cp -a "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>" "${DMG_DIR}"
        COMMAND "${CMAKE_SOURCE_DIR}/macos/retry.sh" 5 hdiutil create ${DMG_FILE}
                               -volname "${PROJECT_NAME}-${VERSION}" -fs "HFS+" -format ULFO -ov
                               -srcdir ${DMG_DIR}
    )
    add_custom_target(dmg DEPENDS ${DMG_FILE})

elseif (WIN32)
    set(INNO_ARCH ${CMAKE_SYSTEM_PROCESSOR})
    if (INNO_ARCH STREQUAL "AMD64")
        set(INNO_ARCH "x64")
    endif()

    if (QT_HOST_PATH)
        set(WINDEPLOYQT_PATH "${QT_HOST_PATH}/${QT6_HOST_INFO_BINDIR}")
        set(WINDEPLOYQT_EXTRA_ARGS "--qtpaths=${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}/qtpaths.bat")
    else()
        set(WINDEPLOYQT_PATH "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}")
    endif()

    if (${Qt6_VERSION} VERSION_LESS "6.5.0")
        list(APPEND WINDEPLOYQT_EXTRA_ARGS --no-qmltooling)
    elseif (${Qt6_VERSION} VERSION_GREATER "6.5.0")
        list(APPEND WINDEPLOYQT_EXTRA_ARGS --skip-plugin-types qmltooling)
    endif ()

    # deploy Qt dependencies and create an INNO setup installer
    add_custom_target(installer
        COMMAND "${WINDEPLOYQT_PATH}/windeployqt" $<TARGET_FILE:${PROJECT_NAME}>
                ${WINDEPLOYQT_EXTRA_ARGS}
                "--qmldir=${CMAKE_CURRENT_SOURCE_DIR}"
                "--no-opengl-sw"
                "--no-translations"
                "--verbose" "2"
        COMMAND "iscc.exe" "/DSOURCE_DIR=${CMAKE_CURRENT_BINARY_DIR}/bin" "/DARCH=${INNO_ARCH}"
                "/O${CMAKE_CURRENT_BINARY_DIR}"
                "/F${PROJECT_NAME}-${VERSION}" "${CMAKE_SOURCE_DIR}/windows/haiq.iss"
        COMMENT "Creating INNO Setup installer. Please wait..."
        DEPENDS ${PROJECT_NAME}
    )

elseif (ANDROID)
    # we cannot set the apk name directly, so we have to rename it after creation
    add_custom_target(final-apk
        COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_BINARY_DIR}/android-build/${PROJECT_NAME}.apk"
                                           "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${VERSION}.apk"
        COMMENT "Moving apk to final name and location..."
        DEPENDS apk
    )

    string(TOLOWER "${CMAKE_BUILD_TYPE}" lower_build_type)

    add_custom_target(final-aab
        COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_BINARY_DIR}/android-build/build/outputs/bundle/${lower_build_type}/android-build-release.aab"
                                           "${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${VERSION}.aab"
        COMMENT "Moving aab to final name and location..."
        DEPENDS aab
    )

elseif (LINUX)
    install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
    install(FILES unix/org.griebl.HAiQ.desktop DESTINATION share/applications)
    install(FILES icons/haiq.png DESTINATION share/icons/hicolor/256x256/apps RENAME org.griebl.HAiQ.png)

#    string(TIMESTAMP APPSTREAM_RELEASE_DATE "%Y-%m-%d")
#    configure_file(unix/org.griebl.HAiQ.metainfo.xml.in unix/org.griebl.HAiQ.metainfo.xml @ONLY)
#    install(FILES ${CMAKE_BINARY_DIR}/unix/org.griebl.HAiQ.metainfo.xml DESTINATION share/metainfo)

#    set(SNAP_DIR "${CMAKE_BINARY_DIR}/snap")
#    file(COPY "${CMAKE_SOURCE_DIR}/icons/haiq.png" DESTINATION "${SNAP_DIR}/gui/")
#    configure_file(unix/snapcraft.yaml.in "${SNAP_DIR}/snapcraft.yaml" @ONLY)
#    configure_file(unix/flatpak.yaml.in flatpak.yaml @ONLY)
endif()

# we don't want the standard 'package' target
set(CPACK_OUTPUT_CONFIG_FILE "${CMAKE_BINARY_DIR}/BundleConfig.cmake" )
include(CPack)

message(STATUS "")
message(STATUS "Configure Summary:")
message(STATUS "  Version ........ ${VERSION}")
message(STATUS "  Build number ... ${BUILD_NUMBER}")
message(STATUS "  Build type ..... ${CMAKE_BUILD_TYPE}")
message(STATUS "  Qt version ..... ${Qt6_VERSION}")
message(STATUS "  Qt location .... ${Qt6_DIR}")
message(STATUS "  Build type ..... ${HAIQ_TYPE}")
message(STATUS "  Link-time opt. . ${LTO_STATUS}")
message(STATUS "  ASAN ........... ${SANITIZE}")
message(STATUS "  Qt Modeltest ... ${MODELTEST}")
message(STATUS "")
