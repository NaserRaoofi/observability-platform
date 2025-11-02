import * as snykPolicyLib from 'snyk-policy';
import { PackageExpanded } from 'snyk-resolve-deps/dist/types';
import { SupportedPackageManagers } from '../package-managers';
import { PolicyOptions } from '../types';
export declare function findAndLoadPolicy(root: string, scanType: SupportedPackageManagers | 'docker' | 'iac' | 'cpp', options: PolicyOptions, pkg?: PackageExpanded, scannedProjectFolder?: string): Promise<snykPolicyLib.Policy | undefined>;
