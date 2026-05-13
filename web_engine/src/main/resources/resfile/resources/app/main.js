let path = require('path');
let util = require('util');
let os = require('os');
let crypto = require('crypto');
let fs = require('fs');
let zlib = require('zlib');
let EventEmitter = require('events');
let electron = require('electron');
electron.remote = require('@electron/remote/main');
let {app, protocol, net, remote} = electron;

remote.initialize();

protocol.registerSchemesAsPrivileged([
	{scheme: 'app', privileges: {standard: true, secure: true, supportFetchAPI: true, stream: true, codeCache: true}}
]);

let updateEvents = new EventEmitter();

let insider = false;
let disable = false;
let silence = false;
updateEvents.on('insider', (arg) => {
	insider = arg;
});
updateEvents.on('disable', (arg) => {
	disable = arg;
});
updateEvents.on('silence', (arg) => {
	silence = arg;
});

let APP_PATH = (() => {
	let path = app.getAppPath();
	let asar_index = path.indexOf('app.asar');
	if (asar_index >= 0) {
		return path.slice(0, asar_index);
	}
	return path;
})();

let currentBaseVersion = require('./package.json').version || app.getVersion();
let currentPackageVersion = currentBaseVersion;
let dataPath = app.getPath('userData');

function itemExists(filePath) {
	try {
		fs.accessSync(filePath);
		return true;
	} catch (e) {
		return false;
	}
}

function normalizeForPrefix(filePath) {
	return path.resolve(filePath).replace(/\\/g, '/');
}

function getVaultTrashDir(targetPath) {
	try {
		let obsidianConfigPath = path.join(dataPath, 'obsidian.json');
		if (fs.existsSync(obsidianConfigPath)) {
			let obsidianConfig = JSON.parse(fs.readFileSync(obsidianConfigPath, 'utf8'));
			let vaults = obsidianConfig && obsidianConfig.vaults;
			if (vaults) {
				let normalizedTarget = normalizeForPrefix(targetPath);
				let matchedVaultPath = null;
				for (let id of Object.keys(vaults)) {
					let vaultPath = vaults[id] && vaults[id].path;
					if (!vaultPath || !fs.existsSync(vaultPath)) continue;
					let normalizedVault = normalizeForPrefix(vaultPath);
					if (normalizedTarget === normalizedVault || normalizedTarget.startsWith(normalizedVault + '/')) {
						if (!matchedVaultPath || normalizedVault.length > normalizeForPrefix(matchedVaultPath).length) {
							matchedVaultPath = vaultPath;
						}
					}
				}
				if (matchedVaultPath) return path.join(matchedVaultPath, '.trash');
			}
		}
		return getVaultTrashDirByFilesystem(targetPath);
	} catch (e) {
		console.error('[HMOS-TRASH] failed to resolve vault trash dir', e);
		return getVaultTrashDirByFilesystem(targetPath);
	}
}

function getVaultTrashDirByFilesystem(targetPath) {
	try {
		let dir = fs.statSync(targetPath).isDirectory() ? targetPath : path.dirname(targetPath);
		while (dir && path.dirname(dir) !== dir) {
			if (fs.existsSync(path.join(dir, '.obsidian'))) {
				return path.join(dir, '.trash');
			}
			dir = path.dirname(dir);
		}
	} catch (e) {
	}
	return path.join(path.dirname(targetPath), '.trash');
}

function moveToVaultTrash(targetPath) {
	let trashDir = getVaultTrashDir(targetPath);
	if (!trashDir) return false;
	fs.mkdirSync(trashDir, {recursive: true});
	let parsed = path.parse(targetPath);
	let targetName = parsed.base;
	let trashPath = path.join(trashDir, targetName);
	if (fs.existsSync(trashPath)) {
		trashPath = path.join(trashDir, parsed.name + '-' + Date.now() + parsed.ext);
	}
	fs.renameSync(targetPath, trashPath);
	console.log('[HMOS-TRASH] moved to vault trash fallback', targetPath, '->', trashPath);
	return true;
}

async function waitForMissing(filePath, timeoutMs) {
	let deadline = Date.now() + timeoutMs;
	while (Date.now() < deadline) {
		if (!itemExists(filePath)) return true;
		await new Promise((resolve) => setTimeout(resolve, 100));
	}
	return !itemExists(filePath);
}

