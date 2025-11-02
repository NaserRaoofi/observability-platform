/**
 * Attempt to json-stringify an object which is potentially very large and might exceed the string limit.
 * If it does exceed the string limit, return empty string.
 * @param obj the object from which you want to get a JSON string
 */
export declare function jsonStringifyLargeObject(obj: any): string;
