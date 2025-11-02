/// <reference types="node" />
import { Readable } from 'stream';
export declare class ConcatStream extends Readable {
    private current;
    private queue;
    constructor(...streams: Readable[]);
    append(...streams: Readable[]): void;
    _read(size?: number): void;
}
