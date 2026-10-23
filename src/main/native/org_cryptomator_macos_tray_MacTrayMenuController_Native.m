//
//  org_cryptomator_macos_tray_MacTrayMenuController_Native.m
//  Integrations
//
//  Created by oc7o on 24.05.26.
//  Copyright © 2026 Cryptomator. All rights reserved.
//

#import <AppKit/AppKit.h>
#include <jni.h>
#include "org_cryptomator_macos_tray_MacTrayMenuController_Native.h"

static JavaVM *gJvm = NULL;

// Cached java.lang.Runnable.run() method ID for invoking Java callbacks.
static jmethodID gRunnableRun = NULL;

// The following globals are only accessed on the main thread.
static NSStatusItem *gStatusItem = nil;
static jobject gBeforeOpenListener = NULL;

static JNIEnv *getEnv(void) {
	JNIEnv *env = NULL;
	if ((*gJvm)->GetEnv(gJvm, (void **)&env, JNI_VERSION_10) == JNI_EDETACHED) {
		(*gJvm)->AttachCurrentThreadAsDaemon(gJvm, (void **)&env, NULL);
	}
	return env;
}

static void callRunnable(jobject runnable) {
	JNIEnv *env = getEnv();
	if (env == NULL || runnable == NULL || gRunnableRun == NULL) {
		return;
	}
	(*env)->CallVoidMethod(env, runnable, gRunnableRun);
	if ((*env)->ExceptionCheck(env)) {
		// Java wraps all callbacks in a logging try/catch, so only Errors end up here.
		(*env)->ExceptionDescribe(env);
		(*env)->ExceptionClear(env);
	}
}

static void deleteGlobalRef(jobject ref) {
	JNIEnv *env = getEnv();
	if (env != NULL && ref != NULL) {
		(*env)->DeleteGlobalRef(env, ref);
	}
}

// The helpers below use alloc/init, so the returned objects are owned (+1) and
// never land in an autorelease pool, even on Java threads that have none.
NS_RETURNS_RETAINED static NSString *newStringFromJava(JNIEnv *env, jstring str) {
	if (str == NULL) {
		return nil;
	}
	const char *chars = (*env)->GetStringUTFChars(env, str, NULL);
	if (chars == NULL) {
		return nil;
	}
	NSString *result = [[NSString alloc] initWithUTF8String:chars];
	(*env)->ReleaseStringUTFChars(env, str, chars);
	return result;
}

NS_RETURNS_RETAINED static NSData *newDataFromJava(JNIEnv *env, jbyteArray array) {
	if (array == NULL) {
		return nil;
	}
	jsize len = (*env)->GetArrayLength(env, array);
	jbyte *bytes = (*env)->GetByteArrayElements(env, array, NULL);
	if (bytes == NULL) {
		return nil;
	}
	NSData *result = [[NSData alloc] initWithBytes:bytes length:len];
	(*env)->ReleaseByteArrayElements(env, array, bytes, JNI_ABORT);
	return result;
}

// Synchronous, so calls keep their order and addSubMenuItem can return its handle.
// Callers must not hold a lock that the main thread may be waiting for.
static void runOnMainThread(dispatch_block_t block) {
	if ([NSThread isMainThread]) {
		block();
	} else {
		dispatch_sync(dispatch_get_main_queue(), block);
	}
}

@interface SKYActionHandler : NSObject
- (instancetype)initWithAction:(jobject)action;
- (void)fire:(id)sender;
@end

@implementation SKYActionHandler {
	jobject _action;
}

- (instancetype)initWithAction:(jobject)action {
	if (self = [super init]) {
		_action = action; // global ref owned by this handler
	}
	return self;
}

- (void)dealloc {
	deleteGlobalRef(_action);
}

- (void)fire:(id)sender {
	callRunnable(_action);
}

@end

@interface SKYMenuDelegate : NSObject <NSMenuDelegate>
@end

static NSMenu *rootMenu(void);

@implementation SKYMenuDelegate

// menuNeedsUpdate: rather than menuWillOpen:, because the listener may rebuild
// the menu, and AppKit only permits structural changes at this point.
- (void)menuNeedsUpdate:(NSMenu *)menu {
	// Only the root tray menu shall trigger the callback, not submenus.
	if (menu == rootMenu()) {
		callRunnable(gBeforeOpenListener);
	}
}

@end

// NSMenuItem.target is a weak reference, so action handlers are retained here
// for the menu's lifetime and released in clearMenu().
static NSMutableArray *gActionHandlers = nil;

static SKYMenuDelegate *gMenuDelegate = nil;

// Created once and kept for the library's lifetime, so the menu can be built
// independently of whether showTrayIcon has been called yet.
static NSMenu *rootMenu(void) {
	static NSMenu *menu = nil;
	if (menu == nil) {
		menu = [[NSMenu alloc] init];
		menu.autoenablesItems = NO;
		menu.delegate = gMenuDelegate;
	}
	return menu;
}

// Menu handles crossing the JNI boundary are raw NSMenu pointers cast to jlong;
// 0 (ROOT_MENU) denotes the root menu. Submenus are only kept alive by the menu
// tree, so handles are valid until the next clearMenu().
static NSMenu *menuFromHandle(jlong handle) {
	if (handle == 0L) {
		return rootMenu();
	}
	return (__bridge NSMenu *)(void *)(intptr_t)handle;
}

