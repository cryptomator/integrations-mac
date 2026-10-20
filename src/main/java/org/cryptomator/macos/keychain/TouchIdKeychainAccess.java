package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.common.LocalizedDisplayName;
import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;

import java.nio.CharBuffer;
import java.util.Arrays;

/**
 * Stores passwords in the macOS system keychain, requiring an authenticated user to load them.
 * Authentication is done via TouchID or password as a fallback, when TouchID is not available.
 * <p>
 * Items are stored in the data protection keychain with the service name <code>Cryptomator</code>, unless configured otherwise
 * using the system property <code>cryptomator.integrationsMac.keychainServiceName</code>.
 */
@Priority(1010)
@OperatingSystem(OperatingSystem.Value.MAC)
@LocalizedDisplayName(bundle = "MacIntegrationsBundle", key = "org.cryptomator.macos.keychain.touchIdDisplayName")
public class TouchIdKeychainAccess implements KeychainAccessProvider {

	private static final String SERVICE_NAME = System.getProperty("cryptomator.integrationsMac.keychainServiceName", "Cryptomator");

	private final MacKeychain keychain;

	public TouchIdKeychainAccess() {
		this(new MacKeychain());
	}

	// visible for testing
	TouchIdKeychainAccess(MacKeychain keychain) {
		this.keychain = keychain;
	}

	@Override
	public void storePassphrase(String key, String displayName, CharSequence passphrase) throws KeychainAccessException {
		keychain.storePassword(SERVICE_NAME, key, passphrase, true);
	}

	@Override
	public char[] loadPassphrase(String key) throws KeychainAccessException {
		var password = keychain.loadPassword(SERVICE_NAME, key);
		if (password == null) {
			return null;
		} else if (password.requiresOsAuthentication()) {
			return password.value();
		}
		// the entry was stored without user presence (e.g. by MacSystemKeychainAccess): protect it, then load it again through the authenticated path
		try {
			keychain.storePassword(SERVICE_NAME, key, CharBuffer.wrap(password.value()), true);
		} finally {
			Arrays.fill(password.value(), '\0');
		}
		var protectedPassword = keychain.loadPassword(SERVICE_NAME, key);
		if (protectedPassword == null || !protectedPassword.requiresOsAuthentication()) {
			if (protectedPassword != null) {
				Arrays.fill(protectedPassword.value(), '\0');
			}
			throw new KeychainAccessException("Failed to protect stored passphrase with user presence");
		}
		return protectedPassword.value();
	}

	@Override
	public boolean isSupported() {
		return keychain.isTouchIDavailable();
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
			keychain.storePassword(SERVICE_NAME, key, passphrase, true);
		}
	}

}