function installHarmonyTrashCompat() {
	if (!electron.shell || typeof electron.shell.trashItem !== 'function') return;
	let nativeTrashItem = electron.shell.trashItem.bind(electron.shell);
	electron.shell.trashItem = async function(targetPath) {
		let existedBefore = itemExists(targetPath);
		try {
			let result = await nativeTrashItem(targetPath);
			if (!existedBefore || await waitForMissing(targetPath, 3000)) {
				console.log('[HMOS-TRASH] native trash succeeded', targetPath);
				return result;
			}
			throw new Error('HarmonyOS native trash returned but the file still exists');
		} catch (e) {
			console.error('[HMOS-TRASH] native trash failed', e);
			if (existedBefore && itemExists(targetPath) && moveToVaultTrash(targetPath)) {
				return;
			}
			throw e;
		}
	};
}

installHarmonyTrashCompat();

async function runHarmonyTrashSelfTest() {
	let obsidianConfigPath = path.join(dataPath, 'obsidian.json');
	let originalConfig = null;
	try {
		await app.whenReady();
		let testRoot = path.join(dataPath, 'harmony-trash-self-test');
		let testVault = path.join(testRoot, 'vault');
		fs.mkdirSync(testVault, {recursive: true});
		fs.mkdirSync(path.join(testVault, '.obsidian'), {recursive: true});
		if (fs.existsSync(obsidianConfigPath)) {
			originalConfig = fs.readFileSync(obsidianConfigPath, 'utf8');
		}
		let config = originalConfig ? JSON.parse(originalConfig) : {};
		config.vaults = config.vaults || {};
		config.vaults['hmos-trash-self-test'] = {path: testVault, ts: Date.now()};
		fs.writeFileSync(obsidianConfigPath, JSON.stringify(config, null, 2), 'utf8');
		let testFile = path.join(testVault, 'delete-me-' + Date.now() + '.md');
		fs.writeFileSync(testFile, 'HarmonyOS trash self test', 'utf8');
		await electron.shell.trashItem(testFile);
		let removed = await waitForMissing(testFile, 3000);
		console.log('[HMOS-TRASH-TEST]', removed ? 'pass' : 'fail', testFile);
	} catch (e) {
		console.error('[HMOS-TRASH-TEST] fail', e);
	} finally {
		try {
			if (originalConfig === null) {
				fs.rmSync(obsidianConfigPath, {force: true});
			} else {
				fs.writeFileSync(obsidianConfigPath, originalConfig, 'utf8');
			}
			fs.rmSync(path.join(dataPath, 'harmony-trash-self-test'), {recursive: true, force: true});
		} catch (e) {
			console.error('[HMOS-TRASH-TEST] cleanup failed', e);
		}
	}
}

if (fs.existsSync(path.join(APP_PATH, 'harmonyos-trash-test.enabled'))) {
	runHarmonyTrashSelfTest();
}

function pad(number) {
	if (number < 10) {
		return '0' + number;
	}
	return number;
}

function stamp() {
	let d = new Date();
	return d.getUTCFullYear() +
		'-' + pad(d.getUTCMonth() + 1) +
		'-' + pad(d.getUTCDate()) +
		' ' + pad(d.getUTCHours()) +
		':' + pad(d.getUTCMinutes()) +
		':' + pad(d.getUTCSeconds());
}

function logger(logfile) {
	let fileout = fs.openSync(logfile, 'a');
	let stdout = process.stdout;

	stdout.on('error', function(e) {
		// `write` failed. Do nothing...
	});

	let fn = function () {
		let data = stamp() + ' ' + util.format.apply(null, arguments) + os.EOL;

		try {
			fs.writeSync(fileout, data);
			// Don't output to stdout if the app requests silence mode (to avoid polluting CLI outputs)
			if (!silence) stdout.write(data);
		}
		catch (e) {
			// Failed to write to log
		}
	};

	fn.end = function () {
		fs.closeSync(fileout);
	};

	return fn;
}

let log = logger(path.join(dataPath, 'obsidian.log'));

let idFile = path.join(dataPath, 'id');
let id;
try {
	if (fs.existsSync(idFile)) {
		id = fs.readFileSync(idFile, 'utf8');
	}
} catch (e) {
}
try {
	if (!id || id.length < 16) {
		id = crypto.randomBytes(16).toString('hex');
		fs.writeFileSync(idFile, id, 'utf8');
	}
} catch (e) {
}

