package org.cryptomator.macos.secondfactor;

import com.sun.jna.Callback;
import com.sun.jna.Library;

public interface CryptomatorTouchID extends Library {

	interface AuthCallback extends Callback {

		void callback(int result, int laError);
	}

	int touchid_supported();

	void touchid_authenticate(String message, AuthCallback callback);
}
