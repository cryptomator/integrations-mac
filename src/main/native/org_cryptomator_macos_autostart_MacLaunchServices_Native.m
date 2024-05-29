//
//  org_cryptomator_macos_autostart_MacLaunchServices_Native.m
//  Integrations
//
//  Created by Tobias Hagemann on 16.12.19.
//  Copyright © 2019 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_autostart_MacLaunchServices_Native.h"
#import "SKYLaunchService.h"

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_isLoginItemEnabled(JNIEnv *env, jobject thisObj) {
	return [SKYLaunchService isLoginItemEnabled];
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_enableLoginItem(JNIEnv *env, jobject thisObj) {
	return [SKYLaunchService enableLoginItem];
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_disableLoginItem(JNIEnv *env, jobject thisObj) {
	return [SKYLaunchService disableLoginItem];
}
