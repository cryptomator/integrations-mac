//
//  org_cryptomator_macos_tray_DockTileIcon_Native.m
//  Integrations
//
//  Created by Tobias Hagemann on 19.09.25.
//  Copyright © 2025 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_tray_DockTileIcon_Native.h"
#import "SKYDockTileIcon.h"

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_tray_DockTileIcon_00024Native_applyIcon(JNIEnv *env, jobject thisObj, jstring resourceName, jstring resourceType) {
	NSString *resourceNameString = nil;
	if (resourceName != NULL) {
		const char *resourceNameUtf = (*env)->GetStringUTFChars(env, resourceName, NULL);
		if (resourceNameUtf != NULL) {
			resourceNameString = [NSString stringWithUTF8String:resourceNameUtf];
			(*env)->ReleaseStringUTFChars(env, resourceName, resourceNameUtf);
		}
	}
	NSString *resourceTypeString = nil;
	if (resourceType != NULL) {
		const char *resourceTypeUtf = (*env)->GetStringUTFChars(env, resourceType, NULL);
		if (resourceTypeUtf != NULL) {
			resourceTypeString = [NSString stringWithUTF8String:resourceTypeUtf];
			(*env)->ReleaseStringUTFChars(env, resourceType, resourceTypeUtf);
		}
	}
	return [SKYDockTileIcon applyDockTileIconNamed:resourceNameString ofType:resourceTypeString];
}
