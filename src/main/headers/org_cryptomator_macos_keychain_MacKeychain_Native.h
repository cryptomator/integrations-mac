/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class org_cryptomator_macos_keychain_MacKeychain_Native */

#ifndef _Included_org_cryptomator_macos_keychain_MacKeychain_Native
#define _Included_org_cryptomator_macos_keychain_MacKeychain_Native
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     org_cryptomator_macos_keychain_MacKeychain_Native
 * Method:    storePassword
 * Signature: ([B[B[B)I
 */
JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_storePassword
  (JNIEnv *, jobject, jbyteArray, jbyteArray, jbyteArray);

/*
 * Class:     org_cryptomator_macos_keychain_MacKeychain_Native
 * Method:    storePasswordForAuthenticatedUser
 * Signature: ([B[B[B)I
 */
JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_storePasswordForAuthenticatedUser
  (JNIEnv *, jobject, jbyteArray, jbyteArray, jbyteArray);

/*
 * Class:     org_cryptomator_macos_keychain_MacKeychain_Native
 * Method:    loadPassword
 * Signature: ([B[B)[B
 */
JNIEXPORT jbyteArray JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_loadPassword
  (JNIEnv *, jobject, jbyteArray, jbyteArray);

/*
 * Class:     org_cryptomator_macos_keychain_MacKeychain_Native
 * Method:    deletePassword
 * Signature: ([B[B)I
 */
JNIEXPORT jint JNICALL Java_org_cryptomator_macos_keychain_MacKeychain_00024Native_deletePassword
  (JNIEnv *, jobject, jbyteArray, jbyteArray);

#ifdef __cplusplus
}
#endif
#endif
