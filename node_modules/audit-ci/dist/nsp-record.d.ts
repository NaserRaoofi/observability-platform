import type { GitHubAdvisoryId } from "audit-types";
export interface NSPContent {
    readonly active?: boolean;
    readonly notes?: string;
    readonly expiry?: string | number;
}
export type NSPRecord = Record<string, NSPContent>;
export type GitHubNSPRecord = Record<GitHubAdvisoryId, NSPContent>;
/**
 * Retrieves the allowlist id from the NSPRecord.
 *
 * @param nspRecord NSPRecord object.
 * @returns The advisory id.
 */
export declare function getAllowlistId(nspRecord: NSPRecord | GitHubNSPRecord): string;
/**
 * Retrieves the content for the NSPRecord.
 *
 * @param nspRecord NSPRecord object.
 * @returns The NSPContent object.
 */
export declare function getNSPContent(nspRecord: NSPRecord | GitHubNSPRecord): NSPContent;
/**
 * Determines if the NSPRecord is active.
 *
 * @param nspRecord NSPRecord object.
 * @param now The current date. The default is initialized to the current date.
 * @returns True if the record is active, false otherwise.
 */
export declare function isNSPRecordActive(nspRecord: NSPRecord, now?: Date): boolean;
//# sourceMappingURL=nsp-record.d.ts.map