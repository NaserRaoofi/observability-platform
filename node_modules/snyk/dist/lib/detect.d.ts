import { SupportedPackageManagers } from './package-managers';
export declare const AUTO_DETECTABLE_FILES: string[];
export declare function isPathToPackageFile(path: string, featureFlags?: Set<string>): boolean;
export declare function detectPackageManager(root: string, options: any, featureFlags?: Set<string>): any;
export declare function localFileSuppliedButNotFound(root: any, file: any): any;
export declare function isLocalFolder(root: string): boolean;
export declare function detectPackageFile(root: string, featureFlags?: Set<string>): string | undefined;
export declare function detectPackageManagerFromFile(file: string, featureFlags?: Set<string>): SupportedPackageManagers;
