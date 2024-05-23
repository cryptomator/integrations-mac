//
//  org_cryptomator_macos_autostart_MacLaunchServices_Native.m
//  Integrations
//
//  Created by Tobias Hagemann on 16.12.19.
//  Copyright © 2019 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_autostart_MacLaunchServices_Native.h"
#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_isLoginItemEnabled(JNIEnv *env, jobject thisObj) {
	LSSharedFileListRef sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	NSString *applicationPath = NSBundle.mainBundle.bundlePath;
	if (sharedFileList) {
		UInt32 seedValue;
		NSArray *sharedFileListArray = CFBridgingRelease(LSSharedFileListCopySnapshot(sharedFileList, &seedValue));
		for (id sharedFile in sharedFileListArray) {
			LSSharedFileListItemRef sharedFileListItem = (__bridge LSSharedFileListItemRef)sharedFile;
			CFURLRef applicationPathURL = NULL;
			LSSharedFileListItemResolve(sharedFileListItem, 0, (CFURLRef *)&applicationPathURL, NULL);
			if (applicationPathURL != NULL) {
				NSString *resolvedApplicationPath = [(__bridge NSURL *)applicationPathURL path];
				CFRelease(applicationPathURL);
				if ([resolvedApplicationPath compare:applicationPath] == NSOrderedSame) {
					CFRelease(sharedFileList);
					return YES;
				}
			}
		}
		CFRelease(sharedFileList);
	} else {
		NSLog(@"Unable to create the shared file list.");
	}
	return NO;
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_enableLoginItem(JNIEnv *env, jobject thisObj) {
	NSString *applicationPath = NSBundle.mainBundle.bundlePath;
	BOOL *success = SMLoginItemSetEnabled((__bridge CFStringRef)applicationPath, YES);
	if (success) {
		return YES;
	} else {
		NSLog(@"Unable to enable login item.");
		return NO;
	}
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_disableLoginItem(JNIEnv *env, jobject thisObj) {
	NSString *applicationPath = NSBundle.mainBundle.bundlePath;
	BOOL *success = SMLoginItemSetEnabled((__bridge CFStringRef)applicationPath, NO);
	if (success) {
		return YES;
	} else {
		NSLog(@"Unable to disable login item.");
		return NO;
	}
}
