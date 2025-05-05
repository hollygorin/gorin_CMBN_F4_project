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


%graphing:
    %color palletes:

        random40 = lines(40);

        black = repmat([0 0 0], 100, 1);
        
        bluePallete = [
            0.27, 0.51, 0.71;   % steel blue
            0.35, 0.70, 0.90;   % sky blue
            0.25, 0.65, 0.60;   % teal
            0.40, 0.80, 0.67;   % aquamarine
            0.60, 0.73, 0.85;   % light blue
            0.23, 0.39, 0.57;   % navy-ish
            0.51, 0.74, 0.78;   % soft cyan
            0.47, 0.60, 0.76;   % muted periwinkle
            0.31, 0.59, 0.76;   % mid blue
            0.19, 0.44, 0.60;   % slate blue
            0.26, 0.60, 0.73;   % muted turquoise
            0.33, 0.65, 0.75;   % soft ice blue
            0.42, 0.68, 0.88;   % powder blue
            0.29, 0.52, 0.65;   % marine blue
            0.22, 0.48, 0.68    % desaturated ocean blue
        ];

        rainbow = [
            0.10 0.40 0.90;     % electric blue
            0.98, 0.80, 0.25;   % gold yellow
            0.60 0.90 0.20;     % lime green
            0.90, 0.55, 0.45;   % salmon
            0.55, 0.80, 0.80;   % light teal
            0.95, 0.60, 0.30;   % soft orange
            0.35, 0.65, 0.85;   % sky blue
            1.00 0.90 0.10;     % bold yellow
            0.40, 0.75, 0.60;   % mint green
            0.75, 0.40, 0.65;   % rose
            0.60, 0.75, 0.25;   % olive green
            0.60, 0.50, 0.75;   % lavender purple
            0.20, 0.40, 0.70;   % deep blue
            0.80, 0.40, 0.40;   % muted red
            0.50, 0.60, 0.80;   % dusty blue
            0.75, 0.25, 0.25;   % brick red
            0.20, 0.60, 0.20;   % forest green
            0.25, 0.75, 0.75    % aqua teal
            0.90 0.20 0.50;     % vivid pink
            0.70, 0.30, 0.55;   % dusty rose
            0.45, 0.45, 0.70;   % steel blue
            0.85, 0.50, 0.20;   % burnt orange
            0.70, 0.70, 0.70    % medium gray
            0.60, 0.30, 0.30;   % cocoa
            0.60, 0.70, 0.90;   % light periwinkle
            
        ];






