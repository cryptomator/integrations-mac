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
    if (@available(macOS 13, *)) {
        return [[SMAppService mainAppService] status] == SMAppServiceStatusEnabled ? YES : NO;
    } else { // macOS < 13
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
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_enableLoginItem(JNIEnv *env, jobject thisObj) {
    if (@available(macOS 13, *)) {
        NSError* error = nil;
        if (![[SMAppService mainAppService] registerAndReturnError: & error]) {
            NSLog(@"Failed to add login item: %@", error.localizedDescription);
            return NO;
        } else {
            return YES;
        }
    } else { // macOS < 13
        LSSharedFileListRef sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        NSString *applicationPath = NSBundle.mainBundle.bundlePath;
        NSURL *applicationPathURL = [NSURL fileURLWithPath:applicationPath];
        if (sharedFileList) {
        	LSSharedFileListItemRef sharedFileListItem = LSSharedFileListInsertItemURL(sharedFileList, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)applicationPathURL, NULL, NULL);
        	if (sharedFileListItem) {
        		CFRelease(sharedFileListItem);
        	}
        	CFRelease(sharedFileList);
        	return YES;
        } else {
        	NSLog(@"Unable to create the shared file list.");
        	return NO;
        }
    }
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_autostart_MacLaunchServices_00024Native_disableLoginItem(JNIEnv *env, jobject thisObj) {
    if (@available(macOS 13, *)) {
        NSError* error = nil;
        if (![[SMAppService mainAppService] unregisterAndReturnError: & error]) {
            NSLog(@"Failed to remove login item: %@", error.localizedDescription);
            return NO;
        } else {
            return YES;
        }
    } else { // macOS < 13
        LSSharedFileListRef sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        NSString *applicationPath = NSBundle.mainBundle.bundlePath;
       	if (sharedFileList) {
       		UInt32 seedValue;
       		NSArray *sharedFileListArray = CFBridgingRelease(LSSharedFileListCopySnapshot(sharedFileList, &seedValue));
       		for (id sharedFile in sharedFileListArray) {
       			LSSharedFileListItemRef sharedFileListItem = (__bridge LSSharedFileListItemRef)sharedFile;
       			CFURLRef applicationPathURL;
       			if (LSSharedFileListItemResolve(sharedFileListItem, 0, &applicationPathURL, NULL) == noErr) {
       				NSString *resolvedApplicationPath = [(__bridge NSURL *)applicationPathURL path];
       				if ([resolvedApplicationPath compare:applicationPath] == NSOrderedSame) {
       					LSSharedFileListItemRemove(sharedFileList, sharedFileListItem);
       				}
       				CFRelease(applicationPathURL);
       			}
       		}
       		CFRelease(sharedFileList);
       		return YES;
       	} else {
       		NSLog(@"Unable to create the shared file list.");
       		return NO;
       	}
    }
}
