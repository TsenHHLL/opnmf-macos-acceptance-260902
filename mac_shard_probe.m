function mac_shard_probe(shardName, expectedCount)
%MAC_SHARD_PROBE Run one non-overlapping Apple Silicon test shard.

shardName = string(shardName);
expectedCount = double(expectedCount);
harnessRoot = fileparts(mfilename("fullpath"));
toolboxRoot = fullfile(harnessRoot, "GUI-260902");
artifactRoot = fullfile(harnessRoot, "artifacts", "shards", shardName);
if ~isfolder(artifactRoot)
    mkdir(artifactRoot);
end

originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>

cd(toolboxRoot);
addpath(toolboxRoot, "-begin");
addpath(fullfile(toolboxRoot, "depend"), "-begin");
addpath(fullfile(toolboxRoot, "tests", "helpers"), "-begin");

files = shardFiles(shardName);
suite = matlab.unittest.Test.empty;
for idx = 1:numel(files)
    suite = [suite matlab.unittest.TestSuite.fromFile( ...
        fullfile(toolboxRoot, "tests", files(idx)))]; %#ok<AGROW>
end
assert(numel(suite) == expectedCount, ...
    "opnmf:acceptance:UnexpectedShardCount", ...
    "Shard %s expected %d tests but found %d.", ...
    shardName, expectedCount, numel(suite));

diaryPath = fullfile(artifactRoot, "console.log");
diary(diaryPath);
diaryCleanup = onCleanup(@() diary("off")); %#ok<NASGU>
results = run(suite);
disp(results);
diary("off");
clear diaryCleanup

summary = struct( ...
    "Shard", shardName, ...
    "Total", numel(results), ...
    "Passed", nnz([results.Passed]), ...
    "Failed", nnz([results.Failed]), ...
    "Incomplete", nnz([results.Incomplete]), ...
    "DurationSeconds", sum([results.Duration]), ...
    "Computer", string(computer), ...
    "Architecture", string(computer("arch")), ...
    "MATLABRelease", string(version("-release")), ...
    "ArchiveSHA256", ...
        "24BC909FA1D7946B21E2FE644C674B1B072CD22DAAAF16A9A3600B96B9CA1CE0");
writeJson(fullfile(artifactRoot, "summary.json"), summary);
try
    save(fullfile(artifactRoot, "results.mat"), ...
        "results", "summary", "-v7.3");
catch saveException
    writeText(fullfile(artifactRoot, "results_save_failed.txt"), ...
        getReport(saveException, "extended", "hyperlinks", "off"));
end

assert(summary.Failed == 0 && summary.Incomplete == 0, ...
    "opnmf:acceptance:ShardFailure", ...
    "Shard %s has failed or incomplete tests.", shardName);
writeJson(fullfile(artifactRoot, "SHARD_PASSED.json"), summary);
end

function files = shardFiles(shardName)
switch shardName
    case "base"
        files = [ ...
            "TestAssignmentAlignment.m"
            "TestCrAveRemoval.m"
            "TestEnvironment.m"
            "TestFactorization.m"
            "TestFactorizationConvergenceRange.m"
            "TestHeatmapAndHoldout.m"
            "TestImputationSummary.m"
            "TestLoadData.m"
            "TestMetricPresentation.m"
            "TestProtectedBaseline.m"
            "TestValidation.m"];
    case "numeric"
        files = [ ...
            "TestDimensionality.m"
            "TestFormulaGraybox.m"
            "TestLargeScaleGraybox.m"
            "TestMatrixGraybox.m"
            "TestNumericalRegression.m"];
    case "gui_support"
        files = [ ...
            "TestAssignmentAlignmentGUI.m"
            "TestDiagnosticAssessmentRevisions.m"
            "TestExports.m"
            "TestFactorHeatmapItemNames.m"
            "TestImputationComparison.m"
            "TestIndependentSampleOverview.m"
            "TestKFoldSameDataSummaryPresentation.m"
            "TestLocalExtremaPresentation.m"
            "TestPosthoc.m"
            "TestPosthocMultiComparison.m"
            "TestSiteStratification.m"];
    case "gui_main"
        files = "TestOPNMFApp.m";
    otherwise
        error("opnmf:acceptance:UnknownShard", ...
            "Unknown test shard: %s", shardName);
end
end

function writeJson(filePath, value)
writeText(filePath, jsonencode(value, "PrettyPrint", true));
end

function writeText(filePath, value)
fileId = fopen(filePath, "w");
assert(fileId >= 0, "opnmf:acceptance:WriteFailed", ...
    "Unable to write %s.", filePath);
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, "%s\n", value);
end

function restoreSession(originalFolder, originalPath)
path(originalPath);
if isfolder(originalFolder)
    cd(originalFolder);
end
close all force
end

