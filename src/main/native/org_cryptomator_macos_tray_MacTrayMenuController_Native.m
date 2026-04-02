#import <Cocoa/Cocoa.h>
#include <jni.h>
#include "org_cryptomator_macos_tray_MacTrayMenuController.h"

// ---------------------------------------------------------------------------
// Global state
// ---------------------------------------------------------------------------
static NSStatusItem *statusItem;
static JavaVM *jvm = NULL;

// ---------------------------------------------------------------------------
// SKYMenuItemAction — holds a Java Runnable and invokes it when a menu item
// is selected.  The global ref is owned by this object and deleted on dealloc.
// ---------------------------------------------------------------------------
@interface SKYMenuItemAction : NSObject
- (instancetype)initWithRunnable:(jobject)runnableGlobalRef vm:(JavaVM *)vm;
- (void)invoke:(id)sender;
@end

@implementation SKYMenuItemAction {
    jobject _runnable; // global ref
    JavaVM *_vm;
}

- (instancetype)initWithRunnable:(jobject)runnableGlobalRef vm:(JavaVM *)vm {
    if (self = [super init]) {
        _runnable = runnableGlobalRef;
        _vm = vm;
    }
    return self;
}

- (void)dealloc {
    if (_runnable != NULL) {
        JNIEnv *env = NULL;
        (*_vm)->GetEnv(_vm, (void **)&env, JNI_VERSION_1_8);
        if (env) (*env)->DeleteGlobalRef(env, _runnable);
        _runnable = NULL;
    }
}

- (void)invoke:(id)sender {
    JNIEnv *env = NULL;
    BOOL attached = (*_vm)->GetEnv(_vm, (void **)&env, JNI_VERSION_1_8) == JNI_EDETACHED;
    if (attached) (*_vm)->AttachCurrentThread(_vm, (void **)&env, NULL);
    if (!env) return;

    jclass cls = (*env)->GetObjectClass(env, _runnable);
    jmethodID run = (*env)->GetMethodID(env, cls, "run", "()V");
    if (run) (*env)->CallVoidMethod(env, _runnable, run);
    (*env)->DeleteLocalRef(env, cls);

    if (attached) (*_vm)->DetachCurrentThread(_vm);
}
@end

// ---------------------------------------------------------------------------
// SKYMenuDelegate — NSMenuDelegate that fires the beforeOpenCallback.
// ---------------------------------------------------------------------------
@interface SKYMenuDelegate : NSObject <NSMenuDelegate>
- (instancetype)initWithVM:(JavaVM *)vm;
- (void)updateCallback:(jobject)callbackGlobalRef; // transfers ownership of global ref
@end

@implementation SKYMenuDelegate {
    jobject _callback; // global ref or NULL
    JavaVM *_vm;
}

- (instancetype)initWithVM:(JavaVM *)vm {
    if (self = [super init]) {
        _callback = NULL;
        _vm = vm;
    }
    return self;
}

- (void)updateCallback:(jobject)callbackGlobalRef {
    JNIEnv *env = NULL;
    (*_vm)->GetEnv(_vm, (void **)&env, JNI_VERSION_1_8);
    if (env && _callback) (*env)->DeleteGlobalRef(env, _callback);
    _callback = callbackGlobalRef;
}

- (void)menuWillOpen:(NSMenu *)menu {
    if (!_callback) return;

    JNIEnv *env = NULL;
    BOOL attached = (*_vm)->GetEnv(_vm, (void **)&env, JNI_VERSION_1_8) == JNI_EDETACHED;
    if (attached) (*_vm)->AttachCurrentThread(_vm, (void **)&env, NULL);
    if (!env) return;

    jclass cls = (*env)->GetObjectClass(env, _callback);
    jmethodID run = (*env)->GetMethodID(env, cls, "run", "()V");
    if (run) (*env)->CallVoidMethod(env, _callback, run);
    (*env)->DeleteLocalRef(env, cls);

    if (attached) (*_vm)->DetachCurrentThread(_vm);
}
@end

static SKYMenuDelegate *menuDelegate = nil;

// ---------------------------------------------------------------------------
// scaleImageToMenuBar — scales NSImage to match the status bar height
static void scaleImageToMenuBar(NSImage *image) {
    CGFloat barHeight = [NSStatusBar systemStatusBar].thickness;
    CGFloat ratio = barHeight / image.size.height;
    image.size = NSMakeSize(round(image.size.width * ratio), barHeight);
}

