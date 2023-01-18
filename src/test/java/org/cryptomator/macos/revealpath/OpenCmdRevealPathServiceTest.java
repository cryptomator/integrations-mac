package org.cryptomator.macos.revealpath;

import org.cryptomator.integrations.revealpath.RevealFailedException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Disabled
public class OpenCmdRevealPathServiceTest {

	@TempDir
	Path tmpDir;

	OpenCmdRevealPathService inTest = new OpenCmdRevealPathService();

	@Test
	public void testRevealDirSuccess() {
		Assertions.assertDoesNotThrow(() -> inTest.reveal(tmpDir));
	}

	@Test
	public void testRevealFileSuccess() throws IOException {
		var path = tmpDir.resolve("foobar.text");
		Files.createFile(path);
		Assertions.assertDoesNotThrow(() -> inTest.reveal(path));
	}

	@Test
	public void testRevealFail() {
		Assertions.assertThrows(RevealFailedException.class, () -> inTest.reveal(tmpDir.resolve("foobar")));
	}

}
