"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.audit = exports.report = void 0;
const colors_1 = require("./colors");
const common_1 = require("./common");
const model_1 = __importDefault(require("./model"));
const semver = __importStar(require("semver"));
const child_process_1 = require("child_process");
const MINIMUM_PNPM_AUDIT_REGISTRY_VERSION = "5.4.0";
async function runPnpmAudit(config) {
    const { directory, registry, _pnpm, "skip-dev": skipDevelopmentDependencies, "extra-args": extraArguments, } = config;
    const pnpmExec = _pnpm || "pnpm";
    let stdoutBuffer = {};
    function outListener(data) {
        stdoutBuffer = { ...stdoutBuffer, ...data };
    }
    const stderrBuffer = [];
    function errorListener(line) {
        stderrBuffer.push(line);
    }
    const arguments_ = ["audit", "--json"];
    if (registry) {
        const pnpmVersion = getPnpmVersion(directory);
        if (pnpmAuditSupportsRegistry(pnpmVersion)) {
            arguments_.push("--registry", registry);
        }
        else {
            console.warn(colors_1.yellow, `Update PNPM to version >=${MINIMUM_PNPM_AUDIT_REGISTRY_VERSION} to use the --registry flag`);
        }
    }
    if (skipDevelopmentDependencies) {
        arguments_.push("--prod");
    }
    if (extraArguments) {
        arguments_.push(...extraArguments);
    }
    const options = { cwd: directory };
    await (0, common_1.runProgram)(pnpmExec, arguments_, options, outListener, errorListener);
    if (stderrBuffer.length > 0) {
        throw new Error(`Invocation of pnpm audit failed:\n${stderrBuffer.join("\n")}`);
    }
    return stdoutBuffer;
}
function printReport(parsedOutput, levels, reportType, outputFormat) {
    const printReportObject = (text, object) => {
        if (outputFormat === "text") {
            console.log(colors_1.blue, text);
        }
        console.log(JSON.stringify(object, undefined, 2));
    };
    switch (reportType) {
        case "full":
            printReportObject("PNPM audit report JSON:", parsedOutput);
            break;
        case "important": {
            const { advisories, metadata } = parsedOutput;
            const relevantAdvisoryLevels = Object.keys(advisories).filter((advisory) => levels[advisories[advisory].severity]);
            const relevantAdvisories = {};
            for (const advisory of relevantAdvisoryLevels) {
                relevantAdvisories[advisory] = advisories[advisory];
            }
            const keyFindings = {
                advisories: relevantAdvisories,
                metadata: metadata,
            };
            printReportObject("PNPM audit report results:", keyFindings);
            break;
        }
        case "summary":
            printReportObject("PNPM audit report summary:", parsedOutput.metadata);
            break;
        default:
            throw new Error(`Invalid report type: ${reportType}. Should be \`['important', 'full', 'summary']\`.`);
    }
}
function report(parsedOutput, config, reporter) {
    const { levels, "report-type": reportType, "output-format": outputFormat, } = config;
    printReport(parsedOutput, levels, reportType, outputFormat);
    const model = new model_1.default(config);
    const summary = model.load(parsedOutput);
    return reporter(summary, config, parsedOutput);
}
exports.report = report;
/**
 * Audit your PNPM project!
 *
 * @returns Returns the audit report summary on resolve, `Error` on rejection.
 */
async function audit(config, reporter = common_1.reportAudit) {
    const parsedOutput = await runPnpmAudit(config);
    if ("error" in parsedOutput) {
        const { code, summary } = parsedOutput.error;
        throw new Error(`code ${code}: ${summary}`);
    }
    return report(parsedOutput, config, reporter);
}
exports.audit = audit;
function pnpmAuditSupportsRegistry(pnpmVersion) {
    return semver.gte(pnpmVersion, MINIMUM_PNPM_AUDIT_REGISTRY_VERSION);
}
function getPnpmVersion(cwd) {
    return (0, child_process_1.execSync)("pnpm -v", { cwd }).toString().replace("\n", "");
}
//# sourceMappingURL=pnpm-auditer.js.map