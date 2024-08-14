package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

public class MacKeychainTest {

	private final MacKeychain keychain = new MacKeychain();

	@Nested
	public class WithStoredPassword {

		private final String storedPw = "h€llo wørld123";

		@BeforeEach
		public void setup() throws KeychainAccessException {
			keychain.storePassword("service", "account", storedPw, false);
		}

		@Test
		public void testLoadWithInvalidAccount() {
			char[] loadedPw = keychain.loadPassword("service", "wrong");
			Assertions.assertNull(loadedPw);
		}

		@Test
		public void testLoadWithInvalidService() {
			char[] loadedPw = keychain.loadPassword("wrong", "account");
			Assertions.assertNull(loadedPw);
		}

		@Test
		public void testLoad() {
			char[] loadedPw = keychain.loadPassword("service", "account");
			Assertions.assertArrayEquals(storedPw.toCharArray(), loadedPw);
		}

		@Test
		public void testDelete() {
			Assertions.assertDoesNotThrow(() -> keychain.deletePassword("service", "account"));
			char[] deletedPw = keychain.loadPassword("service", "account");
			Assertions.assertNull(deletedPw);
		}
	}

}