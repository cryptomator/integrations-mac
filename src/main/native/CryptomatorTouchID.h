//
//  CryptomatorTouchID.h
//  CryptomatorTouchID
//
//  Created by Ralph Plawetzki on 27.01.24.
//

#import <Foundation/Foundation.h>

typedef void (*auth_cb_t)(int32_t success, int32_t laError);

#ifdef __cplusplus
extern "C" {
#endif

int32_t touchid_supported(void);

void touchid_authenticate(const char* msg, auth_cb_t callback);

#ifdef __cplusplus
}
#endif
