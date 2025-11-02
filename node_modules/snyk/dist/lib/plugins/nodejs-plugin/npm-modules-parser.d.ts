import { PackageExpanded } from 'snyk-resolve-deps/dist/types';
import { Options } from '../types';
export declare function parse(root: string, targetFile: string, options: Options): Promise<PackageExpanded>;
