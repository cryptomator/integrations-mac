package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

public class MacKeychainTest {

	private final MacKeychain keychain = new MacKeychain();

	@Test
	public void testLoadResultNotFound() throws KeychainAccessException {
		Assertions.assertNull(MacKeychain.toPassword(new MacKeychain.LoadResult(-25300, null)));
	}

	@Test
	public void testLoadResultError() {
		Assertions.assertThrows(KeychainAccessException.class, () -> MacKeychain.toPassword(new MacKeychain.LoadResult(-128, null)));
	}

	@Test
	public void testLoadResultWithoutPassword() {
		Assertions.assertThrows(KeychainAccessException.class, () -> MacKeychain.toPassword(new MacKeychain.LoadResult(0, null)));
	}

	@Nested
	public class WithStoredPassword {

		private final String storedPw = "h€llo wørld123";

		@BeforeEach
		public void setup() throws KeychainAccessException {
			keychain.storePassword("service", "account", storedPw, false);
		}

		@Test
		public void testLoadWithInvalidAccount() throws KeychainAccessException {
			char[] loadedPw = keychain.loadPassword("service", "wrong");
			Assertions.assertNull(loadedPw);
		}

		@Test
		public void testLoadWithInvalidService() throws KeychainAccessException {
			char[] loadedPw = keychain.loadPassword("wrong", "account");
			Assertions.assertNull(loadedPw);
		}

		@Test
		public void testLoad() throws KeychainAccessException {
			char[] loadedPw = keychain.loadPassword("service", "account");
			Assertions.assertArrayEquals(storedPw.toCharArray(), loadedPw);
		}

		@Test
		public void testOverwrite() throws KeychainAccessException {
			keychain.storePassword("service", "account", "0ther pw", false);
			char[] loadedPw = keychain.loadPassword("service", "account");
			Assertions.assertArrayEquals("0ther pw".toCharArray(), loadedPw);
		}

		@Test
		public void testDelete() throws KeychainAccessException {
			Assertions.assertDoesNotThrow(() -> keychain.deletePassword("service", "account"));
			char[] deletedPw = keychain.loadPassword("service", "account");
			Assertions.assertNull(deletedPw);
		}
	}

}
