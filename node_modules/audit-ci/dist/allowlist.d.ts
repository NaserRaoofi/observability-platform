import type { GitHubAdvisoryId } from "audit-types";
import type { AuditCiPreprocessedConfig } from "./config";
import { type NSPRecord, type GitHubNSPRecord } from "./nsp-record";
export type AllowlistRecord = string | NSPRecord;
/**
 * Takes a string and converts it into a NSPRecord object. If a NSPRecord
 * is passed in, no modifications are made and the record is returned as is.
 *
 * @param recordOrId A string or NSPRecord object.
 * @returns Normalized NSPRecord object.
 */
export declare function normalizeAllowlistRecord(recordOrId: AllowlistRecord): NSPRecord;
/**
 * Removes duplicate allowlist items from an array based on the allowlist id.
 *
 * @param recordsOrIds An array containing allowlist string ids or NSPRecords.
 * @returns An array of NSPRecords with duplicates removed.
 */
export declare function dedupeAllowlistRecords(recordsOrIds: AllowlistRecord[]): NSPRecord[];
declare class Allowlist {
    modules: string[];
    advisories: GitHubAdvisoryId[];
    paths: string[];
    moduleRecords: NSPRecord[];
    advisoryRecords: GitHubNSPRecord[];
    pathRecords: NSPRecord[];
    /**
     * @param input the allowlisted module names, advisories, and module paths
     */
    constructor(input?: AllowlistRecord[]);
    static mapConfigToAllowlist(config: Pick<AuditCiPreprocessedConfig, "allowlist">): Allowlist;
}
export default Allowlist;
//# sourceMappingURL=allowlist.d.ts.map