package org.cryptomator.macos.autostart;

import org.cryptomator.macos.common.NativeLibLoader;

class MacLaunchServices {

	/**
	 * Check if login item is currently enabled.
	 *
	 * @return <code>true</code> if login item is currently enabled, <code>false</code> otherwise.
	 */
	public boolean isLoginItemEnabled() {
		return Native.INSTANCE.isLoginItemEnabled();
	}

	/**
	 * Enable login item. If it is already enabled, nothing happens and it will be handled as successful.
	 *
	 * @return <code>true</code> if enabling login item was successful, <code>false</code> otherwise.
	 */
	public boolean enableLoginItem() {
		return Native.INSTANCE.enableLoginItem();
	}

	/**
	 * Disable login item. If it is already disabled, nothing happens and it will be handled as successful.
	 *
	 * @return <code>true</code> if disabling login item was successful, <code>false</code> otherwise.
	 */
	public boolean disableLoginItem() {
		return Native.INSTANCE.disableLoginItem();
	}

	private static class Native {
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		public native boolean isLoginItemEnabled();

		public native boolean enableLoginItem();

		public native boolean disableLoginItem();
	}

}
