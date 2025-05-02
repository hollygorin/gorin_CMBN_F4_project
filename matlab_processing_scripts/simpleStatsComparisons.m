%this script uses the runDVANOVAS function to run mixed-methods ANOVAS comparing DVs
    %within subjects by speed
        %raw data (and %HR max) for BL, S, M, F
        %norm data by S, M, F
    %between subjects by group

thesisDataAnalysisSettings;  % call script with directories/variables

load(fullfile(dataTablesFolderDir, 'integratedDataTable.mat'));

% Conditions
%fixedSpeedConditionsWithBL and fixedSpeedConditionsNoBL defined in thesisDataAnalysisSettings

% makes tables for data of interest
%anovaSpeedDVsWithBL = integratedDataTable(ismember(integratedDataTable.Condition, fixedSpeedConditionsWithBL), :);
anovaSpeedDVsNoBL = integratedDataTable(ismember(integratedDataTable.Condition, fixedSpeedConditionsNoBL), :);

% DVs
DVraw = {'MeanHeartRate', 'Percent_HR_Max', 'MeanPupilDiameter', 'RR'};
DVnorm = {'MeanHeartRate', 'Percent_HR_Max', 'HR_normBL', 'MeanPupilDiameter', 'Pupil_normBL', 'RR_normBL'};

% Run ANOVAs
runDVANOVAs(DVraw, anovaSpeedDVsWithBL, speedConditions);
runDVANOVAs(DVnorm, anovaSpeedDVsNoBL, speedConditionsNoBL);
