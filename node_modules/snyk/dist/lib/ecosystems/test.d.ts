/// <reference types="node" />
import { Writable } from 'stream';
import { Options, PolicyOptions } from '../types';
import { TestCommandResult } from '../../cli/commands/types';
import { Ecosystem, ScanResult, TestResult } from './types';
type ScanResultsByPath = {
    [dir: string]: ScanResult[];
};
export declare function testEcosystem(ecosystem: Ecosystem, paths: string[], options: Options & PolicyOptions): Promise<TestCommandResult>;
export declare function selectAndExecuteTestStrategy(ecosystem: Ecosystem, scanResultsByPath: {
    [dir: string]: ScanResult[];
}, options: Options & PolicyOptions): Promise<[TestResult[], string[]]>;
export declare function printUnmanagedDepGraph(results: ScanResultsByPath, target: string, destination: Writable): Promise<TestCommandResult>;
export {};
