//
//  org_cryptomator_macos_tray_MacTrayMenuController_Native.m
//

#import <AppKit/AppKit.h>
#include <jni.h>

static JavaVM *gJvm = NULL;
static NSStatusItem *gStatusItem = nil;
static NSMenu *gRootMenu = nil;

// NSMenuItem.target is a weak reference, so action handlers are retained here
// for the menu's lifetime and released in clearMenu().
static NSMutableArray *gActionHandlers = nil;

static JNIEnv *getEnv(void) {
    JNIEnv *env = NULL;
    (*gJvm)->AttachCurrentThread(gJvm, (void **)&env, NULL);
    return env;
}

static void callRunnable(JNIEnv *env, jobject runnable) {
    jclass cls = (*env)->FindClass(env, "java/lang/Runnable");
    jmethodID run = (*env)->GetMethodID(env, cls, "run", "()V");
    (*env)->CallVoidMethod(env, runnable, run);
    (*env)->DeleteLocalRef(env, cls);
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
    JNIEnv *env = getEnv();
    _action = (*env)->NewGlobalRef(env, action);
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
@property (nonatomic) jobject beforeOpenListener;
@end

@implementation SKYMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
    if (self.beforeOpenListener != NULL) {
        JNIEnv *env = getEnv();
        callRunnable(env, self.beforeOpenListener);
    }
}

@end

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
    gJvm = jvm;
    gActionHandlers = [NSMutableArray array];
    return JNI_VERSION_1_8;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_showTrayIcon
(JNIEnv *env, jobject obj, jbyteArray pngData, jstring tooltip, jobject defaultAction) {
    jsize len = (*env)->GetArrayLength(env, pngData);
    jbyte *bytes = (*env)->GetByteArrayElements(env, pngData, NULL);
    NSData *imageData = [NSData dataWithBytes:bytes length:len];
    (*env)->ReleaseByteArrayElements(env, pngData, bytes, JNI_ABORT);

    const char *tooltipChars = (*env)->GetStringUTFChars(env, tooltip, NULL);
    NSString *tooltipStr = [NSString stringWithUTF8String:tooltipChars];
    (*env)->ReleaseStringUTFChars(env, tooltip, tooltipChars);

    gMenuDelegate = [[SKYMenuDelegate alloc] init];

    NSImage *image = [[NSImage alloc] initWithData:imageData];
    image.size = NSMakeSize(18, 18);
    image.template = YES;

    gRootMenu = [[NSMenu alloc] init];
    [gRootMenu setAutoenablesItems:NO];
    gRootMenu.delegate = gMenuDelegate;

    gStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    gStatusItem.button.image = image;
    gStatusItem.button.toolTip = tooltipStr;
    gStatusItem.menu = gRootMenu;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_updateTrayIcon
(JNIEnv *env, jobject obj, jbyteArray pngData) {
    jsize len = (*env)->GetArrayLength(env, pngData);
    jbyte *bytes = (*env)->GetByteArrayElements(env, pngData, NULL);
    NSData *imageData = [NSData dataWithBytes:bytes length:len];
    (*env)->ReleaseByteArrayElements(env, pngData, bytes, JNI_ABORT);

    NSImage *image = [[NSImage alloc] initWithData:imageData];
    image.size = NSMakeSize(18, 18);
    image.template = YES;
    gStatusItem.button.image = image;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_clearMenu
(JNIEnv *env, jobject obj) {
    [gRootMenu removeAllItems];
    [gActionHandlers removeAllObjects];
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addActionItem
(JNIEnv *env, jobject obj, jlong menuHandle, jstring title, jboolean enabled, jobject action) {
    const char *titleChars = (*env)->GetStringUTFChars(env, title, NULL);
    NSString *titleStr = [NSString stringWithUTF8String:titleChars];
    (*env)->ReleaseStringUTFChars(env, title, titleChars);

    SKYActionHandler *handler = [[SKYActionHandler alloc] initWithAction:action];
    [gActionHandlers addObject:handler];

    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:titleStr
                                                  action:@selector(fire:)
                                           keyEquivalent:@""];
    item.target = handler;
    item.enabled = (BOOL)enabled;
    [menuFromHandle(menuHandle) addItem:item];
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addSeparator
(JNIEnv *env, jobject obj, jlong menuHandle) {
    [menuFromHandle(menuHandle) addItem:[NSMenuItem separatorItem]];
}

JNIEXPORT jlong JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_addSubMenuItem
(JNIEnv *env, jobject obj, jlong menuHandle, jstring title) {
    const char *titleChars = (*env)->GetStringUTFChars(env, title, NULL);
    NSString *titleStr = [NSString stringWithUTF8String:titleChars];
    (*env)->ReleaseStringUTFChars(env, title, titleChars);

    NSMenu *submenu = [[NSMenu alloc] initWithTitle:titleStr];
    [submenu setAutoenablesItems:NO];
    submenu.delegate = gMenuDelegate;

    NSMenuItem *parentItem = [[NSMenuItem alloc] initWithTitle:titleStr
                                                        action:NULL
                                                 keyEquivalent:@""];
    parentItem.submenu = submenu;
    [menuFromHandle(menuHandle) addItem:parentItem];

    return (jlong)(intptr_t)(__bridge void *)submenu;
}

JNIEXPORT void JNICALL Java_org_cryptomator_macos_tray_MacTrayMenuController_00024Native_setBeforeOpenMenuListener
(JNIEnv *env, jobject obj, jobject listener) {
    if (gMenuDelegate.beforeOpenListener != NULL) {
        (*env)->DeleteGlobalRef(env, gMenuDelegate.beforeOpenListener);
    }
    gMenuDelegate.beforeOpenListener = (*env)->NewGlobalRef(env, listener);
}
