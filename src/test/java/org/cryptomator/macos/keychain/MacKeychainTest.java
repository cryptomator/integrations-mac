package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

public class MacKeychainTest {

	private final MacKeychain keychain = new MacKeychain();

	@Test
	@DisplayName("OS authentication is unsupported without keychain-access-groups entitlement, as in this test JVM")
	public void testOsAuthenticationWithoutEntitlement() {
		Assertions.assertFalse(keychain.isOsAuthenticationAvailable());
	}

	@Test
	public void testLoadResultNotFound() throws KeychainAccessException {
		Assertions.assertNull(MacKeychain.toStoredPassword(new MacKeychain.LoadResult(-25300, null, false)));
	}

	@Test
	public void testLoadResultError() {
		Assertions.assertThrows(KeychainAccessException.class, () -> MacKeychain.toStoredPassword(new MacKeychain.LoadResult(-128, null, false)));
	}

	@Test
	public void testLoadResultWithoutPassword() {
		Assertions.assertThrows(KeychainAccessException.class, () -> MacKeychain.toStoredPassword(new MacKeychain.LoadResult(0, null, false)));
	}

	@Test
	public void testLoadResultProtected() throws KeychainAccessException {
		var loadedPw = MacKeychain.toStoredPassword(new MacKeychain.LoadResult(0, "pw".getBytes(StandardCharsets.UTF_8), true));
		Assertions.assertArrayEquals("pw".toCharArray(), loadedPw.value());
		Assertions.assertTrue(loadedPw.requiresOsAuthentication());
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
			var loadedPw = keychain.loadPassword("service", "wrong");
			Assertions.assertNull(loadedPw);
		}

		@Test
		public void testLoadWithInvalidService() throws KeychainAccessException {
			var loadedPw = keychain.loadPassword("wrong", "account");
			Assertions.assertNull(loadedPw);
		}

		@Test
		public void testLoad() throws KeychainAccessException {
			var loadedPw = keychain.loadPassword("service", "account");
			Assertions.assertArrayEquals(storedPw.toCharArray(), loadedPw.value());
			Assertions.assertFalse(loadedPw.requiresOsAuthentication());
		}

		@Test
		public void testOverwrite() throws KeychainAccessException {
			keychain.storePassword("service", "account", "0ther pw", false);
			var loadedPw = keychain.loadPassword("service", "account");
			Assertions.assertArrayEquals("0ther pw".toCharArray(), loadedPw.value());
		}

		@Test
		@DisplayName("protecting fails without keychain-access-groups entitlement, as in this test JVM, but keeps the stored password")
		public void testProtectWithoutEntitlement() throws KeychainAccessException {
			Assertions.assertThrows(KeychainAccessException.class, () -> keychain.storePassword("service", "account", "0ther pw", true));
			var loadedPw = keychain.loadPassword("service", "account");
			Assertions.assertArrayEquals(storedPw.toCharArray(), loadedPw.value());
			Assertions.assertFalse(loadedPw.requiresOsAuthentication());
		}

		@Test
		public void testDelete() throws KeychainAccessException {
			Assertions.assertDoesNotThrow(() -> keychain.deletePassword("service", "account"));
			var deletedPw = keychain.loadPassword("service", "account");
			Assertions.assertNull(deletedPw);
		}
	}

}