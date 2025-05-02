%thesisDataAnalysisSettings
    %loads important paths, constants, and settings
    %called in (as of 4/28/25): 
        %createSubjectIDMap.m, selectTrials.m,trimming.m, extractAll.m, exportDatatoFiles.m, simpleStatsComparisons.m, visualizeDataInd


%DIRECTORIES:
rootThesisDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/';

%folders:
rawDataFolderDir = fullfile(rootThesisDir, 'RawData');
dataTablesFolderDir = fullfile(rootThesisDir, 'gorin_CMBN_F4_project', 'DataTables');
dataFiguresFolderDir = fullfile(rootThesisDir, 'gorin_CMBN_F4_project', 'DataFigures');

%files:
extraByTrialVarsDir = fullfile(dataTablesFolderDir, 'extraByTrialVars.csv');
extraBySubjVarsDir = fullfile(dataTablesFolderDir, 'extraBySubjVars.csv');
integratedDataTableDir = fullfile(dataTablesFolderDir, 'integratedDataTable.mat');

rawFixedSpeedFileNames = {
        'Trial1raw_EndlessCarKinematicLog.csv'; 'Trial4raw_EndlessCarKinematicLog.csv'; 'Trial5raw_EndlessCarKinematicLog.csv'; ...
        'Trial6raw_EndlessCarKinematicLog.csv'; 'Trial7raw_EndlessCarKinematicLog.csv'; ...
        'Trial8raw_EndlessCarKinematicLog.csv'; 'Trial1raw_EndlessCarEyeLog.csv'; 'Trial4raw_EndlessCarEyeLog.csv'; ...
        'Trial5raw_EndlessCarEyeLog.csv'; 'Trial6raw_EndlessCarEyeLog.csv'; ...
        'Trial7raw_EndlessCarEyeLog.csv'; 'Trial8raw_EndlessCarEyeLog.csv'};
        %used in trimming.m

%TRIMMING RAW DATA TIMEFRAME:
startKeepTime = 29999; %time frame from beginning to cut out
endTimeLow = 210510; %time to cut from there on (low range) xxxxx0
endTimeHigh = 210519; %time to cut from there on (high range) xxxxx9


%separate out trials/conditions
fixedSpeedTrials = [1, 4, 5, 8, 6, 7];
    %used in select trials
%algTrials = [3, 9];
fixedSpeedConditionsWithBL = ["baseline", "slow", "mod", "fast"];
fixedSpeedConditionsNoBL = ["slow", "mod", "fast"];


%variables in extractall --> integratedDataTable
    %mapping variables: (used in extractall.m)
        SpeedCategoryMap = containers.Map({1, 4, 5, 8, 6, 7}, {'B', 'S', 'S', 'M', 'F', 'F'});
                    %assigns speed categories to match conditions
        DistractorMap    = containers.Map({1, 4, 5, 8, 6, 7}, {'NA','N', 'Y', 'NA','N', 'Y'});
                    %assigns speed categories to match conditions
        ConditionMap    = containers.Map({1, 4, 5, 8, 6, 7}, {'baseline','slow', 'slow+', 'mod','fast', 'fast+'});
                    %assigns condition descriptors to match conditions
    
    matVariables = ["epoch", "MeanAccuracy", "MeanHeartRate", "MeanPupilDiameter", "MeanSpeedMultiplier", "SD1", "SD2", "SDNN", "SDratio"];
        %pulled from .mat files in raw data folders
    bySubjVars = ["BetaBlocker", "Sex", "DomHand", "BBTdom", "BBTnondom", "MOCA", "Lenses", "Age", "AffHand", "Chronicity", "FMA", "BBTa",	"BBTu"];
        %subject intake form and clinical testing
        %pulled in from extraBySubjVariables.csv
    subjectiveVars = ["IMIt", "IMIrelaxed", "IMIattention", "IMIinteresting", "IMItry", "IMIboring", "IMIeffort", "IMIsatisfied", "IMIanxious", "ISA"];
    byTrialVars = ["Subjective", subjectiveVars, "Order", "RR"];
        %subjective assessments, order trials were administered, RR (DV analyzed separtely and not in .mat files)
        %pulled in from extraByTrialVariables.csv