// This is the only JNI_OnLoad in the library, so it runs regardless of which
// integration is used first. It must not fail, or every integration would break.
JNIEXPORT jint JNI_OnLoad(JavaVM *jvm, void *reserved) {
	gJvm = jvm;
	gActionHandlers = [[NSMutableArray alloc] init];
	gMenuDelegate = [[SKYMenuDelegate alloc] init];

	JNIEnv *env = NULL;
	if ((*jvm)->GetEnv(jvm, (void **)&env, JNI_VERSION_10) == JNI_OK) {
		jclass runnableClass = (*env)->FindClass(env, "java/lang/Runnable");
		if (runnableClass != NULL) {
			gRunnableRun = (*env)->GetMethodID(env, runnableClass, "run", "()V");
			(*env)->DeleteLocalRef(env, runnableClass);
		}
	}
	return JNI_VERSION_10;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_runOnMainThread
(JNIEnv *env, jobject obj, jobject task) {
	jobject taskRef = (*env)->NewGlobalRef(env, task);
	runOnMainThread(^{
		callRunnable(taskRef);
	});
	(*env)->DeleteGlobalRef(env, taskRef);
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_showTrayIcon
(JNIEnv *env, jobject obj, jbyteArray pngData, jstring tooltip) {
	NSData *imageData = newDataFromJava(env, pngData);
	NSString *tooltipStr = newStringFromJava(env, tooltip);
	__block BOOL success = NO;

	runOnMainThread(^{
		@autoreleasepool { // systemStatusBar and statusItemWithLength: return autoreleased objects
			NSImage *image = imageData != nil ? [[NSImage alloc] initWithData:imageData] : nil;
			if (image == nil) {
				return;
			}
			image.size = NSMakeSize(18, 18);
			image.template = YES;

			if (gStatusItem != nil) {
				[[NSStatusBar systemStatusBar] removeStatusItem:gStatusItem];
			}
			gStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
			gStatusItem.button.image = image;
			gStatusItem.button.toolTip = tooltipStr;
			gStatusItem.menu = rootMenu();
			success = gStatusItem.button != nil;
		}
	});
	return success;
}

JNIEXPORT jboolean JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_updateTrayIcon
(JNIEnv *env, jobject obj, jbyteArray pngData) {
	NSData *imageData = newDataFromJava(env, pngData);
	__block BOOL success = NO;

	runOnMainThread(^{
		NSImage *image = imageData != nil ? [[NSImage alloc] initWithData:imageData] : nil;
		if (image == nil || gStatusItem == nil) {
			return;
		}
		image.size = NSMakeSize(18, 18);
		image.template = YES;
		gStatusItem.button.image = image;
		success = YES;
	});
	return success;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_clearMenu
(JNIEnv *env, jobject obj) {
	runOnMainThread(^{
		[rootMenu() removeAllItems];
		[gActionHandlers removeAllObjects];
	});
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addActionItem
(JNIEnv *env, jobject obj, jlong menuHandle, jstring title, jboolean enabled, jobject action) {
	NSString *titleStr = newStringFromJava(env, title) ?: @"";
	jobject actionRef = action != NULL ? (*env)->NewGlobalRef(env, action) : NULL;

	runOnMainThread(^{
		SKYActionHandler *handler = [[SKYActionHandler alloc] initWithAction:actionRef];
		[gActionHandlers addObject:handler];

		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:titleStr action:@selector(fire:) keyEquivalent:@""];
		item.target = handler;
		item.enabled = enabled && actionRef != NULL;
		[menuFromHandle(menuHandle) addItem:item];
	});
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addSeparator
(JNIEnv *env, jobject obj, jlong menuHandle) {
	runOnMainThread(^{
		@autoreleasepool { // separatorItem returns an autoreleased object
			[menuFromHandle(menuHandle) addItem:[NSMenuItem separatorItem]];
		}
	});
}

JNIEXPORT jlong JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addSubMenuItem
(JNIEnv *env, jobject obj, jlong menuHandle, jstring title) {
	NSString *titleStr = newStringFromJava(env, title) ?: @"";
	__block jlong result = 0L;

	runOnMainThread(^{
		NSMenu *submenu = [[NSMenu alloc] initWithTitle:titleStr];
		submenu.autoenablesItems = NO;
		// Submenus share the delegate, but menuNeedsUpdate: ignores non-root menus.
		submenu.delegate = gMenuDelegate;

		NSMenuItem *parentItem = [[NSMenuItem alloc] initWithTitle:titleStr action:NULL keyEquivalent:@""];
		parentItem.submenu = submenu;
		[menuFromHandle(menuHandle) addItem:parentItem];

		result = (jlong)(intptr_t)(__bridge void *)submenu;
	});
	return result;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_setBeforeOpenMenuListener
(JNIEnv *env, jobject obj, jobject listener) {
	jobject listenerRef = listener != NULL ? (*env)->NewGlobalRef(env, listener) : NULL;

	// No AppKit involved, but swapping on the main thread avoids racing with menuNeedsUpdate:.
	runOnMainThread(^{
		deleteGlobalRef(gBeforeOpenListener);
		gBeforeOpenListener = listenerRef;
	});
}
