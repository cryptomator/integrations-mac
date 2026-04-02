package org.cryptomator.macos.tray;

import org.cryptomator.integrations.common.CheckAvailability;
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
import java.util.function.Consumer;

@CheckAvailability
@Priority(2000) // gewinnt gegen AwtTrayMenuController (FALLBACK)
public class MacTrayMenuController implements TrayMenuController {

	private static final Logger LOG = LoggerFactory.getLogger(MacTrayMenuController.class);

	static {
		// genauso wie bei MacLaunchServices/MacSystemAppearance:
		NativeLibLoader.loadLib(); // lädt die bestehende Mac-Integrations-dylib
	}

	@CheckAvailability
	public static boolean isAvailable() {
		NativeLibLoader.loadLib();
		return NativeLibLoader.isLoaded();
	}

	@Override
	public void showTrayIcon(Consumer<TrayIconLoader> iconLoader, Runnable defaultAction, String tooltip) throws TrayMenuException {
		TrayIconLoader.PngData cb = pngData -> nativeShowTrayIcon(pngData, tooltip, defaultAction);
		iconLoader.accept(cb);
	}

	@Override
	public void updateTrayIcon(Consumer<TrayIconLoader> iconLoader) {
		TrayIconLoader.PngData cb = MacTrayMenuController::nativeUpdateTrayIcon;
		iconLoader.accept(cb);
	}

	@Override
	public void updateTrayMenu(List<TrayMenuItem> items) {
		NativeMenu nativeMenu = NativeMenu.from(items);
		nativeUpdateTrayMenu(nativeMenu);
	}

	@Override
	public void onBeforeOpenMenu(Runnable listener) {
		nativeSetBeforeOpenCallback(listener);
	}

	// --- DTO für JNI, möglichst simpel halten ---

	public static final class NativeMenu {

		public final List<NativeMenuItem> items;

		public NativeMenu(List<NativeMenuItem> items) {
			this.items = items;
		}

		public static NativeMenu from(List<TrayMenuItem> items) {
			return new NativeMenu(items.stream().map(NativeMenuItem::from).toList());
		}
	}

	public static sealed class NativeMenuItem permits NativeActionItem, NativeSeparatorItem, NativeSubMenuItem {
		public static NativeMenuItem from(TrayMenuItem item) {
			return switch (item) {
				case ActionItem a -> new NativeActionItem(a.title(), a.enabled(), a.action());
				case SeparatorItem s -> new NativeSeparatorItem();
				case SubMenuItem s -> new NativeSubMenuItem(s.title(), NativeMenu.from(s.items()));
			};
		}
	}

	public static final class NativeActionItem extends NativeMenuItem {
		public final String title;
		public final boolean enabled;
		public final Runnable action;

		public NativeActionItem(String title, boolean enabled, Runnable action) {
			this.title = title;
			this.enabled = enabled;
			this.action = action;
		}
	}

	public static final class NativeSeparatorItem extends NativeMenuItem {
	}

	public static final class NativeSubMenuItem extends NativeMenuItem {
		public final String title;
		public final NativeMenu submenu;

		public NativeSubMenuItem(String title, NativeMenu submenu) {
			this.title = title;
			this.submenu = submenu;
		}
	}

	// --- native Methoden ---

	private static native void nativeShowTrayIcon(byte[] pngData, String tooltip, Runnable defaultAction);

	private static native void nativeUpdateTrayIcon(byte[] pngData);

	private static native void nativeUpdateTrayMenu(NativeMenu menu);

	private static native void nativeSetBeforeOpenCallback(Runnable callback);
}
