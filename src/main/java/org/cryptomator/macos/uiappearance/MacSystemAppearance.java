package org.cryptomator.macos.uiappearance;

import org.cryptomator.macos.common.NativeLibLoader;

class MacSystemAppearance {

	public String getCurrentInterfaceStyle() {
		return Native.INSTANCE.getCurrentInterfaceStyle();
	}

	/**
	 * @param listener
	 * @return 0 in case of errors or a pointer to the observer
	 */
	long registerObserverWithListener(MacSystemAppearanceListener listener) {
		return Native.INSTANCE.registerObserverWithListener(listener);
	}

	void deregisterObserver(long observer) {
		Native.INSTANCE.deregisterObserver(observer);
	}

	private static class Native {
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		public native String getCurrentInterfaceStyle();

		public native long registerObserverWithListener(MacSystemAppearanceListener listener);

		public native void deregisterObserver(long observer);
	}

}
