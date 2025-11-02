import { Options, Repository } from './types';
import * as z from 'zod';
export declare function validateRepository(repo: Repository, replacer?: Options['process']): z.SafeParseReturnType<unknown, Repository>;
export declare function asbowerrepo(jsRepo: Repository): Repository;
export declare function loadrepository(repoUrl: string, options: Options): Promise<Repository>;
export declare function loadrepositoryFromFile(filepath: string, options: Options): Promise<Repository>;