// Only start the updater when electron is ready, because the net module requires that.
let updatePromise = app.whenReady();
let queueUpdate = (manual) => {
	log('HarmonyOS port: desktop auto-update is disabled');
	updateEvents.emit('check-end');
	return;
	let fn = () => update(manual);
	updatePromise = updatePromise.then(fn, fn);
};

// Used for verifying signatures of downloaded asar files
const SIGNATURE_CERT = '-----BEGIN CERTIFICATE-----\n' +
	'MIIDjzCCAnegAwIBAgIJAOFHLJ2gTCBzMA0GCSqGSIb3DQEBCwUAMF4xCzAJBgNV\n' +
	'BAYTAlVTMRMwEQYDVQQIDApTb21lLVN0YXRlMREwDwYDVQQKDAhEeW5hbGlzdDER\n' +
	'MA8GA1UECwwIRHluYWxpc3QxFDASBgNVBAMMC2R5bmFsaXN0LmlvMB4XDTE2MDUx\n' +
	'NjAyMTA1NFoXDTQwMDUxMDAyMTA1NFowXjELMAkGA1UEBhMCVVMxEzARBgNVBAgM\n' +
	'ClNvbWUtU3RhdGUxETAPBgNVBAoMCER5bmFsaXN0MREwDwYDVQQLDAhEeW5hbGlz\n' +
	'dDEUMBIGA1UEAwwLZHluYWxpc3QuaW8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\n' +
	'ggEKAoIBAQDcodSNp30B0oE+2vRUdr//SGfbDow+67OtGuRYQSjn86bn55fQXhMJ\n' +
	'b5xgZ0natiCriCyllLWgPf+4PnxGRSJZGbm38QSArb0MWR8/yXA+q+7nZisIsN2d\n' +
	'Xih8B3APImxJ4A50nsK/C+fl7nYdo04iz3oerP0UhLDrsLbL+9rdmshjB1boLPf6\n' +
	'QpAAC57OTPQpFBd2hFoS6xAnIb708SHOndsrWDIFEFVCPDYcme3WF5jznuT05OFG\n' +
	'MIX8SZe2jXpg2Vco/1oKRPC7mYFN5B0JTZ7mOH48vB/zPNIsVz8KHh3P9Ru2fC2r\n' +
	'3nPDXFGKzcUZneJmXh4LIUVqwdEPw7hvAgMBAAGjUDBOMB0GA1UdDgQWBBTF2xMx\n' +
	'8xVDZ2wteJPsHUe0OCu18TAfBgNVHSMEGDAWgBTF2xMx8xVDZ2wteJPsHUe0OCu1\n' +
	'8TAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQB6rgBF+DvDHifP+U6Z\n' +
	'FqJ4mX1nalEXEPI1jvRZaOheKpkOEBbhkCAosbBEmYxfj8xay1GGgB9nkJk2dodR\n' +
	'sGVhrZz+CwGR+hSEfYDQwMBvmzm3OcETfEtvwEAU1P93prbxul2oSWP48AVDDYKe\n' +
	'pxTZvW/yZcnoHI9XzhLNMYIEvOs+wKWAOF0+BjsIukQouaXs6gklul2J99IqpdPh\n' +
	'w2l4l7mkPx8htCbTE47GTraHt2i2mwyBZSKbfqzi73Fj5SFRtZlWJDNPKoWxcFg2\n' +
	'91B7IHumd5jwAUdVJit3K5Tgt/q4OzwokcDZcrh5lJg0+Kstsz4RDWDbfzTNJuKn\n' +
	'oueR\n' +
	'-----END CERTIFICATE-----';

async function update(manual) {
	if (!manual && disable) {
		return;
	}
	updateEvents.emit('check-start');
	try {
		// Hopefully this can help us catch any updater failures
		// Or any old buggy versions that may still be operating in the wild.
		// Don't wait on the async result
		httpGetBinary('https://releases.obsidian.md/desktop?id=' + id + '&v=' + currentPackageVersion + '&p=' + process.platform).then(() => null, () => null);
	} catch (e) {
	}

	try {
		await runUpdate();
	} catch (e) {
		log('Failed to perform update');
		console.error(e);
	}
	updateEvents.emit('check-end');
}

