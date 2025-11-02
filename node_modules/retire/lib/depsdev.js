"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkOSV = checkOSV;
const https_1 = __importDefault(require("https"));
const retire_1 = require("./retire");
function loadJson(url, options) {
    options.log.debug('Downloading ' + url + ' ...');
    return new Promise((resolve, reject) => {
        const req = https_1.default.request(url, (res) => {
            if (res.statusCode == 404)
                return resolve(undefined);
            if (res.statusCode != 200) {
                return reject('HTTP ' + res.statusCode + ' ' + res.statusMessage + ' for ' + url);
            }
            const data = [];
            res.on('data', (c) => data.push(c));
            res.on('end', () => {
                const result = Buffer.concat(data).toString();
                resolve(JSON.parse(result));
            });
        });
        req.on('error', (err) => {
            reject(err);
        });
        req.end();
    });
}
function getVulnerabilities(packageName, version, options) {
    return loadJson(`https://api.deps.dev/v3alpha/systems/npm/packages/${packageName}/versions/${version}`, options);
}
function scoreToSeverity(score) {
    if (score > 7)
        return 'high';
    if (score > 4)
        return 'medium';
    return 'low';
}
async function loadAdvisory(packageName, version, id, options) {
    const osvAdvisory = await loadJson(`https://api.osv.dev/v1/vulns/${id}`, options);
    const advisory = await loadJson(`https://api.deps.dev/v3alpha/advisories/${id}`, options);
    if (!advisory || !osvAdvisory)
        return [];
    const simplifiedRepo = {
        [packageName]: {
            vulnerabilities: osvAdvisory.affected
                .map(({ ranges }) => ranges.map(({ events }) => ({
                atOrAbove: events[0].introduced,
                below: events[0].fixed,
                severity: scoreToSeverity(advisory.cvss3Score),
                cwe: osvAdvisory.database_specific?.cwe_ids ?? [],
                identifiers: {
                    githubID: id,
                    CVE: osvAdvisory.aliases.filter((x) => x.startsWith('CVE-')),
                    summary: advisory.title,
                },
                info: osvAdvisory.references.map(({ url }) => url),
            })))
                .reduce((a, b) => a.concat(b), []),
            extractors: {},
        },
    };
    return (0, retire_1.check)(packageName, version, simplifiedRepo);
}
async function checkOSV(packageName, version, options) {
    try {
        const versionInfo = await getVulnerabilities(packageName, version, options);
        if (!versionInfo)
            return [];
        if (versionInfo.advisoryKeys.length == 0)
            return [];
        const comps = await Promise.all(versionInfo.advisoryKeys.map(({ id }) => loadAdvisory(packageName, version, id, options)));
        const flattened = comps.reduce((a, b) => a.concat(b), []);
        return flattened.map((x) => x.vulnerabilities ?? []).reduce((a, b) => a.concat(b), []);
    }
    catch (e) {
        options.log.warn('Error checking OSV: ' + e);
        return [];
    }
}
