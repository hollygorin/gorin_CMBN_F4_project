%this script uses the runDVANOVAS function to run mixed-methods ANOVAS comparing DVs
    %within subjects by speed
        %raw data (and %HR max) for BL, S, M, F
        %norm data by S, M, F
    %between subjects by group

% Conditions
speedConditions = ["baseline", "slow", "mod", "fast"];
    %for raw data and %HRmax comparisons
speedConditionsNorm = ["slow", "mod", "fast"];
    %for data norm to BL comparisons

% makes tables for data of interest
anovaData = statsFormatTable(ismember(statsFormatTable.Condition, speedConditions), :);
anovaDataNorm = statsFormatTable(ismember(statsFormatTable.Condition, speedConditionsNorm), :);

% DVs
dvNames = {'MeanHeartRate', 'Percent_HR_Max', 'MeanPupilDiameter', 'RR'};
dvNamesNorm = {'Pupil_normBL', 'RR_normBL'};

% Run ANOVAs
runDVANOVAs(dvNames, anovaData, speedConditions);
runDVANOVAs(dvNamesNorm, anovaDataNorm, speedConditionsNorm);
