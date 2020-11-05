package org.cryptomator.macos.uiappearance;

import org.cryptomator.integrations.uiappearance.Theme;
import org.cryptomator.integrations.uiappearance.UiAppearanceException;
import org.cryptomator.integrations.uiappearance.UiAppearanceListener;
import org.cryptomator.integrations.uiappearance.UiAppearanceProvider;

import java.util.HashMap;
import java.util.Map;

public class MacUiAppearanceProvider implements UiAppearanceProvider {

	private final MacSystemAppearance systemAppearance;
	private final AppAppearance appAppearance;
	private final Map<UiAppearanceListener, Long> registeredObservers;

	public MacUiAppearanceProvider() {
		this.systemAppearance = new MacSystemAppearance();
		this.appAppearance = new AppAppearance();
		this.registeredObservers = new HashMap<>();
	}

	@Override
	public Theme getSystemTheme() {
		return systemAppearance.getCurrentInterfaceStyle().equals("Dark") ? Theme.DARK : Theme.LIGHT;
	}

	@Override
	public void adjustToTheme(Theme theme) {
		switch (theme) {
			case LIGHT:
				appAppearance.setToAqua();
				break;
			case DARK:
				appAppearance.setToDarkAqua();
				break;
		}
	}

	@Override
	public void addListener(UiAppearanceListener listener) throws UiAppearanceException {
		var observer = systemAppearance.registerObserverWithListener(() -> {
			listener.systemAppearanceChanged(getSystemTheme());
		});
		if (observer == 0) {
			throw new UiAppearanceException("Failed to register system appearance observer.");
		} else {
			registeredObservers.put(listener, observer);
		}
	}

	@Override
	public void removeListener(UiAppearanceListener listener) throws UiAppearanceException {
		var observer = registeredObservers.remove(listener);
		if (observer != null) {
			systemAppearance.deregisterObserver(observer);
		}
	}

}
