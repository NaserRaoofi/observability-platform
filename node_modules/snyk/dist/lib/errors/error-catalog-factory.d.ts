import { ProblemError } from '@snyk/error-catalog-nodejs-public';
/**
 * Simple factory that creates error catalog instances based on status code
 * @param statusCode - HTTP status code
 * @param message - Error message (optional)
 * @returns ProblemError instance
 */
export declare function createErrorCatalogFromStatusCode(statusCode: number): ProblemError;
