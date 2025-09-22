package org.cryptomator.macos.tray;

import org.cryptomator.macos.common.NativeLibLoader;

class DockTileIcon {

	static void applyIcon(String resourceName, String resourceType) {
		Native.INSTANCE.applyIcon(resourceName, resourceType);
	}

	private static class Native {
		private static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		native boolean applyIcon(String resourceName, String resourceType);
	}

}
