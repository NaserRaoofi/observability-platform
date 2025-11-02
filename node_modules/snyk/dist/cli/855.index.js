"use strict";
exports.id = 855;
exports.ids = [855];
exports.modules = {

/***/ 66855:
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {


Object.defineProperty(exports, "__esModule", ({ value: true }));
const getWoof_1 = __webpack_require__(76993);
function woof(...args) {
    const woof = (0, getWoof_1.default)(args);
    console.log(`
    |         |
   /|         |\\
  | |         | |
  | |/-------\\| |
  \\             /
   |  \\     /  |
   | \\o/   \\o/ |
   |    | |    |
    \\/  | |  \\/
    |   | |   |
     \\  ( )  /
      \\_/ \\_/  /-----\\
        \\U/ --( ${woof} )
               \\-----/
`);
}
exports["default"] = woof;


/***/ }),

/***/ 76993:
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {


Object.defineProperty(exports, "__esModule", ({ value: true }));
const preview_features_enabled_1 = __webpack_require__(76278);
const woofs = {
    en: 'Woof!',
    he: ' בה! ',
    ru: ' Гав!',
    es: 'Guau!',
    cs: ' Haf!',
    uk: ' Гав!',
    de: 'Wuff!',
    ro: ' Ham!',
    cat: 'Meow?',
};
function getWoof(args) {
    const options = args.pop();
    let lang = 'en';
    if (typeof options.language === 'string' &&
        Object.keys(woofs).includes(options.language)) {
        lang = options.language;
    }
    if (lang === 'cat') {
        for (const option in options) {
            console.debug(`${option}:::`, options[option], `:::${option}`);
        }
        const envVal = options.env;
        if (envVal) {
            console.debug(envVal + '=' + process.env[envVal]);
        }
        if ((0, preview_features_enabled_1.previewFeaturesEnabled)()) {
            console.debug('This is a previewoof!');
        }
        if (options['exit-code'] != undefined) {
            const exitCode = Number(options['exit-code']);
            if (exitCode < 0) {
                process.abort();
            }
            else {
                process.exit(exitCode);
            }
        }
    }
    return woofs[lang];
}
exports["default"] = getWoof;


/***/ }),

/***/ 76278:
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {


Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.previewFeaturesEnabled = void 0;
const debug = __webpack_require__(15158)('preview');
function previewFeaturesEnabled() {
    if (process.env.SNYK_INTERNAL_PREVIEW_FEATURES === '1') {
        debug('Using a preview feature!');
        return true;
    }
    return false;
}
exports.previewFeaturesEnabled = previewFeaturesEnabled;


/***/ })

};
;
//# sourceMappingURL=855.index.js.map