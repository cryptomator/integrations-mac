package org.cryptomator.macos.tray;

import org.cryptomator.macos.common.NativeLibLoader;

class DockTileIcon {

	static void applyDefaultIconIfPossible(String resourceName, String resourceType) {
		Native.INSTANCE.applyDefaultIcon(resourceName, resourceType);
	}

	private static class Native {
		private static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		native boolean applyDefaultIcon(String resourceName, String resourceType);
	}

}
