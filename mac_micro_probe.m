function mac_micro_probe(shardName, testFile, startIndex, stopIndex, fullCount)
%MAC_MICRO_PROBE Run a small Apple Silicon shard with per-test checkpoints.

shardName = string(shardName);
testFile = string(testFile);
startIndex = double(startIndex);
stopIndex = double(stopIndex);
fullCount = double(fullCount);
harnessRoot = fileparts(mfilename("fullpath"));
toolboxRoot = fullfile(harnessRoot, "GUI-260902");
artifactRoot = fullfile(harnessRoot, "artifacts", "micro", shardName);
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

allTests = matlab.unittest.TestSuite.fromFile(fullfile(toolboxRoot, "tests", testFile));
assert(numel(allTests) == fullCount, ...
    "opnmf:acceptance:UnexpectedMicroFileCount", ...
    "%s expected %d tests but found %d.", testFile, fullCount, numel(allTests));
assert(startIndex >= 1 && stopIndex >= startIndex && stopIndex <= fullCount, ...
    "opnmf:acceptance:InvalidMicroRange", ...
    "Invalid range %d:%d for %s with %d tests.", ...
    startIndex, stopIndex, testFile, fullCount);
suite = allTests(startIndex:stopIndex);

selection = struct("File", testFile, "Start", startIndex, "Stop", stopIndex, ...
    "FullCount", fullCount, "Expected", numel(suite), ...
    "Names", string({suite.Name}));
writeJson(fullfile(artifactRoot, "selection.json"), selection);

diaryPath = fullfile(artifactRoot, "console.log");
diary(diaryPath);
diaryCleanup = onCleanup(@() diary("off")); %#ok<NASGU>
results = matlab.unittest.TestResult.empty;
records = repmat(struct("Name", "", "Passed", false, "Failed", false, ...
    "Incomplete", false, "DurationSeconds", 0), 1, 0);
progress = struct("Shard", shardName, "Completed", 0, ...
    "Expected", numel(suite), "CurrentTest", "", ...
    "ArchiveSHA256", ...
        "24BC909FA1D7946B21E2FE644C674B1B072CD22DAAAF16A9A3600B96B9CA1CE0");
writeJson(fullfile(artifactRoot, "progress.json"), progress);

for idx = 1:numel(suite)
    progress.CurrentTest = string(suite(idx).Name);
    writeJson(fullfile(artifactRoot, "progress.json"), progress);
    fprintf("MICRO_TEST_START %d/%d %s\n", idx, numel(suite), progress.CurrentTest);
    oneResult = run(suite(idx));
    disp(oneResult);
    results = [results oneResult]; %#ok<AGROW>
    records(end + 1) = struct( ... %#ok<AGROW>
        "Name", string(oneResult.Name), ...
        "Passed", logical(oneResult.Passed), ...
        "Failed", logical(oneResult.Failed), ...
        "Incomplete", logical(oneResult.Incomplete), ...
        "DurationSeconds", double(oneResult.Duration));
    progress.Completed = numel(results);
    progress.CurrentTest = "";
    writeJson(fullfile(artifactRoot, "progress.json"), progress);
    writeJson(fullfile(artifactRoot, "test_results.json"), records);
    try
        save(fullfile(artifactRoot, "results_partial.mat"), ...
            "results", "progress", "-v7.3");
    catch saveException
        writeText(fullfile(artifactRoot, "results_partial_save_failed.txt"), ...
            getReport(saveException, "extended", "hyperlinks", "off"));
    end
end

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
    "ArchiveSHA256", progress.ArchiveSHA256);
writeJson(fullfile(artifactRoot, "summary.json"), summary);
save(fullfile(artifactRoot, "results.mat"), "results", "summary", "-v7.3");

assert(summary.Total == numel(suite), ...
    "opnmf:acceptance:IncompleteMicroShard", ...
    "Micro shard %s did not finish every selected test.", shardName);
assert(summary.Failed == 0 && summary.Incomplete == 0, ...
    "opnmf:acceptance:MicroShardFailure", ...
    "Micro shard %s has failed or incomplete tests.", shardName);
writeJson(fullfile(artifactRoot, "SHARD_PASSED.json"), summary);
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
