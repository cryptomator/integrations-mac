package org.cryptomator.macos.update;

import org.cryptomator.integrations.common.LocalizedDisplayName;
import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.update.DownloadUpdateInfo;
import org.cryptomator.integrations.update.DownloadUpdateMechanism;
import org.cryptomator.integrations.update.UpdateFailedException;
import org.cryptomator.integrations.update.UpdateMechanism;
import org.cryptomator.integrations.update.UpdateStep;
import org.cryptomator.macos.common.Localization;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InterruptedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.UUID;

@OperatingSystem(OperatingSystem.Value.MAC)
@LocalizedDisplayName(bundle = "MacIntegrationsBundle", key = "org.cryptomator.macos.update.dmg.displayName")
public class DmgUpdateMechanism extends DownloadUpdateMechanism {

	private static final Logger LOG = LoggerFactory.getLogger(DmgUpdateMechanism.class);

	@Override
	protected DownloadUpdateInfo checkForUpdate(String currentVersion, LatestVersionResponse response) {
		String suffix = switch (System.getProperty("os.arch")) {
			case "aarch64", "arm64" -> "arm64.dmg";
			default -> "x64.dmg";
		};
		var updateVersion = response.latestVersion().macVersion();
		var asset = response.assets().stream().filter(a -> a.name().endsWith(suffix)).findAny().orElse(null);
		if (UpdateMechanism.isUpdateAvailable(updateVersion, currentVersion) && asset != null) {
			return new DownloadUpdateInfo(this, updateVersion, asset);
		} else {
			return null;
		}
	}

	@Override
	public UpdateStep secondStep(Path workDir, Path assetPath, DownloadUpdateInfo updateInfo) {
		return UpdateStep.of(Localization.get().getString("org.cryptomator.macos.update.dmg.unpacking"), () -> this.unpack(workDir, assetPath));
	}

	private UpdateStep unpack(Path workDir, Path assetPath) throws IOException {
		// Extract Cryptomator.app from the .dmg file
		String script = """
					hdiutil attach "${DMG_PATH}" -mountpoint "/Volumes/Cryptomator_${MOUNT_ID}" -nobrowse -quiet &&
					cp -R "/Volumes/Cryptomator_${MOUNT_ID}/Cryptomator.app" 'Cryptomator.app' &&
					hdiutil detach "/Volumes/Cryptomator_${MOUNT_ID}" -quiet
					""";
		var command = List.of("/bin/zsh", "-c", script);
		var processBuilder = new ProcessBuilder(command);
		processBuilder.directory(workDir.toFile());
		processBuilder.environment().put("DMG_PATH", assetPath.toString());
		processBuilder.environment().put("MOUNT_ID", UUID.randomUUID().toString());
		Process p = processBuilder.start();
		try {
			if (p.waitFor() != 0) {
				LOG.error("Failed to extract DMG, exit code: {}, output: {}", p.exitValue(), new String(p.getErrorStream().readAllBytes()));
				throw new IOException("Failed to extract DMG, exit code: " + p.exitValue());
			}
			LOG.debug("Update ready: {}", workDir.resolve("Cryptomator.app"));
		} catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			throw new InterruptedIOException("Failed to extract DMG, interrupted");
		}
		return UpdateStep.of(Localization.get().getString("org.cryptomator.macos.update.dmg.restarting"), () -> this.restart(workDir));
	}

	public UpdateStep restart(Path workDir) throws IllegalStateException, IOException {
		String selfPath = ProcessHandle.current().info().command().orElse("");
		String installPath;
		if (selfPath.startsWith("/Applications/Cryptomator.app")) {
			installPath = "/Applications/Cryptomator.app";
		} else if (selfPath.contains("/Cryptomator.app/")) {
			installPath = selfPath.substring(0, selfPath.indexOf("/Cryptomator.app/")) + "/Cryptomator.app";
		} else {
			throw new UpdateFailedException("Cannot determine destination path for Cryptomator.app, current path: " + selfPath);
		}
		LOG.info("Restarting to apply Update in {} now...", workDir);
		String script = """
					while kill -0 ${CRYPTOMATOR_PID} 2> /dev/null; do sleep 0.2; done;
					if [ -d "${CRYPTOMATOR_INSTALL_PATH}" ]; then
					  echo "Removing old installation at ${CRYPTOMATOR_INSTALL_PATH}";
					  rm -rf "${CRYPTOMATOR_INSTALL_PATH}"
					fi
					mv 'Cryptomator.app' "${CRYPTOMATOR_INSTALL_PATH}";
					open -a "${CRYPTOMATOR_INSTALL_PATH}";
					""";
		Files.writeString(workDir.resolve("install.sh"), script, StandardCharsets.US_ASCII, StandardOpenOption.WRITE, StandardOpenOption.CREATE_NEW);
		var command = List.of("/bin/zsh", "-c", "/usr/bin/nohup zsh install.sh >install.log 2>&1 &");
		var processBuilder = new ProcessBuilder(command);
		processBuilder.directory(workDir.toFile());
		processBuilder.environment().put("CRYPTOMATOR_PID", String.valueOf(ProcessHandle.current().pid()));
		processBuilder.environment().put("CRYPTOMATOR_INSTALL_PATH", installPath);
		processBuilder.start();

		return UpdateStep.EXIT;
	}

}