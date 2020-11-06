package org.cryptomator.macos.tray;

import org.cryptomator.macos.common.NativeLibLoader;

class ActivationPolicy {

	/**
	 * Sets the application's activation policy to <a href="https://developer.apple.com/documentation/appkit/nsapplicationactivationpolicy/nsapplicationactivationpolicyaccessory?language=objc">NSApplicationActivationPolicyAccessory</a>
	 */
	void transformToAccessory() {
		Native.INSTANCE.transformToAccessory();
	}

	/**
	 * Requests to focus the current app and sets its activation policy to <a href="https://developer.apple.com/documentation/appkit/nsapplicationactivationpolicy/nsapplicationactivationpolicyregular?language=objc">NSApplicationActivationPolicyRegular</a>
	 */
	void transformToRegular() {
		Native.INSTANCE.transformToRegular();
	}

	private static class Native {
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		public native void transformToAccessory();

		public native void transformToRegular();
	}
}
