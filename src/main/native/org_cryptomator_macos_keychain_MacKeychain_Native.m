//
//  org_cryptomator_macos_keychain_MacKeychain_Native.m
//  Integrations
//
//  Created by Sebastian Stenzel on 29.08.16.
//  Copyright © 2016 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_keychain_MacKeychain_Native.h"
#import <Security/Security.h>

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_storePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key, jbyteArray password) {
	const int serviceLen = (*env)->GetArrayLength(env, service);
    jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	const int keyLen = (*env)->GetArrayLength(env, key);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);
	const int pwLen = (*env)->GetArrayLength(env, password);
	jbyte *pwStr = (*env)->GetByteArrayElements(env, password, NULL);

	// find existing:
	SecKeychainItemRef itemRef = NULL;
	OSStatus status = SecKeychainFindGenericPassword(
	    NULL,                // default keychain
	    serviceLen,          // length of service name
	    (char *)serviceStr,  // service name
	    keyLen,              // length of account name
	    (char *)keyStr,      // account name
	    NULL,                // length of password
	    NULL,                // pointer to password data
	    &itemRef             // the item reference
	    );
	if (status == errSecSuccess) {
		// update existing:
		status = SecKeychainItemModifyAttributesAndData(
		    itemRef, // the item reference
		    NULL,    // no change to attributes
		    pwLen,   // length of password
		    pwStr    // pointer to password data
		    );
	} else if (status == errSecItemNotFound) {
		// add new:
		status = SecKeychainAddGenericPassword(
		    NULL,                // default keychain
            serviceLen,          // length of service name
            (char *)serviceStr,  // service name
		    keyLen,              // length of account name
		    (char *)keyStr,      // account name
		    pwLen,               // length of password
		    pwStr,               // pointer to password data
		    NULL                 // the item reference
		    );
	}

	(*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);
	(*env)->ReleaseByteArrayElements(env, password, pwStr, JNI_ABORT);
	if (itemRef) {
		CFRelease(itemRef);
	}
	return status;
}

JNIEXPORT jbyteArray JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_loadPassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
	const int serviceLen = (*env)->GetArrayLength(env, service);
    jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	const int keyLen = (*env)->GetArrayLength(env, key);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);
	void *pwStr = NULL;
	UInt32 pwLen;
	OSStatus status = SecKeychainFindGenericPassword(
	    NULL,                // default keychain
	    serviceLen,          // length of service name
	    (char *)serviceStr,  // service name
	    keyLen,              // length of account name
	    (char *)keyStr,      // account name
	    &pwLen,              // length of password
	    &pwStr,              // pointer to password data
	    NULL                 // the item reference
	    );

	jbyteArray result;
	if (status == errSecSuccess) {
		result = (*env)->NewByteArray(env, pwLen);
		(*env)->SetByteArrayRegion(env, result, 0, pwLen, pwStr);
	} else {
		result = NULL;
	}

	(*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);
	if (pwStr) {
		SecKeychainItemFreeContent(NULL, pwStr);
	}
	return result;
}

JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_deletePassword(JNIEnv *env, jobject thisObj, jbyteArray service, jbyteArray key) {
	const int serviceLen = (*env)->GetArrayLength(env, service);
    jbyte *serviceStr = (*env)->GetByteArrayElements(env, service, NULL);
	const int keyLen = (*env)->GetArrayLength(env, key);
	jbyte *keyStr = (*env)->GetByteArrayElements(env, key, NULL);
	SecKeychainItemRef itemRef = NULL;
	OSStatus status = SecKeychainFindGenericPassword(
	    NULL,                // default keychain
	    serviceLen,          // length of service name
	    (char *)serviceStr,  // service name
	    keyLen,              // length of account name
	    (char *)keyStr,      // account name
	    NULL,                // length of password
	    NULL,                // pointer to password data
	    &itemRef             // the item reference
	    );

	if (status == errSecSuccess) {
		status = SecKeychainItemDelete(
		    itemRef // the item reference
		    );
	}

	(*env)->ReleaseByteArrayElements(env, key, keyStr, JNI_ABORT);
	if (itemRef) {
		CFRelease(itemRef);
	}
	return status;
}
