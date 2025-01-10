//
//  org_cryptomator_macos_keychain_MacKeychain_Native.m
//  Integrations
//
//  Created by Sebastian Stenzel on 29.08.16.
//  Copyright © 2016 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_keychain_MacKeychain_Native.h"
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <LocalAuthentication/LocalAuthentication.h>

static LAContext *sharedContext = nil;
static LAContext* getSharedLAContext(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedContext = [[LAContext alloc] init];
	});
	return sharedContext;
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_storePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key, jbyteArray password, jboolean requireOsAuthentication) {
	jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);
	jbyte *pwStr = (*env)->GetByteArrayElements(env, password, NULL);
	jsize length = (*env)->GetArrayLength(env, password);

	// find existing:
	NSMutableDictionary *query = [@{
		(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
		(__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
		(__bridge id)kSecReturnAttributes: @YES,
		(__bridge id)kSecReturnData: @YES,
		(__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
	} mutableCopy];
	if (requireOsAuthentication) {
		LAContext *context = getSharedLAContext();
		query[(__bridge id)kSecUseAuthenticationContext] = context;
	}
	CFDictionaryRef result = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
	if (status == errSecSuccess && result != NULL) {
		// update existing:
		NSDictionary *attributesToUpdate = @{
			(__bridge id)kSecValueData: [NSData dataWithBytes:pwStr length:length]
		};
		status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
	} else if (status == errSecItemNotFound) {
		// add new:
		NSMutableDictionary *attributes = [@{
			(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
			(__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
			(__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
			(__bridge id)kSecValueData: [NSData dataWithBytes:pwStr length:length]
		} mutableCopy];
		if (requireOsAuthentication) {
			attributes[(__bridge id)kSecAttrAccessControl] = (__bridge_transfer id)SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, kSecAccessControlUserPresence, NULL);
		}
		status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
	} else {
		NSLog(@"Error storing item in keychain. Status code: %d", (int)status);
	}

	(*env)->ReleaseByteArrayElements(env, service, serviceStr, JNI_ABORT);
	(*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);
	(*env)->ReleaseByteArrayElements(env, password, pwStr, JNI_ABORT);
	return status;
}

JNIEXPORT jbyteArray JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_loadPassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
	jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);

	// find existing:
	LAContext *context = getSharedLAContext();
	NSDictionary *query = @{
		(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
		(__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
		(__bridge id)kSecReturnAttributes: @YES,
		(__bridge id)kSecReturnData: @YES,
		(__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
		(__bridge id)kSecUseAuthenticationContext: context
	};
	CFDictionaryRef result = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
	jbyteArray password = NULL;
	if (status == errSecSuccess && result != NULL) {
		// retrieve password:
		NSDictionary *attributes = (__bridge_transfer NSDictionary *)result;
		NSData *passwordData = attributes[(__bridge id)kSecValueData];
		password = (*env)->NewByteArray(env, (int)passwordData.length);
		(*env)->SetByteArrayRegion(env, password, 0, (int)passwordData.length, (jbyte *)passwordData.bytes);
	} else if (status != errSecItemNotFound) {
		NSLog(@"Error retrieving item from keychain. Status code: %d", (int)status);
	}

	(*env)->ReleaseByteArrayElements(env, service, serviceStr, JNI_ABORT);
	(*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);
	return password;
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_deletePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
	jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);

	// find existing:
	LAContext *context = getSharedLAContext();
	NSDictionary *query = @{
		(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
		(__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
		(__bridge id)kSecUseAuthenticationContext: context
	};
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
	if (status != errSecSuccess) {
		NSLog(@"Error deleting item from keychain. Status code: %d", (int)status);
	}

	(*env)->ReleaseByteArrayElements(env, service, serviceStr, JNI_ABORT);
	(*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);
	return status;
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_isTouchIDavailable(JNIEnv *env, jobject thisObj) {
	NSError *error = nil;
	LAContext *context = getSharedLAContext();
	if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
		return JNI_TRUE;
	} else {
		NSLog(@"Touch ID is not available: %@", error.localizedDescription);
		return JNI_FALSE;
	}
}
