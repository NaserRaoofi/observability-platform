import { FormattedResult } from '../types';
import { Policy } from 'snyk-policy';
export declare function filterIgnoredIssues(policy: Policy | undefined, results: FormattedResult[]): {
    filteredIssues: FormattedResult[];
    ignoreCount: number;
};
