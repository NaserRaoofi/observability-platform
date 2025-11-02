"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const common = require("./common");
const process = require("process");
const errorContextMessage = 'Download Error';
(async () => {
    try {
        const config = common.getCurrentConfiguration();
        const executable = config.getLocalLocation();
        if (process.argv.includes('exec')) {
            const filenameShasum = config.getShasumFile();
            const { downloadUrl, backupUrl } = config.getDownloadLocations();
            const downloadError = await common.downloadWithBackup(downloadUrl, backupUrl, executable, filenameShasum);
            if (downloadError !== undefined) {
                throw downloadError;
            }
        }
    }
    catch (err) {
        await common.logError(errorContextMessage, err);
    }
})();
//# sourceMappingURL=bootstrap.js.map