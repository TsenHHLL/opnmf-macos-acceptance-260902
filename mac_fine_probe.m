function mac_fine_probe(shardName, expectedCount)
%MAC_FINE_PROBE Run one fine-grained Apple Silicon GUI test shard.

shardName = string(shardName);
expectedCount = double(expectedCount);
harnessRoot = fileparts(mfilename("fullpath"));
toolboxRoot = fullfile(harnessRoot, "GUI-260902");
artifactRoot = fullfile(harnessRoot, "artifacts", "fine", shardName);
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

[suite, selection] = selectShard(toolboxRoot, shardName);
assert(numel(suite) == expectedCount, ...
    "opnmf:acceptance:UnexpectedFineShardCount", ...
    "Fine shard %s expected %d tests but found %d.", ...
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
    "Selection", selection, ...
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
    "opnmf:acceptance:FineShardFailure", ...
    "Fine shard %s has failed or incomplete tests.", shardName);
writeJson(fullfile(artifactRoot, "SHARD_PASSED.json"), summary);
end

function [suite, selection] = selectShard(toolboxRoot, shardName)
testsRoot = fullfile(toolboxRoot, "tests");
if startsWith(shardName, "gui_main_")
    allTests = matlab.unittest.TestSuite.fromFile( ...
        fullfile(testsRoot, "TestOPNMFApp.m"));
    assert(numel(allTests) == 101, ...
        "opnmf:acceptance:UnexpectedOPNMFAppCount", ...
        "TestOPNMFApp expected 101 tests but found %d.", numel(allTests));
    switch shardName
        case "gui_main_001"
            bounds = [1 17];
        case "gui_main_002"
            bounds = [18 34];
        case "gui_main_003"
            bounds = [35 51];
        case "gui_main_004"
            bounds = [52 68];
        case "gui_main_005"
            bounds = [69 84];
        case "gui_main_006"
            bounds = [85 101];
        otherwise
            error("opnmf:acceptance:UnknownFineShard", ...
                "Unknown fine shard: %s", shardName);
    end
    suite = allTests(bounds(1):bounds(2));
    selection = struct("Kind", "suiteRange", ...
        "File", "TestOPNMFApp.m", "Start", bounds(1), "Stop", bounds(2));
    return
end

switch shardName
    case "gui_support_001"
        files = ["TestDiagnosticAssessmentRevisions.m", "TestPosthoc.m"];
        expectedPerFile = [7 11];
    case "gui_support_002"
        files = ["TestSiteStratification.m", "TestImputationComparison.m", ...
            "TestAssignmentAlignmentGUI.m"];
        expectedPerFile = [11 4 1];
    case "gui_support_003"
        files = ["TestPosthocMultiComparison.m", "TestExports.m", ...
            "TestFactorHeatmapItemNames.m", "TestIndependentSampleOverview.m", ...
            "TestKFoldSameDataSummaryPresentation.m", ...
            "TestLocalExtremaPresentation.m"];
        expectedPerFile = [4 3 2 1 1 1];
    otherwise
        error("opnmf:acceptance:UnknownFineShard", ...
            "Unknown fine shard: %s", shardName);
end

suite = matlab.unittest.Test.empty;
for idx = 1:numel(files)
    fileSuite = matlab.unittest.TestSuite.fromFile(fullfile(testsRoot, files(idx)));
    assert(numel(fileSuite) == expectedPerFile(idx), ...
        "opnmf:acceptance:UnexpectedFineFileCount", ...
        "%s expected %d tests but found %d.", ...
        files(idx), expectedPerFile(idx), numel(fileSuite));
    suite = [suite fileSuite]; %#ok<AGROW>
end
selection = struct("Kind", "files", "Files", files, ...
    "ExpectedPerFile", expectedPerFile);
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
