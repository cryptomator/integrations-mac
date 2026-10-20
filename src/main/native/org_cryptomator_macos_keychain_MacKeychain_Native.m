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

// returns nil without further JNI calls, if a previous call left an exception pending
static NSString* stringFromByteArray(JNIEnv *env, jbyteArray array) {
	if ((*env)->ExceptionCheck(env)) {
		return nil;
	}
	jbyte *bytes = (*env)->GetByteArrayElements(env, array, NULL);
	if (bytes == NULL) {
		return nil;
	}
	NSString *string = [[NSString alloc] initWithBytes:bytes length:(*env)->GetArrayLength(env, array) encoding:NSUTF8StringEncoding];
	(*env)->ReleaseByteArrayElements(env, array, bytes, JNI_ABORT);
	return string;
}

// Items requiring user presence live in the data protection keychain, all others in the file-based keychain. Loading targets one of them explicitly,
// because a query spanning both reports a failed authentication in the data protection keychain as errSecItemNotFound.
static NSDictionary* itemQuery(NSString *service, NSString *account, BOOL dataProtectionKeychain) {
	return @{
		(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService: service,
		(__bridge id)kSecAttrAccount: account,
		(__bridge id)kSecUseDataProtectionKeychain: @(dataProtectionKeychain)
	};
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_storePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key, jbyteArray password, jboolean requireOsAuthentication) {
	NSString *serviceString = stringFromByteArray(env, service);
	NSString *keyString = stringFromByteArray(env, key);
	jbyte *pwStr = (*env)->ExceptionCheck(env) ? NULL : (*env)->GetByteArrayElements(env, password, NULL);

	OSStatus status = errSecParam;

	if (serviceString && keyString && pwStr) {
		jsize length = (*env)->GetArrayLength(env, password);
		// find existing:
		NSMutableDictionary *query = [@{
			(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
			(__bridge id)kSecAttrService: serviceString,
			(__bridge id)kSecAttrAccount: keyString,
			(__bridge id)kSecReturnAttributes: @YES,
			(__bridge id)kSecReturnData: @YES,
			(__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
		} mutableCopy];
		if (requireOsAuthentication) {
			LAContext *context = getSharedLAContext();
			query[(__bridge id)kSecUseAuthenticationContext] = context;
		}
		CFDictionaryRef result = NULL;
		status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
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
				(__bridge id)kSecAttrService: serviceString,
				(__bridge id)kSecAttrAccount: keyString,
				(__bridge id)kSecValueData: [NSData dataWithBytes:pwStr length:length]
			} mutableCopy];
			if (requireOsAuthentication) {
				attributes[(__bridge id)kSecAttrAccessControl] = (__bridge_transfer id)SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, kSecAccessControlUserPresence, NULL);
			}
			status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
		} else {
			NSLog(@"Error storing item in keychain. Status code: %d", (int)status);
		}
	} else {
		NSLog(@"Invalid input: service or key string conversion failed or password unavailable");
	}

	if (pwStr) {
		(*env)->ReleaseByteArrayElements(env, password, pwStr, JNI_ABORT);
	}
	return status;
}

JNIEXPORT jobject JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_loadPassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
	NSString *serviceString = stringFromByteArray(env, service);
	NSString *keyString = stringFromByteArray(env, key);

	OSStatus status = errSecParam;
	NSData *passwordData = nil;

	if (serviceString && keyString) { // guard both NSStrings not to be NIL
		// find existing, preferring the protected item:
		NSMutableDictionary *query = [itemQuery(serviceString, keyString, YES) mutableCopy];
		query[(__bridge id)kSecReturnData] = @YES;
		query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
		query[(__bridge id)kSecUseAuthenticationContext] = getSharedLAContext();
		CFTypeRef result = NULL;
		status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
		if (status == errSecItemNotFound || status == errSecMissingEntitlement) {
			query[(__bridge id)kSecUseDataProtectionKeychain] = @NO;
			status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
		}
		if (status == errSecSuccess && result != NULL) {
			passwordData = (__bridge_transfer NSData *)result;
		} else if (status != errSecItemNotFound) {
			NSLog(@"Error retrieving item from keychain. Status code: %d", (int)status);
		}
	} else {
		NSLog(@"Invalid input: service or key string conversion failed");
	}

	if ((*env)->ExceptionCheck(env)) {
		return NULL;
	}
	jbyteArray password = NULL;
	if (passwordData) {
		password = (*env)->NewByteArray(env, (int)passwordData.length);
		if (password == NULL) {
			return NULL;
		}
		(*env)->SetByteArrayRegion(env, password, 0, (int)passwordData.length, (jbyte *)passwordData.bytes);
	}
	jclass resultClass = (*env)->FindClass(env, "org/cryptomator/macos/keychain/MacKeychain$LoadResult");
	if (resultClass == NULL) {
		return NULL;
	}
	jmethodID resultConstructor = (*env)->GetMethodID(env, resultClass, "<init>", "(I[B)V");
	if (resultConstructor == NULL) {
		return NULL;
	}
	return (*env)->NewObject(env, resultClass, resultConstructor, (jint)status, password);
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_deletePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
	NSString *serviceString = stringFromByteArray(env, service);
	NSString *keyString = stringFromByteArray(env, key);

	OSStatus status = errSecParam;

	if (serviceString && keyString) { // guard both NSStrings not to be NIL
		// spans both keychains on purpose, removing protected and unprotected items alike:
		LAContext *context = getSharedLAContext();
		NSDictionary *query = @{
			(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
			(__bridge id)kSecAttrService: serviceString,
			(__bridge id)kSecAttrAccount: keyString,
			(__bridge id)kSecUseAuthenticationContext: context
		};
		status = SecItemDelete((__bridge CFDictionaryRef)query);
		if (status != errSecSuccess) {
			NSLog(@"Error deleting item from keychain. Status code: %d", (int)status);
		}
	} else {
		NSLog(@"Invalid input: service or key string conversion failed");
	}

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
