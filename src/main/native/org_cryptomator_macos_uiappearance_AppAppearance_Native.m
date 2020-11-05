//
//  org_cryptomator_macos_uiappearance_AppAppearance_Native.m
//  Integrations
//
//  Created by Sebastian Stenzel on 05.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_uiappearance_AppAppearance_Native.h"
#import <AppKit/AppKit.h>

JNIEXPORT void JNICALL Java_org_cryptomator_macos_uiappearance_AppAppearance_00024Native_setToAqua(JNIEnv *env, jobject thisObj) {
    if (@available(macOS 10.14, *)) {
        NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_uiappearance_AppAppearance_00024Native_setToDarkAqua(JNIEnv *env, jobject thisObj) {
    if (@available(macOS 10.14, *)) {
        NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    }
}
