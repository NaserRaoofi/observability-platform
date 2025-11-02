import { CustomError } from './custom-error';
export declare class MissingApiTokenError extends CustomError {
    private static ERROR_CODE;
    private static ERROR_STRING_CODE;
    private static ERROR_MESSAGE;
    /**
     * isMissingApiToken returns whether the error instance is a missing API token
     * error.
     *
     * Defined as a property so that the same expression resolves as "falsy"
     * (undefined) when other error types are tested.
     */
    get isMissingApiToken(): boolean;
    constructor();
}
