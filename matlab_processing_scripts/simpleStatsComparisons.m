%this script uses the runDVANOVAS function to run mixed-methods ANOVAS comparing DVs
    %within subjects by speed
        %raw data (and %HR max) for BL, S, M, F
        %norm data by S, M, F
    %between subjects by group

load('/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables/StatsFormatTable.mat');

% Conditions
%speedConditionsWithBL = ["baseline", "slow", "mod", "fast"];
    %for raw data and %HRmax comparisons
speedConditionsNoBL = ["slow", "mod", "fast"];
    %for data norm to BL comparisons

% makes tables for data of interest
%anovaDataWithBL = statsFormatTable(ismember(statsFormatTable.Condition, speedConditions), :);
anovaDataNoBL = statsFormatTable(ismember(statsFormatTable.Condition, speedConditionsNoBL), :);

% DVs
dvNamesWithBL = {'MeanHeartRate', 'Percent_HR_Max', 'MeanPupilDiameter', 'RR'};
dvNamesNoBL = {'MeanHeartRate', 'Percent_HR_Max', 'HR_normBL', 'MeanPupilDiameter', 'Pupil_normBL', 'RR_normBL'};

% Run ANOVAs
%runDVANOVAs(dvNamesWithBL, anovaDataWithBL, speedConditions);
runDVANOVAs(dvNamesNoBL, anovaDataNoBL, speedConditionsNoBL);
