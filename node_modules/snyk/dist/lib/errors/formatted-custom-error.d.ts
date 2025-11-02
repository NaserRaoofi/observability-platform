import { CustomError } from '.';
import { ProblemError } from '@snyk/error-catalog-nodejs-public';
export declare class FormattedCustomError extends CustomError {
    formattedUserMessage: string;
    constructor(message: string, formattedUserMessage: string, userMessage?: string, errorCatalog?: ProblemError);
    set errorCatalog(ec: ProblemError | undefined);
    get errorCatalog(): ProblemError | undefined;
}
