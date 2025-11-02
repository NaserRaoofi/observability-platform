"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.info = info;
exports.warn = warn;
exports.pick = pick;
exports.flatten = flatten;
function info(options) {
    return function (...message) {
        (options.logger || console.log)(message);
    };
}
function warn(options) {
    return function (...message) {
        (options.warnlogger || options.logger || console.warn)(message);
    };
}
function pick(p, keys) {
    const result = {};
    keys.forEach((k) => {
        if (k in p) {
            result[k] = p[k];
        }
    });
    return result;
}
function flatten(e) {
    return e.reduce((x, y) => x.concat(y), []);
}
