//
//  org_cryptomator_macos_tray_MacTrayMenuController_Native.m
//

#import <AppKit/AppKit.h>
#include <jni.h>
#include "org_cryptomator_macos_tray_MacTrayMenuController_Native.h"

static JavaVM *gJvm = NULL;
static NSStatusItem *gStatusItem = nil;
static NSMenu *gRootMenu = nil;

static jobject gBeforeOpenListener = NULL;

// Cached java.lang.Runnable.run() method ID for invoking Java callbacks.
static jmethodID gRunnableRun = NULL;

static JNIEnv *getEnv(void) {
	JNIEnv *env = NULL;
	(*gJvm)->AttachCurrentThread(gJvm, (void **)&env, NULL);
	return env;
}

static void callRunnable(JNIEnv *env, jobject runnable) {
	(*env)->CallVoidMethod(env, runnable, gRunnableRun);
	if ((*env)->ExceptionCheck(env)) {
		(*env)->ExceptionDescribe(env); // Log to stderr for debugging
		(*env)->ExceptionClear(env);
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
	self = [super init];
	_action = action; // global ref owned by this handler
	return self;
}

- (void)dealloc {
	JNIEnv *env = getEnv();
	(*env)->DeleteGlobalRef(env, _action);
}

- (void)fire:(id)sender {
	JNIEnv *env = getEnv();
	callRunnable(env, _action);
}

@end

@interface SKYMenuDelegate : NSObject <NSMenuDelegate>
@end

@implementation SKYMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
	// Only the root tray menu shall trigger the callback, not submenus.
	if (menu != gRootMenu) {
		return;
	}
	if (gBeforeOpenListener != NULL) {
		JNIEnv *env = getEnv();
		callRunnable(env, gBeforeOpenListener);
	}
}

@end

// NSMenuItem.target is a weak reference, so action handlers are retained here
// for the menu's lifetime and released in clearMenu().
static NSMutableArray *gActionHandlers = nil;

// Single delegate created during JNI_OnLoad so its lifecycle is independent of
// the call order of showTrayIcon and setBeforeOpenMenuListener.
static SKYMenuDelegate *gMenuDelegate = nil;

// Menu handles crossing the JNI boundary are raw NSMenu pointers cast to jlong;
// 0 (ROOT_MENU) denotes the status item's root menu.
static NSMenu *menuFromHandle(jlong handle) {
	if (handle == 0L) {
		return gRootMenu;
	}
	return (__bridge NSMenu *)(void *)(intptr_t)handle;
}

JNIEXPORT jint JNI_OnLoad(JavaVM *jvm, void *reserved) {
	@autoreleasepool {
		gJvm = jvm;
		gActionHandlers = [NSMutableArray array];
		gMenuDelegate = [[SKYMenuDelegate alloc] init];

		JNIEnv *env;
		if ((*jvm)->GetEnv(jvm, (void **)&env, JNI_VERSION_1_8) == JNI_OK) {
			jclass runnableClass = (*env)->FindClass(env, "java/lang/Runnable");
			gRunnableRun = (*env)->GetMethodID(env, runnableClass, "run", "()V");
			(*env)->DeleteLocalRef(env, runnableClass);
		}
	}
	return JNI_VERSION_1_8;
}

JNIEXPORT void JNI_OnUnload(JavaVM *jvm, void *reserved) {
	@autoreleasepool {
		if (gBeforeOpenListener != NULL) {
			JNIEnv *env = getEnv();
			(*env)->DeleteGlobalRef(env, gBeforeOpenListener);
			gBeforeOpenListener = NULL;
		}
		gMenuDelegate = nil;
		gActionHandlers = nil;
		gJvm = NULL;
	}
}

