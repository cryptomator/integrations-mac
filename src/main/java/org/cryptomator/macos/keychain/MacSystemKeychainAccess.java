package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.cryptomator.macos.common.Localization;

/**
 * Stores passwords in the macOS system keychain.
 * <p>
 * Items are stored in the default keychain with the service name <code>Cryptomator</code>, unless configured otherwise
 * using the system property <code>cryptomator.integrationsMac.keychainServiceName</code>.
 */
@Priority(1000)
@OperatingSystem(OperatingSystem.Value.MAC)
public class MacSystemKeychainAccess implements KeychainAccessProvider {

	private static final String SERVICE_NAME = System.getProperty("cryptomator.integrationsMac.keychainServiceName", "Cryptomator");

	private final MacKeychain keychain;

	public MacSystemKeychainAccess() {
		this(new MacKeychain());
	}

	// visible for testing
	MacSystemKeychainAccess(MacKeychain keychain) {
		this.keychain = keychain;
	}

	@Override
	public String displayName() {
		return Localization.get().getString("org.cryptomator.macos.keychain.displayName");
	}

	@Override
	public void storePassphrase(String key, String displayName, CharSequence passphrase) throws KeychainAccessException {
		keychain.storePassword(SERVICE_NAME, key, passphrase, false);
	}

	@Override
	public void storePassphrase(String key, String displayName, CharSequence passphrase, boolean requireOsAuthentication) throws KeychainAccessException {
		keychain.storePassword(SERVICE_NAME, key, passphrase, requireOsAuthentication);
	}

	@Override
	public char[] loadPassphrase(String key) {
		return keychain.loadPassword(SERVICE_NAME, key);
	}

	@Override
	public boolean isSupported() {
		return true;
	}

	@Override
	public boolean isLocked() {
		return false;
	}

	@Override
	public void deletePassphrase(String key) throws KeychainAccessException {
		keychain.deletePassword(SERVICE_NAME, key);
	}

	@Override
	public void changePassphrase(String key, String displayName, CharSequence passphrase) throws KeychainAccessException {
		if (keychain.deletePassword(SERVICE_NAME, key)) {
			keychain.storePassword(SERVICE_NAME, key, passphrase, false);
		}
	}

}
