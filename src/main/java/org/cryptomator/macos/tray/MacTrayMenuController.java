package org.cryptomator.macos.tray;

import org.cryptomator.integrations.common.CheckAvailability;
import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.tray.ActionItem;
import org.cryptomator.integrations.tray.SeparatorItem;
import org.cryptomator.integrations.tray.SubMenuItem;
import org.cryptomator.integrations.tray.TrayIconLoader;
import org.cryptomator.integrations.tray.TrayMenuController;
import org.cryptomator.integrations.tray.TrayMenuException;
import org.cryptomator.integrations.tray.TrayMenuItem;
import org.cryptomator.macos.common.NativeLibLoader;

import java.util.List;
import java.util.function.Consumer;

@Priority(1000)
@OperatingSystem(OperatingSystem.Value.MAC)
@CheckAvailability
public class MacTrayMenuController implements TrayMenuController {

	@CheckAvailability
	public static boolean isAvailable() {
		return MacTrayMenuController.class.getResource("/libIntegrations.dylib") != null;
	}

	@Override
	public void showTrayIcon(Consumer<TrayIconLoader> iconLoader, Runnable defaultAction, String tooltip) throws TrayMenuException {
		Native.INSTANCE.showTrayIcon(loadPng(iconLoader), tooltip, defaultAction);
	}

	@Override
	public void updateTrayIcon(Consumer<TrayIconLoader> iconLoader) {
		Native.INSTANCE.updateTrayIcon(loadPng(iconLoader));
	}

	@Override
	public void updateTrayMenu(List<TrayMenuItem> items) {
		Native.INSTANCE.clearMenu();
		buildMenu(Native.ROOT_MENU, items);
	}

	@Override
	public void onBeforeOpenMenu(Runnable listener) {
		Native.INSTANCE.setBeforeOpenMenuListener(listener);
	}

	private static byte[] loadPng(Consumer<TrayIconLoader> iconLoader) {
		byte[][] holder = {null};
		iconLoader.accept((TrayIconLoader.PngData) data -> holder[0] = data);
		if (holder[0] == null) {
			throw new IllegalStateException("Icon loader did not provide PNG data");
		}
		return holder[0];
	}

	private void buildMenu(long menuHandle, List<TrayMenuItem> items) {
		for (var item : items) {
			switch (item) {
				case ActionItem a -> Native.INSTANCE.addActionItem(menuHandle, a.title(), a.enabled(), a.action());
				case SeparatorItem ignored -> Native.INSTANCE.addSeparator(menuHandle);
				case SubMenuItem s -> {
					long submenuHandle = Native.INSTANCE.addSubMenuItem(menuHandle, s.title());
					buildMenu(submenuHandle, s.items());
				}
			}
		}
	}

	private static final class Native {

		static final long ROOT_MENU = 0L;
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		native void showTrayIcon(byte[] pngData, String tooltip, Runnable defaultAction);

		native void updateTrayIcon(byte[] pngData);

		native void clearMenu();

		native void addActionItem(long menuHandle, String title, boolean enabled, Runnable action);

		native void addSeparator(long menuHandle);

		native long addSubMenuItem(long menuHandle, String title);

		native void setBeforeOpenMenuListener(Runnable listener);
	}
}