static void runOnMainThread(void (^block)(void)) {
	if ([NSThread isMainThread]) {
		block();
	} else {
		dispatch_sync(dispatch_get_main_queue(), block);
	}
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_showTrayIcon
(JNIEnv *env, jobject obj, jbyteArray pngData, jstring tooltip, jobject defaultAction) {
	// defaultAction is intentionally unused: this status item always presents its
	// menu on click (see gStatusItem.menu below)
	(void)defaultAction;

	@autoreleasepool {
		jsize len = (*env)->GetArrayLength(env, pngData);
		jbyte *bytes = (*env)->GetByteArrayElements(env, pngData, NULL);
		NSData *imageData = [NSData dataWithBytes:bytes length:len];
		(*env)->ReleaseByteArrayElements(env, pngData, bytes, JNI_ABORT);

		const char *tooltipChars = (*env)->GetStringUTFChars(env, tooltip, NULL);
		NSString *tooltipStr = [NSString stringWithUTF8String:tooltipChars];
		(*env)->ReleaseStringUTFChars(env, tooltip, tooltipChars);

		runOnMainThread((dispatch_block_t)^(void) {
			@autoreleasepool {
				if (gStatusItem != nil) {
					[[NSStatusBar systemStatusBar] removeStatusItem:gStatusItem];
					gStatusItem = nil;
				}

				[gRootMenu removeAllItems];
				[gActionHandlers removeAllObjects];

				gRootMenu = [[NSMenu alloc] init];
				[gRootMenu setAutoenablesItems:NO];
				gRootMenu.delegate = gMenuDelegate;

				NSImage *image = [[NSImage alloc] initWithData:imageData];
				image.size = NSMakeSize(18, 18);
				image.template = YES;

				gStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
				gStatusItem.button.image = image;
				gStatusItem.button.toolTip = tooltipStr;
				gStatusItem.menu = gRootMenu;
			}
		});
	}
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_updateTrayIcon
(JNIEnv *env, jobject obj, jbyteArray pngData) {
	@autoreleasepool {
		jsize len = (*env)->GetArrayLength(env, pngData);
		jbyte *bytes = (*env)->GetByteArrayElements(env, pngData, NULL);
		NSData *imageData = [NSData dataWithBytes:bytes length:len];
		(*env)->ReleaseByteArrayElements(env, pngData, bytes, JNI_ABORT);

		runOnMainThread((dispatch_block_t)^(void) {
			@autoreleasepool {
				NSImage *image = [[NSImage alloc] initWithData:imageData];
				image.size = NSMakeSize(18, 18);
				image.template = YES;
				gStatusItem.button.image = image;
			}
		});
	}
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_clearMenu
(JNIEnv *env, jobject obj) {
	runOnMainThread((dispatch_block_t)^(void) {
		@autoreleasepool {
			[gRootMenu removeAllItems];
			[gActionHandlers removeAllObjects];
		}
	});
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addActionItem
(JNIEnv *env, jobject obj, jlong menuHandle, jstring title, jboolean enabled, jobject action) {
	@autoreleasepool {
		const char *titleChars = (*env)->GetStringUTFChars(env, title, NULL);
		NSString *titleStr = [NSString stringWithUTF8String:titleChars];
		(*env)->ReleaseStringUTFChars(env, title, titleChars);

		jobject actionRef = (*env)->NewGlobalRef(env, action);

		runOnMainThread((dispatch_block_t)^(void) {
			@autoreleasepool {
				SKYActionHandler *handler = [[SKYActionHandler alloc] initWithAction:actionRef];
				[gActionHandlers addObject:handler];

				NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:titleStr
														  action:@selector(fire:)
											   keyEquivalent:@""];
				item.target = handler;
				item.enabled = (BOOL)enabled;
				[menuFromHandle(menuHandle) addItem:item];
			}
		});
	}
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addSeparator
(JNIEnv *env, jobject obj, jlong menuHandle) {
	runOnMainThread((dispatch_block_t)^(void) {
		@autoreleasepool {
			[menuFromHandle(menuHandle) addItem:[NSMenuItem separatorItem]];
		}
	});
}

JNIEXPORT jlong JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addSubMenuItem
(JNIEnv *env, jobject obj, jlong menuHandle, jstring title) {
	__block jlong result = 0L;

	@autoreleasepool {
		const char *titleChars = (*env)->GetStringUTFChars(env, title, NULL);
		NSString *titleStr = [NSString stringWithUTF8String:titleChars];
		(*env)->ReleaseStringUTFChars(env, title, titleChars);

		runOnMainThread((dispatch_block_t)^(void) {
			@autoreleasepool {
				NSMenu *submenu = [[NSMenu alloc] initWithTitle:titleStr];
				[submenu setAutoenablesItems:NO];
				// Submenus share the delegate, but menuWillOpen: ignores non-root menus.
				submenu.delegate = gMenuDelegate;

				NSMenuItem *parentItem = [[NSMenuItem alloc] initWithTitle:titleStr
																action:NULL
												 keyEquivalent:@""];
				parentItem.submenu = submenu;
				[menuFromHandle(menuHandle) addItem:parentItem];

				result = (jlong)(intptr_t)(__bridge void *)submenu;
			}
		});
	}

	return result;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_setBeforeOpenMenuListener
(JNIEnv *env, jobject obj, jobject listener) {
	@autoreleasepool {
		jobject listenerRef = (*env)->NewGlobalRef(env, listener);

		runOnMainThread((dispatch_block_t)^(void) {
			@autoreleasepool {
				if (gBeforeOpenListener != NULL) {
					JNIEnv *mainEnv = getEnv();
					(*mainEnv)->DeleteGlobalRef(mainEnv, gBeforeOpenListener);
				}
				gBeforeOpenListener = listenerRef;
			}
		});
	}
}
