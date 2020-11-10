//
//  SKYAppearanceObserver.m
//  Integrations
//
//  Created by Sebastian Stenzel on 05.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#import "SKYAppearanceObserver.h"

@interface SKYAppearanceObserver ()
@property (nonatomic, assign) jobject listener;
@property (nonatomic, assign) JavaVM *vm;
@end

@implementation SKYAppearanceObserver

- (instancetype)initWithListener:(jobject)listener vm:(JavaVM *)vm {
    if (self = [super init]) {
        self.listener = listener;
        self.vm = vm;
    }
    return self;
}

- (void)interfaceThemeChangedNotification:(NSNotification *)notification {
    JNIEnv *env = NULL;
    if ((*self.vm)->GetEnv(self.vm, (void **)&env, JNI_VERSION_10) == JNI_EDETACHED) {
        (*self.vm)->AttachCurrentThread(self.vm, (void **)&env, NULL);
    }
    if (env == NULL) {
        return;
    }
    jclass listenerClass = (*env)->GetObjectClass(env, self.listener);
    if (listenerClass == NULL) {
        return;
    }
    jmethodID listenerMethodID = (*env)->GetMethodID(env, listenerClass, "systemAppearanceChanged", "()V");
    if (listenerMethodID == NULL) {
        return;
    }
    (*env)->CallVoidMethod(env, self.listener, listenerMethodID);
}

@end
