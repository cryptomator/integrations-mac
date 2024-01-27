package org.cryptomator.macos.secondfactor;

import com.sun.jna.Callback;
import com.sun.jna.Native;
import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.secondfactor.SecondFactorProvider;

@Priority(1000)
@OperatingSystem(OperatingSystem.Value.MAC)
public class MacTouchIDProvider implements SecondFactorProvider {

	private static final CryptomatorTouchID NATIVELIB;

	static {
		NATIVELIB = Native.load("CryptomatorTouchID", CryptomatorTouchID.class);
	}

	@Override
	public boolean device_supported() {
		return NATIVELIB.touchid_supported() == 1;
	}

	@Override
	public void device_authenticate(String message, Callback callback) {
		if (callback instanceof CryptomatorTouchID.AuthCallback) {
			NATIVELIB.touchid_authenticate(message, (CryptomatorTouchID.AuthCallback) callback);
		}
	}
}
