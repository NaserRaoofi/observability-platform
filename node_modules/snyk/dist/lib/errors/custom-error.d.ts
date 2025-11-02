import { ProblemError } from '@snyk/error-catalog-nodejs-public';
export declare class CustomError extends Error {
    innerError: any;
    code: number | undefined;
    userMessage: string | undefined;
    strCode: string | undefined;
    protected _errorCatalog: ProblemError | undefined;
    constructor(message: string);
    set errorCatalog(ec: ProblemError | undefined);
    get errorCatalog(): ProblemError | undefined;
}
