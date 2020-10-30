package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

public class MacKeychainTest {

	@Test
	public void testKeychainAccess() throws KeychainAccessException {
		MacKeychain keychain = new MacKeychain();

		String storedPw = "h€llo wørld123";
		keychain.storePassword("foo", storedPw);
		char[] loadedPw2 = keychain.loadPassword("bar");
		Assertions.assertNull(loadedPw2);

		char[] loadedPw = keychain.loadPassword("foo");
		Assertions.assertArrayEquals(storedPw.toCharArray(), loadedPw);

		keychain.deletePassword("foo");
		char[] deletedPw = keychain.loadPassword("foo");
		Assertions.assertNull(deletedPw);
	}

}