import org.cryptomator.integrations.autostart.AutoStartProvider;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.cryptomator.integrations.tray.TrayIntegrationProvider;
import org.cryptomator.integrations.uiappearance.UiAppearanceProvider;
import org.cryptomator.macos.autostart.MacAutoStartProvider;
import org.cryptomator.macos.keychain.MacSystemKeychainAccess;
import org.cryptomator.macos.tray.MacTrayIntegrationProvider;
import org.cryptomator.macos.uiappearance.MacUiAppearanceProvider;

module org.cryptomator.integrations.mac {
	requires org.cryptomator.integrations.api;
	requires org.slf4j;

	provides AutoStartProvider with MacAutoStartProvider;
	provides KeychainAccessProvider with MacSystemKeychainAccess;
	provides TrayIntegrationProvider with MacTrayIntegrationProvider;
	provides UiAppearanceProvider with MacUiAppearanceProvider;
}