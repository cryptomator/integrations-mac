//
//  SKYLaunchService.m
//  Integrations
//
//  Created by Tobias Hagemann on 26.05.24.
//  Copyright © 2024 Cryptomator. All rights reserved.
//

#import "SKYLaunchService.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation SKYLaunchService

+ (BOOL)isLoginItemEnabled {
	if (@available(macOS 13, *)) {
		if (SMAppService.mainAppService.status == SMAppServiceStatusEnabled) {
			return YES;
		} else if ([self isLegacyLoginItemEnabled]) {
			// migrate legacy login item
			[self disableLegacyLoginItem];
			return [self enableLoginItem];
		} else {
			return NO;
		}
	} else { // macOS < 13
		return [self isLegacyLoginItemEnabled];
	}
}

+ (BOOL)enableLoginItem {
	if (@available(macOS 13, *)) {
		NSError *error;
		if ([SMAppService.mainAppService registerAndReturnError:&error]) {
			return YES;
		} else {
			NSLog(@"Failed to register login item: %@", error.localizedDescription);
			return NO;
		}
	} else { // macOS < 13
		return [self enableLegacyLoginItem];
	}
}

+ (BOOL)disableLoginItem {
	if (@available(macOS 13, *)) {
		NSError *error;
		if ([SMAppService.mainAppService unregisterAndReturnError:&error]) {
			return YES;
		} else {
			NSLog(@"Failed to unregister login item: %@", error.localizedDescription);
			return NO;
		}
	} else { // macOS < 13
		return [self disableLegacyLoginItem];
	}
}

#pragma mark - Legacy

+ (BOOL)isLegacyLoginItemEnabled {
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

+ (BOOL)enableLegacyLoginItem {
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

+ (BOOL)disableLegacyLoginItem {
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

@end
