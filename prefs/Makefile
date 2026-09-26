ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
  ARCHS ?= arm64 arm64e
  TARGET ?= iphone:clang:latest:15.0
else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
  ARCHS ?= arm64 arm64e
  TARGET ?= iphone:clang:latest:15.0
else
  ARCHS ?= arm64 arm64e
  TARGET ?= iphone:clang:latest:13.0
endif

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = QuickPassPrefs

QuickPassPrefs_FILES = QPRootListController.m ../shared/QPPrefs.m ../shared/QPLocalize.m
QuickPassPrefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore
QuickPassPrefs_PRIVATE_FRAMEWORKS = Preferences
QuickPassPrefs_LDFLAGS = -F$(THEOS_PROJECT_DIR)/stubs
QuickPassPrefs_INSTALL_PATH = /Library/PreferenceBundles
QuickPassPrefs_CFLAGS = -fobjc-arc -I../include -I../shared -Wno-deprecated-declarations -Wno-unused-variable
QuickPassPrefs_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/bundle.mk
