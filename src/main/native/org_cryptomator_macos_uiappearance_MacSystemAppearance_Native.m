//
//  org_cryptomator_macos_uiappearance_MacSystemAppearance_Native.m
//  Integrations
//
//  Created by Sebastian Stenzel on 05.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#import "org_cryptomator_macos_uiappearance_MacSystemAppearance_Native.h"
#import <AppKit/AppKit.h>
#import "SKYAppearanceNotifier.h"
#import "SKYAppearanceObserver.h"

JNIEXPORT jstring JNICALL Java_org_cryptomator_macos_uiappearance_MacSystemAppearance_00024Native_getCurrentInterfaceStyle
(JNIEnv *env, jobject thisObj) {
    NSString *interfaceStyle = [NSUserDefaults.standardUserDefaults stringForKey:@"AppleInterfaceStyle"] ?: @"Light";
        return (*env)->NewStringUTF(env, [interfaceStyle cStringUsingEncoding:NSUTF8StringEncoding]);
}

JNIEXPORT jlong JNICALL Java_org_cryptomator_macos_uiappearance_MacSystemAppearance_00024Native_registerObserverWithListener
(JNIEnv *env, jobject thisObj, jobject listenerObj) {
    JavaVM *vm = NULL;
    if ((*env)->GetJavaVM(env, &vm) != JNI_OK) {
        return 0;
    }
    jobject listener = (*env)->NewGlobalRef(env, listenerObj);
    if (listener == NULL) {
        return 0;
    }
    SKYAppearanceObserver *observer = [[SKYAppearanceObserver alloc] initWithListener:listener vm:vm];
    [SKYAppearanceNotifier.sharedInstance addObserver:observer];
    long observerPtr = (long)(__bridge_retained CFTypeRef)observer;
    return observerPtr;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_uiappearance_MacSystemAppearance_00024Native_deregisterObserver
(JNIEnv *env, jobject thisObj, jlong observerPtr) {
    SKYAppearanceObserver *observer = (__bridge_transfer SKYAppearanceObserver *)((void *)observerPtr);
    (*env)->DeleteGlobalRef(env, observer.listener);
    [SKYAppearanceNotifier.sharedInstance removeObserver:observer];
}
