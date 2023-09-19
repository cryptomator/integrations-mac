//
//  org_cryptomator_macos_tray_ActivationPolicy_Native.m
//  Integrations
//
//  Created by Sebastian Stenzel on 06.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_tray_ActivationPolicy_Native.h"
#import <AppKit/AppKit.h>

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_ActivationPolicy_00024Native_transformToAccessory
(JNIEnv *env, jobject thisObj) {
	if (NSApp.activationPolicy != NSApplicationActivationPolicyAccessory) {
		[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
	}
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_ActivationPolicy_00024Native_transformToRegular
(JNIEnv *env, jobject thisObj) {
	if (NSApp.activationPolicy != NSApplicationActivationPolicyRegular) {
		[NSApp activateIgnoringOtherApps:YES];
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	}
}
