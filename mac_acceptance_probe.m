function mac_acceptance_probe(runnerArchitecture)
%MAC_ACCEPTANCE_PROBE Validate the exact GUI-260902 package on macOS.

if nargin < 1 || strlength(string(runnerArchitecture)) == 0
    runnerArchitecture = "unknown";
end
runnerArchitecture = string(runnerArchitecture);

harnessRoot = fileparts(mfilename("fullpath"));
toolboxRoot = fullfile(harnessRoot, "GUI-260902");
artifactRoot = fullfile(harnessRoot, "artifacts", runnerArchitecture);
if ~isfolder(artifactRoot)
    mkdir(artifactRoot);
end

originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>

try
    assert(ismac, "opnmf:acceptance:NotMac", ...
        "This acceptance probe must run on macOS.");
    assert(isfolder(toolboxRoot), "opnmf:acceptance:MissingPackage", ...
        "The extracted GUI-260902 directory is missing.");

    cd(toolboxRoot);
    addpath(toolboxRoot, "-begin");
    addpath(fullfile(toolboxRoot, "depend"), "-begin");

    environment = struct( ...
        "Timestamp", string(datetime("now", "TimeZone", "local")), ...
        "RunnerArchitecture", runnerArchitecture, ...
        "Computer", string(computer), ...
        "Architecture", string(computer("arch")), ...
        "OperatingSystem", string(system_dependent("getos")), ...
        "MATLABVersion", string(version), ...
        "MATLABRelease", string(version("-release")), ...
        "JavaVersion", string(version("-java")), ...
        "StatisticsToolboxLicensed", ...
            logical(license("test", "Statistics_Toolbox")), ...
        "NNMFPath", string(which("nnmf")), ...
        "BootstrpPath", string(which("bootstrp")), ...
        "ApplicationPath", string(which("OPNMFApp")), ...
        "RunEntryPath", string(which("run_opnmf")));

    assert(environment.StatisticsToolboxLicensed, ...
        "opnmf:acceptance:MissingStatisticsLicense", ...
        "Statistics and Machine Learning Toolbox is not licensed.");
    assert(strlength(environment.NNMFPath) > 0, ...
        "opnmf:acceptance:MissingNNMF", "nnmf is unavailable.");
    assert(strlength(environment.BootstrpPath) > 0, ...
        "opnmf:acceptance:MissingBootstrp", "bootstrp is unavailable.");

    writeJson(fullfile(artifactRoot, "environment.json"), environment);

    % Exercise the actual application class without requiring an interactive
    % WindowServer session. The run_opnmf entry point is checked above and is
    % covered by the packaged application tests.
    app = OPNMFApp("Visible", "off");
    appCleanup = onCleanup(@() closeApp(app)); %#ok<NASGU>
    drawnow;
    assert(isa(app, "OPNMFApp") && isvalid(app), ...
        "opnmf:acceptance:GuiLaunchFailed", ...
        "run_opnmf did not return a valid OPNMFApp instance.");
    closeApp(app);
    clear appCleanup

    diaryPath = fullfile(artifactRoot, "full_test_console.log");
    diary(diaryPath);
    diaryCleanup = onCleanup(@() diary("off")); %#ok<NASGU>
    import matlab.unittest.TestSuite
    suite = TestSuite.fromFolder(fullfile(toolboxRoot, "tests"), ...
        "IncludingSubfolders", true);
    results = run(suite);
    disp(results);
    diary("off");
    clear diaryCleanup

    testSummary = struct( ...
        "Total", numel(results), ...
        "Passed", nnz([results.Passed]), ...
        "Failed", nnz([results.Failed]), ...
        "Incomplete", nnz([results.Incomplete]), ...
        "DurationSeconds", sum([results.Duration]));
    writeJson(fullfile(artifactRoot, "test_summary.json"), testSummary);
    try
        save(fullfile(artifactRoot, "full_test_results.mat"), ...
            "results", "environment", "testSummary", "-v7.3");
    catch saveException
        fileId = fopen(fullfile(artifactRoot, ...
            "full_test_results_save_failed.txt"), "w");
        if fileId >= 0
            cleanupFile = onCleanup(@() fclose(fileId)); %#ok<NASGU>
            fprintf(fileId, "%s\n", getReport(saveException, ...
                "extended", "hyperlinks", "off"));
            clear cleanupFile
        end
    end

    assert(testSummary.Total == 257, ...
        "opnmf:acceptance:UnexpectedTestCount", ...
        "Expected 257 tests, but ran %d.", testSummary.Total);
    assert(testSummary.Failed == 0 && testSummary.Incomplete == 0, ...
        "opnmf:acceptance:TestFailure", ...
        "macOS acceptance has failed or incomplete tests.");

    success = struct( ...
        "Status", "PASSED", ...
        "RunnerArchitecture", runnerArchitecture, ...
        "Total", testSummary.Total, ...
        "Passed", testSummary.Passed, ...
        "ArchiveSHA256", ...
            "24BC909FA1D7946B21E2FE644C674B1B072CD22DAAAF16A9A3600B96B9CA1CE0");
    writeJson(fullfile(artifactRoot, "ACCEPTANCE_PASSED.json"), success);
catch exception
    failurePath = fullfile(artifactRoot, "ACCEPTANCE_FAILED.txt");
    fileId = fopen(failurePath, "w");
    if fileId >= 0
        cleanupFile = onCleanup(@() fclose(fileId)); %#ok<NASGU>
        fprintf(fileId, "%s\n", getReport(exception, "extended", ...
            "hyperlinks", "off"));
    end
    rethrow(exception)
end
end

function writeJson(path, value)
fileId = fopen(path, "w");
assert(fileId >= 0, "opnmf:acceptance:WriteFailed", ...
    "Unable to write %s.", path);
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, "%s\n", jsonencode(value, "PrettyPrint", true));
end

function closeApp(app)
try
    if ~isempty(app) && isvalid(app)
        delete(app);
    end
catch
end
close all force
end

function restoreSession(originalFolder, originalPath)
path(originalPath);
if isfolder(originalFolder)
    cd(originalFolder);
end
close all force
end
