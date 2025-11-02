import { TestOutput } from '../scan/results';
import { IacAnalytics } from './index';
type IacCloudContext = Pick<IacAnalytics, 'iacCloudContext' | 'iacCloudContextCloudProvider' | 'iacCloudContextSuppressedIssuesCount'>;
export declare function getIacCloudContext(testConfig: {
    snykCloudEnvironment?: string;
}, testOutput: TestOutput): IacCloudContext;
export {};