async function runUpdate() {
	let updateJson = null;

	try {
		log('Checking for update using Github');
		updateJson = JSON.parse(await httpGet('https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json'));
		log('Success.');
	} catch (e) {
		log(`Failed to check for update using Github (${e.message})`);
		console.error(e);
	}

	if (updateJson) {
		try {
			await downloadUpdate(updateJson);
			return;
		} catch (e) {
			if (e.code !== 'ETIMEDOUT') {
				throw e;
			}
			log('Failed to download update from Github');
		}
	}

	try {
		log('Checking for update using obsidian.md');
		updateJson = JSON.parse(await httpGet('https://releases.obsidian.md/desktop-releases.json'));
		log('Success.');
	} catch (e) {
		log(`Failed to check for update using obsidian.md (${e.message})`);
		console.error(e);
	}

	if (updateJson) {
		await downloadUpdate(updateJson);
	}
}

async function downloadUpdate(updateJson) {
	let usingInsider = false;
	if (insider && updateJson.beta) {
		updateJson = updateJson.beta;
		usingInsider = true;
	}
	let {minimumVersion, latestVersion, downloadUrl, hash, signature} = updateJson;

	if (!minimumVersion || !latestVersion || !downloadUrl || !hash || !signature) {
		log('Update failed: info incomplete', updateJson);
		return;
	}

	log('Latest version is ' + latestVersion + (usingInsider ? ' (insider)' : ''));

	// If minimum version is higher than current electron version, we will require a manual full reinstall
	if (isV2MoreRecent(app.getVersion(), minimumVersion)) {
		updateEvents.emit('update-manual-required');
		log('Update failed: minimum version mismatch. App must be manually updated');
		return;
	}

	// A new version is posted, go get it!
	if (isV2MoreRecent(currentPackageVersion, latestVersion)) {
		// Download file only if it's not already here
		let downloadPath = path.join(dataPath, 'obsidian-' + latestVersion + '.asar');
		if (!fs.existsSync(downloadPath)) {
			log('Downloading update from', downloadUrl);
			// Download to a buffer so we can check its signature
			let compressedBuffer = await httpGetBinary(downloadUrl);

			log('Verifying hash & signature. Size=', compressedBuffer.byteLength);
			let newHash = crypto.createHash('SHA256')
				.update(compressedBuffer)
				.digest('base64')
			let verifiedHash = hash === newHash;
			let verifiedSignature =
				crypto.createVerify('RSA-SHA256')
					.update(compressedBuffer)
					.verify(SIGNATURE_CERT, signature, 'base64');

			if (verifiedHash && verifiedSignature) {
				log('Saving file');
				let tempDownloadPath = path.join(dataPath, 'obsidian.asar.tmp');
				let decompressedBuffer = await new Promise((resolve, reject) => {
					zlib.gunzip(compressedBuffer, {}, (err, data) => {
						if (err) {
							return reject(err);
						}
						resolve(data);
					});
				});

				await fs.promises.writeFile(tempDownloadPath, decompressedBuffer);
				await fs.promises.rename(tempDownloadPath, downloadPath);
				log('Update complete.');
				updateEvents.emit('update-downloaded');
			}
			else {
				if (!verifiedHash) {
					log('Hash check failed!', newHash);
				}
				if (!verifiedSignature) {
					log('Signature check failed!');
				}
			}
		}
		else {
			log('An update is already downloaded.');
		}
	}
	else {
		log('App is up to date.');
	}

	// Clean up old updates now that we have the latest version
	let files = fs.readdirSync(dataPath, {withFileTypes: true});
	for (let file of files) {
		let filename = file.name;

		// Delete temporary file
		if (filename === 'obsidian.asar.tmp') {
			await fs.promises.unlink(path.join(dataPath, filename));
		}

		// Delete all versions that aren't the latest version.
		if (file.isFile() && filename.startsWith('obsidian-') && filename.endsWith('.asar')) {
			let newVersion = extractVersion(filename);
			// Make an exception for the current running version.
			if (newVersion !== currentPackageVersion &&
				newVersion !== latestVersion) {
				await fs.promises.unlink(path.join(dataPath, filename));
			}
		}
	}
}

function loadApp(asarPath) {
	// Execute asar content
	let main = path.join(asarPath, 'main.js');

	let fn;
	try {
		fn = require(main);
	} catch (e) {
		log('Failed to require app package', asarPath);
		console.error(e);
		return false;
	}

	if (fn) {
		fn(asarPath, updateEvents);
		return true;
	}
	return false;
}

