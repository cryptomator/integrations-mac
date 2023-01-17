package org.cryptomator.macos.revealpath;

import org.cryptomator.integrations.revealpath.RevealFailedException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Path;

@Disabled
public class OpenCmdRevealPathServiceTest {

	@TempDir
	Path tmpDir;

	OpenCmdRevealPathService inTest = new OpenCmdRevealPathService();

	@Test
	public void testRevealSuccess() {
		Assertions.assertDoesNotThrow(() -> inTest.reveal(tmpDir));
	}

	@Test
	public void testRevealFail() {
		Assertions.assertThrows(RevealFailedException.class, () -> inTest.reveal(tmpDir.resolve("foobar")));
	}
}
