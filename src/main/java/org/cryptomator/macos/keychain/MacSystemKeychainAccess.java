package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.cryptomator.macos.common.Localization;

public class MacSystemKeychainAccess implements KeychainAccessProvider {

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
	public void storePassphrase(String key, CharSequence passphrase) throws KeychainAccessException {
		keychain.storePassword(key, passphrase);
	}

	@Override
	public char[] loadPassphrase(String key) {
		return keychain.loadPassword(key);
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
		keychain.deletePassword(key);
	}

	@Override
	public void changePassphrase(String key, CharSequence passphrase) throws KeychainAccessException {
		if (keychain.deletePassword(key)) {
			keychain.storePassword(key, passphrase);
		}
	}

}
