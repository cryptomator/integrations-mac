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

// the kServiceName must be the same as in the project settings > Keychain Sharing > Keychain Groups

static SecAccessControlRef createAccessControl(void) {
    SecAccessControlCreateFlags flags = kSecAccessControlUserPresence;
    
    SecAccessControlRef accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenUnlocked,
        flags,
        NULL // Ignore any error
    );
    
    return accessControl;
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_storePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key, jbyteArray password) {
	jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);
	jbyte *pwStr = (*env)->GetByteArrayElements(env, password, NULL);
	jsize length = (*env)->GetArrayLength(env, password);

	// find existing:
    NSDictionary *searchAttributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
        (__bridge id)kSecReturnAttributes: @YES,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
        
    CFDictionaryRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchAttributes, (CFTypeRef *)&result);

    if (status == errSecSuccess && result != NULL) {
        NSLog(@"Item found in keychain, updating it.");

        // update existing:
        NSDictionary *changeAttributes = @{
            (__bridge id)kSecValueData: [NSData dataWithBytes:pwStr length:length]
        };

        status = SecItemUpdate((__bridge CFDictionaryRef)searchAttributes, (__bridge CFDictionaryRef)changeAttributes);

        } else if (status == errSecItemNotFound) {
            NSLog(@"Adding item to keychain.");

            // add new:
            NSDictionary *keychainAttributes = @{
                (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
                //(__bridge id)kSecAttrAccessControl: (__bridge_transfer id)createAccessControl(),
                (__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
                (__bridge id)kSecValueData: [NSData dataWithBytes:pwStr length:length]
            };

            status = SecItemAdd((__bridge CFDictionaryRef)keychainAttributes, NULL);

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

    // Create a dictionary of search attributes to find the item in the keychain
    NSDictionary *searchAttributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
        (__bridge id)kSecReturnAttributes: @YES,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
        
    CFDictionaryRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchAttributes, (CFTypeRef *)&result);

    (*env)->ReleaseByteArrayElements(env, service, serviceStr, JNI_ABORT);
    (*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);

    if (status == errSecSuccess && result != NULL) {
            NSDictionary *attributes = (__bridge_transfer NSDictionary *)result;
            NSData *passwordData = attributes[(__bridge id)kSecValueData];
            NSLog(@"Item found in keychain.");

            NSUInteger pwLen = [passwordData length];
            const void *pwBytes = [passwordData bytes];

            jbyteArray password = (*env)->NewByteArray(env, (int)pwLen);
            (*env)->SetByteArrayRegion(env, password, 0, (int)pwLen, (jbyte *)pwBytes);

            return password;

        } else if (status == errSecItemNotFound) {
            NSLog(@"No matching item found in the keychain.");
        } else {
            NSLog(@"Error retrieving item from keychain. Status code: %d", (int)status);
        }

    return NULL; // empty
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_deletePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
    jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
    jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);

    // find existing:
    NSDictionary *searchAttributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [NSString stringWithCString:(char *)serviceStr encoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccount: [NSString stringWithCString:(char *)keyStr encoding:NSUTF8StringEncoding],
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
        
    CFDictionaryRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchAttributes, (CFTypeRef *)&result);

    if (status == errSecSuccess && result != NULL) {
        NSLog(@"Item found in keychain, deleting it.");

        status = SecItemDelete((__bridge CFDictionaryRef)searchAttributes);

        } else if (status == errSecItemNotFound) {
            NSLog(@"No matching item found in the keychain.");

        } else {
            NSLog(@"Error deleting item from keychain. Status code: %d", (int)status);
        }

    (*env)->ReleaseByteArrayElements(env, service, serviceStr, JNI_ABORT);
    (*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);

    return status;
}
