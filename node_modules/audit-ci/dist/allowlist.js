"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dedupeAllowlistRecords = exports.normalizeAllowlistRecord = void 0;
const common_1 = require("./common");
const nsp_record_1 = require("./nsp-record");
const DEFAULT_NSP_CONTENT = {
    active: true,
    notes: undefined,
    expiry: undefined,
};
/**
 * Takes a string and converts it into a NSPRecord object. If a NSPRecord
 * is passed in, no modifications are made and the record is returned as is.
 *
 * @param recordOrId A string or NSPRecord object.
 * @returns Normalized NSPRecord object.
 */
function normalizeAllowlistRecord(recordOrId) {
    return typeof recordOrId === "string"
        ? {
            [recordOrId]: DEFAULT_NSP_CONTENT,
        }
        : recordOrId;
}
exports.normalizeAllowlistRecord = normalizeAllowlistRecord;
/**
 * Removes duplicate allowlist items from an array based on the allowlist id.
 *
 * @param recordsOrIds An array containing allowlist string ids or NSPRecords.
 * @returns An array of NSPRecords with duplicates removed.
 */
function dedupeAllowlistRecords(recordsOrIds) {
    const map = new Map();
    for (const recordOrId of recordsOrIds) {
        const nspRecord = normalizeAllowlistRecord(recordOrId);
        const advisoryId = (0, nsp_record_1.getAllowlistId)(nspRecord);
        if (!map.has(advisoryId)) {
            map.set(advisoryId, nspRecord);
        }
    }
    return [...map.values()];
}
exports.dedupeAllowlistRecords = dedupeAllowlistRecords;
class Allowlist {
    /**
     * @param input the allowlisted module names, advisories, and module paths
     */
    constructor(input) {
        this.modules = [];
        this.advisories = [];
        this.paths = [];
        this.moduleRecords = [];
        this.advisoryRecords = [];
        this.pathRecords = [];
        if (!input) {
            return;
        }
        for (const allowlist of input) {
            if (typeof allowlist === "number") {
                throw new TypeError("Unsupported number as allowlist. Perform codemod to update config to use GitHub advisory as identifiers: https://github.com/quinnturner/audit-ci-codemod with `npx @quinnturner/audit-ci-codemod`. See also: https://github.com/IBM/audit-ci/pull/217");
            }
            const allowlistNspRecord = normalizeAllowlistRecord(allowlist);
            if (!(0, nsp_record_1.isNSPRecordActive)(allowlistNspRecord)) {
                continue;
            }
            const allowlistId = typeof allowlist === "string"
                ? allowlist
                : (0, nsp_record_1.getAllowlistId)(allowlistNspRecord);
            if (allowlistId.includes(">") || allowlistId.includes("|")) {
                this.paths.push(allowlistId);
                this.pathRecords.push(allowlistNspRecord);
            }
            else if ((0, common_1.isGitHubAdvisoryId)(allowlistId)) {
                this.advisories.push(allowlistId);
                this.advisoryRecords.push(allowlistNspRecord);
            }
            else {
                this.modules.push(allowlistId);
                this.moduleRecords.push(allowlistNspRecord);
            }
        }
    }
    static mapConfigToAllowlist(config) {
        const { allowlist } = config;
        const deduplicatedAllowlist = dedupeAllowlistRecords(allowlist || []);
        const allowlistObject = new Allowlist(deduplicatedAllowlist);
        return allowlistObject;
    }
}
exports.default = Allowlist;
//# sourceMappingURL=allowlist.js.map