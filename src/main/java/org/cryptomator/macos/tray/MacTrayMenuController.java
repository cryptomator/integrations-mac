package org.cryptomator.macos.tray;

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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;

@Priority(1000)
@OperatingSystem(OperatingSystem.Value.MAC)
public class MacTrayMenuController implements TrayMenuController {

	private static final Logger LOG = LoggerFactory.getLogger(MacTrayMenuController.class);

	private volatile boolean iconShown;

	/**
	 * {@inheritDoc}
	 * <p>
	 * {@code defaultAction} is ignored, since clicking a macOS status item always opens its menu.
	 */
	@Override
	public void showTrayIcon(Consumer<TrayIconLoader> iconLoader, Runnable defaultAction, String tooltip) throws TrayMenuException {
		byte[] png = loadPng(iconLoader);
		if (png == null) {
			throw new TrayMenuException("Icon loader did not provide PNG data");
		}
		if (!Native.INSTANCE.showTrayIcon(png, tooltip)) {
			throw new TrayMenuException("Failed to add icon to status bar");
		}
		iconShown = true;
	}

	@Override
	public void updateTrayIcon(Consumer<TrayIconLoader> iconLoader) {
		if (!iconShown) {
			throw new IllegalStateException("Failed to update the icon as it has not yet been added");
		}
		byte[] png = loadPng(iconLoader);
		if (png == null || !Native.INSTANCE.updateTrayIcon(png)) {
			LOG.warn("Failed to update tray icon, keeping the previous one");
		}
	}

	@Override
	public void updateTrayMenu(List<TrayMenuItem> items) {
		// Rebuilding within a single main thread hop keeps concurrent rebuilds and
		// menu tracking from interleaving with a half-built menu.
		runOnMainThread(() -> {
			Native.INSTANCE.clearMenu();
			buildMenu(Native.ROOT_MENU, items);
		});
	}

	@Override
	public void onBeforeOpenMenu(Runnable listener) {
		if (!iconShown) {
			throw new IllegalStateException("Failed to add listener as there is no tray menu");
		}
		Native.INSTANCE.setBeforeOpenMenuListener(logExceptions(listener));
	}

	private static byte[] loadPng(Consumer<TrayIconLoader> iconLoader) {
		var png = new AtomicReference<byte[]>();
		iconLoader.accept((TrayIconLoader.PngData) png::set);
		return png.get();
	}

	private static void buildMenu(long menuHandle, List<TrayMenuItem> items) {
		for (var item : items) {
			switch (item) {
				case ActionItem a -> Native.INSTANCE.addActionItem(menuHandle, a.title(), a.enabled(), a.action() == null ? null : logExceptions(a.action()));
				case SeparatorItem ignored -> Native.INSTANCE.addSeparator(menuHandle);
				case SubMenuItem s -> {
					long submenuHandle = Native.INSTANCE.addSubMenuItem(menuHandle, s.title());
					buildMenu(submenuHandle, s.items());
				}
			}
		}
	}

	private static void runOnMainThread(Runnable task) {
		var failure = new AtomicReference<RuntimeException>();
		Native.INSTANCE.runOnMainThread(() -> {
			try {
				task.run();
			} catch (RuntimeException e) {
				failure.set(e);
			}
		});
		if (failure.get() != null) {
			throw failure.get();
		}
	}

	private static Runnable logExceptions(Runnable callback) {
		return () -> {
			try {
				callback.run();
			} catch (RuntimeException e) {
				LOG.error("Tray menu callback failed", e);
			}
		};
	}

	private static final class Native {

		static final long ROOT_MENU = 0L;
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		native void runOnMainThread(Runnable task);

		native boolean showTrayIcon(byte[] pngData, String tooltip);

		native boolean updateTrayIcon(byte[] pngData);

		native void clearMenu();

		native void addActionItem(long menuHandle, String title, boolean enabled, Runnable action);

		native void addSeparator(long menuHandle);

		native long addSubMenuItem(long menuHandle, String title);

		native void setBeforeOpenMenuListener(Runnable listener);
	}
}