// buildNSMenu — recursively converts a Java NativeMenu DTO into an NSMenu.
// Must be called with a valid JNIEnv (i.e. on a JVM-attached thread).
// ---------------------------------------------------------------------------
static NSMenu *buildNSMenu(JNIEnv *env, jobject nativeMenuObj) {
    NSMenu *menu = [[NSMenu alloc] init];
    menu.autoenablesItems = NO;

    // NativeMenu.items  (List<NativeMenuItem>)
    jclass menuClass = (*env)->GetObjectClass(env, nativeMenuObj);
    jfieldID itemsFid = (*env)->GetFieldID(env, menuClass, "items", "Ljava/util/List;");
    jobject itemsList = (*env)->GetObjectField(env, nativeMenuObj, itemsFid);
    (*env)->DeleteLocalRef(env, menuClass);
    if (!itemsList) return menu;

    jclass listClass     = (*env)->FindClass(env, "java/util/List");
    jmethodID sizeMid    = (*env)->GetMethodID(env, listClass, "size", "()I");
    jmethodID getMid     = (*env)->GetMethodID(env, listClass, "get", "(I)Ljava/lang/Object;");
    jint size = (*env)->CallIntMethod(env, itemsList, sizeMid);
    (*env)->DeleteLocalRef(env, listClass);

    jclass actionClass    = (*env)->FindClass(env, "org/cryptomator/macos/tray/MacTrayMenuController$NativeActionItem");
    jclass separatorClass = (*env)->FindClass(env, "org/cryptomator/macos/tray/MacTrayMenuController$NativeSeparatorItem");
    jclass subMenuClass   = (*env)->FindClass(env, "org/cryptomator/macos/tray/MacTrayMenuController$NativeSubMenuItem");

    jfieldID actionTitleFid   = (*env)->GetFieldID(env, actionClass, "title", "Ljava/lang/String;");
    jfieldID actionEnabledFid = (*env)->GetFieldID(env, actionClass, "enabled", "Z");
    jfieldID actionRunnableFid= (*env)->GetFieldID(env, actionClass, "action", "Ljava/lang/Runnable;");
    jfieldID subTitleFid      = (*env)->GetFieldID(env, subMenuClass, "title", "Ljava/lang/String;");
    jfieldID subSubmenuFid    = (*env)->GetFieldID(env, subMenuClass, "submenu",
        "Lorg/cryptomator/macos/tray/MacTrayMenuController$NativeMenu;");

    for (jint i = 0; i < size; i++) {
        jobject item = (*env)->CallObjectMethod(env, itemsList, getMid, i);
        if (!item) continue;

        if ((*env)->IsInstanceOf(env, item, actionClass)) {
            // --- ActionItem ---
            jstring jTitle    = (jstring)(*env)->GetObjectField(env, item, actionTitleFid);
            jboolean enabled  = (*env)->GetBooleanField(env, item, actionEnabledFid);
            jobject jRunnable = (*env)->GetObjectField(env, item, actionRunnableFid);

            const char *titleChars = (*env)->GetStringUTFChars(env, jTitle, NULL);
            NSString *title = [NSString stringWithUTF8String:titleChars];
            (*env)->ReleaseStringUTFChars(env, jTitle, titleChars);
            (*env)->DeleteLocalRef(env, jTitle);

            jobject runnableGlobalRef = (*env)->NewGlobalRef(env, jRunnable);
            (*env)->DeleteLocalRef(env, jRunnable);
            SKYMenuItemAction *handler = [[SKYMenuItemAction alloc] initWithRunnable:runnableGlobalRef vm:jvm];

            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(invoke:) keyEquivalent:@""];
            menuItem.target = handler;
            menuItem.enabled = (BOOL)enabled;
            menuItem.representedObject = handler; // keeps handler alive with the menu item
            [menu addItem:menuItem];

        } else if ((*env)->IsInstanceOf(env, item, separatorClass)) {
            // --- SeparatorItem ---
            [menu addItem:[NSMenuItem separatorItem]];

        } else if ((*env)->IsInstanceOf(env, item, subMenuClass)) {
            // --- SubMenuItem ---
            jstring jTitle = (jstring)(*env)->GetObjectField(env, item, subTitleFid);
            jobject jSubmenu = (*env)->GetObjectField(env, item, subSubmenuFid);

            const char *titleChars = (*env)->GetStringUTFChars(env, jTitle, NULL);
            NSString *title = [NSString stringWithUTF8String:titleChars];
            (*env)->ReleaseStringUTFChars(env, jTitle, titleChars);
            (*env)->DeleteLocalRef(env, jTitle);

            NSMenu *submenu = buildNSMenu(env, jSubmenu);
            submenu.title = title;
            (*env)->DeleteLocalRef(env, jSubmenu);

            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
            menuItem.submenu = submenu;
            menuItem.enabled = YES;
            [menu addItem:menuItem];
        }

        (*env)->DeleteLocalRef(env, item);
    }

    (*env)->DeleteLocalRef(env, itemsList);
    (*env)->DeleteLocalRef(env, actionClass);
    (*env)->DeleteLocalRef(env, separatorClass);
    (*env)->DeleteLocalRef(env, subMenuClass);

    return menu;
}

