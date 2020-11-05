package org.cryptomator.macos.uiappearance;

import org.cryptomator.macos.common.NativeLibLoader;

class AppAppearance {

	void setToAqua() {
		Native.INSTANCE.setToAqua();
	}

	void setToDarkAqua() {
		Native.INSTANCE.setToDarkAqua();
	}

	private static class Native {
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}
		
		public native void setToAqua();

		public native void setToDarkAqua();
	}
}
