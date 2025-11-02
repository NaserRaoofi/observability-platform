/**
 * Sends the specified error back at the Golang CLI, by writting it to the temporary error file. Errors that are not
 * inlcuded in the Error Catalog will be wraped in a generic model.
 * @param err {Error} The error to be sent to the Golang CLI
 * @param isJson {boolean} If the prameter is set, the meta field "supressJsonOutput" will also be set, supressing the Golang CLI from displaying this error.
 * @returns {Promise<boolean>} The result of the operation as a boolean value
 */
export declare function sendError(err: Error, isJson: boolean): boolean;
