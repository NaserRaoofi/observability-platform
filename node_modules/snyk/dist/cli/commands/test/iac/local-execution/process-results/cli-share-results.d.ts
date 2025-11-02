import { IacShareResultsFormat, IaCTestFlags, ShareResultsOutput } from '../types';
import { Policy } from 'snyk-policy';
import { IacOutputMeta, ProjectAttributes, Tag } from '../../../../../../lib/types';
export declare function shareResults({ results, policy, tags, attributes, options, meta, }: {
    results: IacShareResultsFormat[];
    policy: Policy | undefined;
    tags?: Tag[];
    attributes?: ProjectAttributes;
    options: IaCTestFlags;
    meta: IacOutputMeta;
}): Promise<ShareResultsOutput>;
