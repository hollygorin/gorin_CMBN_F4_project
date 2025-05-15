%this script uses the runDVANOVAS function to run mixed-methods ANOVAS comparing DVs
    %within subjects by speed
    %between subjects by group

thesisDataAnalysisSettings;  % call script with directories/variables

load(fullfile(dataTablesFolderDir, 'integratedDataTable.mat'));


    
% Run ANOVAs via function runDVANOVAs(dvNames, anovaDataTable, speedConditions)
%runDVANOVAs(DVraw, TablefixedSpeedConditionsWithBL, fixedSpeedConditionsWithBL);
runDVANOVAs(DVraw, TablefixedSpeedConditionsNoBL, fixedSpeedConditionsNoBL);