function extractVersion(filename) {
	if (filename.startsWith('obsidian-') && filename.endsWith('.asar')) {
		return filename.substring('obsidian-'.length, filename.length - '.asar'.length);
	}
	return null;
}

function parseVersion(string) {
	if (!string) {
		return null;
	}
	let valid = true;
	let parts = string.split('.').map((part) => {
		part = parseInt(part);
		if (isNaN(part)) {
			valid = false;
		}
		return part;
	});
	if (valid) {
		return parts;
	}
	return null;
}

function isMoreRecent(version1, version2) {
	let length = Math.min(version1.length, version2.length);
	for (let i = 0; i < length; i++) {
		if (version1[i] < version2[i]) {
			return true;
		}
		if (version1[i] > version2[i]) {
			return false;
		}
	}
	if (version1.length < version2.length) {
		return true;
	}
	if (version1.length > version2.length) {
		return false;
	}
	return false;
}

function isV2MoreRecent(v1, v2) {
	let version1 = parseVersion(v1);
	let version2 = parseVersion(v2);
	if (!version2) {
		return false;
	}
	if (!version1) {
		return true;
	}
	return isMoreRecent(version1, version2);
}

function httpGet(url) {
	return httpGetBinary(url).then(buffer => buffer.toString('utf8'));
}

function httpGetBinary(url) {
	return new Promise((resolve, reject) => {
		let request = net.request({
			method: 'GET',
			url: url,
			redirect: 'follow',
		});
		request.setHeader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.183 Safari/537.36');
		request.on('login', (authInfo, callback) => callback());
		request.on('error', reject);
		request.on('response', (res) => {
			let data = [];
			res.on('data', (chunk) => data.push(chunk));
			res.on('end', () => resolve(Buffer.concat(data)));
		})
		request.end();
	});
}

// Source: https://github.com/electron/electron/blob/19954126e08c67022b89a886cadb10471ac853ae/lib/browser/init.ts#L20
process.on('uncaughtException', function (error) {
	// Don't emit errors for updater
	if (error.message && error.message.indexOf('net::ERR') !== -1) {
		return;
	}

	console.error('Uncaught Exception', error);

	// Show error in GUI.
	// We can't import { dialog } at the top of this file as this file is
	// responsible for setting up the require hook for the "electron" module
	// so we import it inside the handler down here
	import('electron')
		.then(({dialog}) => {
			const stack = error.stack ? error.stack : `${error.name}: ${error.message}`;
			const message = 'Uncaught Exception:\n' + stack;
			dialog.showErrorBox('A JavaScript error occurred in the main process', message);
		});
});

// Actual startup routine
setInterval(queueUpdate, 60 * 60 * 1000);

let asarPath = path.join(APP_PATH, 'obsidian.asar');
let updatedAsarPath = '';
let updatedAsarVersion = '';

// Check if we have an updated asar to replace the built-in one
try {
	let candidateFile = '';
	let version = '';
	let stat = fs.statSync(dataPath);
	if (stat.isDirectory()) {
		let files = fs.readdirSync(dataPath, {withFileTypes: true});
		for (let file of files) {
			let filename = file.name;
			if (file.isFile() && filename.startsWith('obsidian-') && filename.endsWith('.asar')) {
				let newVersion = extractVersion(filename);
				if (isV2MoreRecent(version, newVersion)) {
					candidateFile = filename;
					version = newVersion;
				}
			}
		}
	}

	// We found an updated asar
	if (isV2MoreRecent(app.getVersion(), version)) {
		updatedAsarPath = path.join(dataPath, candidateFile);
		updatedAsarVersion = version;
	}
} catch (e) {
	if (e.code !== 'ENOENT') {
		console.error(e);
	}
}

let success = false;
if (updatedAsarPath) {
	success = loadApp(updatedAsarPath);
	currentPackageVersion = updatedAsarVersion;
	log('Loaded updated app package', updatedAsarPath);
}

if (!success) {
	success = loadApp(asarPath);
	log('Loaded main app package', asarPath);
}

if (!success) {
	log('Failed to load both app packages.');
}

queueUpdate();
updateEvents.on('check', () => queueUpdate(true));