// ---------------------------------------------------------------------------
// JNI functions
// ---------------------------------------------------------------------------

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    jvm = vm;
    return JNI_VERSION_1_8;
}

JNIEXPORT void JNICALL
Java_org_cryptomator_macos_tray_MacTrayMenuController_nativeShowTrayIcon(JNIEnv *env, jclass clazz,
                                                                          jbyteArray pngData,
                                                                          jstring jTooltip,
                                                                          jobject defaultAction) {
    // Copy JNI data to Obj-C objects before dispatch_async — local refs are only
    // valid during this JNI call, not inside the async block.
    jsize len = (*env)->GetArrayLength(env, pngData);
    jbyte *bytes = (*env)->GetByteArrayElements(env, pngData, NULL);
    NSData *imageData = [NSData dataWithBytes:bytes length:(NSUInteger)len];
    (*env)->ReleaseByteArrayElements(env, pngData, bytes, JNI_ABORT);

    const char *tooltipChars = (*env)->GetStringUTFChars(env, jTooltip, NULL);
    NSString *tooltip = [NSString stringWithUTF8String:tooltipChars];
    (*env)->ReleaseStringUTFChars(env, jTooltip, tooltipChars);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!statusItem) {
            statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        }
        NSImage *image = [[NSImage alloc] initWithData:imageData];
        // setTemplate:YES tells macOS to handle dimming/tinting automatically on every
        // screen and in every appearance — this is the fix for the multi-monitor bug.
        [image setTemplate:YES];
        scaleImageToMenuBar(image);
        statusItem.button.image = image;
        statusItem.button.toolTip = tooltip;

        if (!menuDelegate) {
            menuDelegate = [[SKYMenuDelegate alloc] initWithVM:jvm];
        }
    });
}

JNIEXPORT void JNICALL
Java_org_cryptomator_macos_tray_MacTrayMenuController_nativeUpdateTrayIcon(JNIEnv *env, jclass clazz,
                                                                            jbyteArray pngData) {
    jsize len = (*env)->GetArrayLength(env, pngData);
    jbyte *bytes = (*env)->GetByteArrayElements(env, pngData, NULL);
    NSData *imageData = [NSData dataWithBytes:bytes length:(NSUInteger)len];
    (*env)->ReleaseByteArrayElements(env, pngData, bytes, JNI_ABORT);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!statusItem) return;
        NSImage *image = [[NSImage alloc] initWithData:imageData];
        [image setTemplate:YES];
        scaleImageToMenuBar(image);
        statusItem.button.image = image;
    });
}

JNIEXPORT void JNICALL
Java_org_cryptomator_macos_tray_MacTrayMenuController_nativeUpdateTrayMenu(JNIEnv *env, jclass clazz,
                                                                            jobject nativeMenuDto) {
    // Keep the Java DTO alive across the async boundary via a global ref.
    // The block will attach to the JVM on the main thread, build the NSMenu, then
    // delete the global ref.
    jobject menuGlobalRef = (*env)->NewGlobalRef(env, nativeMenuDto);

    dispatch_async(dispatch_get_main_queue(), ^{
        JNIEnv *mainEnv = NULL;
        BOOL attached = (*jvm)->GetEnv(jvm, (void **)&mainEnv, JNI_VERSION_1_8) == JNI_EDETACHED;
        if (attached) (*jvm)->AttachCurrentThread(jvm, (void **)&mainEnv, NULL);
        if (!mainEnv) return; // extremely unlikely; global ref leaks, but nothing to be done

        NSMenu *menu = buildNSMenu(mainEnv, menuGlobalRef);
        (*mainEnv)->DeleteGlobalRef(mainEnv, menuGlobalRef);

        if (menuDelegate) menu.delegate = menuDelegate;
        if (statusItem) statusItem.menu = menu;

        if (attached) (*jvm)->DetachCurrentThread(jvm);
    });
}

JNIEXPORT void JNICALL
Java_org_cryptomator_macos_tray_MacTrayMenuController_nativeSetBeforeOpenCallback(JNIEnv *env, jclass clazz,
                                                                                   jobject callback) {
    jobject callbackGlobalRef = callback ? (*env)->NewGlobalRef(env, callback) : NULL;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!menuDelegate) {
            menuDelegate = [[SKYMenuDelegate alloc] initWithVM:jvm];
        }
        [menuDelegate updateCallback:callbackGlobalRef]; // transfers ownership
        // Ensure the already-assigned menu also picks up the delegate
        if (statusItem && statusItem.menu && statusItem.menu.delegate != menuDelegate) {
            statusItem.menu.delegate = menuDelegate;
        }
    });
}
