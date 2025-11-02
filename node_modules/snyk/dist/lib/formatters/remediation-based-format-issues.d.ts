import { TestOptions } from '../../lib/types';
import { GroupedVuln, RemediationChanges } from '../../lib/snyk-test/legacy';
export declare function formatIssuesWithRemediation(vulns: GroupedVuln[], remediationInfo: RemediationChanges, options: TestOptions): string[];
export declare function printPath(path: string[], slice?: number): string;
