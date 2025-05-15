%DESCRIPTION:this script 
% allows for subject/trial selection via selectSubject and selectTrials functions
    %allows for running only for new subjects
    %or can run all
% for selected subjects/trials, takes the:
    %.mat output files containing filtered, averaged DVs
            %epoch", "MeanAccuracy", "MeanHeartRate", "MeanPupilDiameter", "MeanSpeedMultiplier", "SD1", "SD2", "SDNN", "SDratio
    %.mat biopac files containing raw respiratory data
            %uses processResp to extract avg RR, avg RD, and RD max
            %asks user if they wish to re-process resp data for subjects with existing values (reduce redundant computation)
    %.csv fileS with extra bySubject (demographics/clinical tests) and byTrial variables
            %bySubj = demographics and clinical test scores
            %byTrial
                %including 'subjective' (Y if subjective assessments administered for that trial) 
                % subjectiveVars (self report IMI/ISA scores)
                    %only for trials with subjective = Y
                        
                %+ order trials were performed
    %as well as adds additional variables mapped to trial#s and subject IDs
            %trial #, condition, speed category, distractor status per trial
            % Group (subject ID H__ = healthy and S__= CVA

% and organizes them into integratedDataTable.mat (long format)
    %ind trial values temp stored in singleTrialRowTable
    %then merged into singleSubjectDataTable
    % then all added to final integratedDataTable
        %then creates (for each subject):
            %subjectiveS row (copy of slow or slow+ row where Subjective = Y)
            %subjectiveF row (copy of fast or fast+ row where Subjective = Y)
            %normalized columns for select DVs (% of BL and raw change from BL)
            %z scores for select DVs
            %of HR max for meanHeartRate

%organizes and saves updated integratedDataTable.mat

%if user selects to, separate exportDatatoFiles script can then export updated data as:
    %.csv long format table
    %wide format excel file (for quick looks and use within lab)

thesisDataAnalysisSettings;  % call script with directories/variables

%1a.DEFINE PATHS, LOAD INPUT DATA FILES, LOCATE OUTPUT FILE FOLDERS 
    rootDir = rawDataFolderDir;
         
   %Where the output files go
    outputDir = dataTablesFolderDir;


   
    %load extra subject-level data:
        %stop it from treating AffHand as a numeric var:
    opts = detectImportOptions(extraBySubjVarsDir);
    opts = setvartype(opts, 'AffHand', 'string');
    extraBySubjVars = readtable(extraBySubjVarsDir, opts);  %defined in thesisDataAnalysisSettings

    %load extra trial-level data: specifies to import bytrialvars as string (fixes entire column of NaNs)
        %opts = settings of how ML should read file
    opts = detectImportOptions(extraByTrialVarsDir); %defined in thesisDataAnalysisSettings
            %ML autodetects how it thinks it should be imported
    opts = setvartype(opts, 'Subjective', 'string');  
            % force subjective to be read as a string 
    extraByTrialVars = readtable(extraByTrialVarsDir, opts);
            %now reads the table following set opts



%%1b clean input data formatting
    %change ID and condition from cell arrays to strings so strcmp doesn't fail later 
    extraBySubjVars.ID = strtrim(string(extraBySubjVars.ID));
    extraBySubjVars.Condition = strtrim(string(extraBySubjVars.Condition));
        %strtrim cleans up extra spaces from csv just in case
    
    extraByTrialVars.ID = strtrim(string(extraByTrialVars.ID));
    extraByTrialVars.Condition = strtrim(string(extraByTrialVars.Condition));




%%%%2.DEFINE VARIABLES, TRIALS, SPEED, DISTRACTOR, and CONDITION for each trial
%variables are string array 
    %reminder string array is ["xxx","xxx"] 
    % and cell array is {'xxx','xxx'} and stores character vectors

%matvariables, bySubjVars, subjectiveVars, byTrialVars, biopacVars, mappingVars defined in thesisDataAnalysisSettings
    %matVariables = DVs pulled from the .mat files
    %bySubjVariables = demographics and clinical testing reults; 
        %pulled from extraBySubjVariables.csv
    %byTrialVars = subjectiveVars (subjective assessments), Subjective status, order, and RR 
        %pulled from extraByTrialVars.csv
        %all subjectiveVars are only assigned to rows where Subjective == yes
    %biopacVariables = new processing of resp/ecg data using new ML functions
    %mappingVars = ["Trial", "Group", "SpeedCategory", "Distractor", "Condition"];
        %speedcategory, distrctor, and condition maps defined in thesisDataAnalysiSettings
            %SpeedCategoryMap assigns speed categories to match conditions
            %DistractorMap assigns speed categories to match conditions
            %ConditionMap assigns condition descriptors to match conditions
        %group mapped in step 9
        %trial defined during step 4 by user input, then defined as t and added as column

allExpectedVars = unique(["Subject", mappingVars, matVariables, bySubjVars, byTrialVars, biopacVars]);
    %all above combined

trialsOfInterest = fixedSpeedTrials;
    %so can use to ignore trials 2, 3, 9 later (irrelevant to this script)
    %fixedSpeedTrials defined in thesisDataAnalysisSettings

            
%%%%3a. SUBJECT SELECTION (using selectSubject function)
subjInput = input('Enter subject IDs ie H1 S5...(separated by a space) or press Enter to select all: ', 's');
if isempty(subjInput)
    [selectedSubjects, subjectMap] = selectSubject(); % all subjects
else
    subjInputFormatted = strsplit(strtrim(subjInput)); 
        %strsplit splits by spaces
    [selectedSubjects, subjectMap] = selectSubject(subjInputFormatted);% selected ones
end 


%%%%%3b.TRIAL SELECTION (using selectTrials function)
userTrialInput = input('Enter trial numbers ie: 4 5 6... (separated by a space) or hit enter to run all: ', 's');
    %gets rid of specific formatting requirements 
if isempty(userTrialInput) %if don't specify, then:
    trialsToRun = selectTrials(); %run all
else
    trialNums = str2num(userTrialInput);
        %str2num converts string to numbers
    trialsToRun = selectTrials(trialNums);
        %run the trials user asks for (makes sure they're the appropriate trials for this script's functions)
end 

%3c ask if want to re-process biopac data for subjects with existing data
reprocessRespInput = input('Do you want to re-process Biopac data for subjects who already have biopac variable values? (Y/N): ', 's');
reprocessResp = strcmpi(strtrim(reprocessRespInput), 'Y');

%3d Prompt user for export after processing
exportInput = input('Do you want to update exported .csv and .xlsx files now? (Y/N): ', 's');
exportNow = strcmpi(strtrim(exportInput), 'Y');

%%%4. LOAD and prepare existing integratedDataTable.mat 
% Load existing integratedDataTable.mat 
matOutputFile = integratedDataTableDir;
    load(matOutputFile, 'integratedDataTable');

%Remove existing subjectiveS and subjectiveF rows (or will add duplicates)
integratedDataTable(integratedDataTable.Trial == 4.5 | integratedDataTable.Trial == 6.5, :) = [];

% Make sure subject and condition is a string and Trial is numeric so no errors w saving
integratedDataTable.Subject = string(integratedDataTable.Subject);
integratedDataTable.Trial   = double(integratedDataTable.Trial);

%5. create tempIntegratedDataTable for all run subject data to be stored in
    %(added to integratedDataTable at the end)
tempIntegratedDataTable = cell2table(cell(0, numel(allExpectedVars)), 'VariableNames', allExpectedVars);

%NOW,FOR ALL TRIALS OF SELECTED SUBJECTS (SUBJECT LOOP), 
for i = 1:length(selectedSubjects) %for each subject selected
    subjectName = selectedSubjects{i};
    
  %%%6. create temp table per each subject (singleSubjectDataTable- to be added to integratedDataTable)
    singleSubjectDataTable = cell2table(cell(0, numel(allExpectedVars)),'VariableNames', allExpectedVars);

    
    %Then, for each subject (still nested w/in subject loop) go through each trial (TRIAL LOOP)
%%%%%%%TRIAL LOOP: 7.load the data and extract DVs
    for t = trialsToRun
        %7a load matVariables .mat files
        matTrialFile = fullfile(rootDir, subjectMap(subjectName),'MatlabOutputFiles', sprintf('Output_Trial%d.mat', t));
            %filles in trial# w/ sprintf to find correct .mat file
                % ie: %d --> integer (ie;t--> '5')
           %loads the .mat files
        
        if exist(matTrialFile, 'file')
            data = load(matTrialFile,matVariables{:});
                %load the DVs from the mat files
        end
                    

        %7b. load biopac raw data
        biopacTrialFile = fullfile(rootDir, subjectMap(subjectName), 'Biopac', sprintf('Trial%d.mat', t));
        
        % Check if values already exist in the integrated table
        existingBiopacDataIdx = integratedDataTable.Subject == subjectName & integratedDataTable.Trial == t;
        hasExistingRespData = ~isempty(integratedDataTable.RR(existingBiopacDataIdx)) && ...
                      ~isnan(integratedDataTable.RR(existingBiopacDataIdx)) && ...
                      ~isnan(integratedDataTable.RD(existingBiopacDataIdx)) && ...
                      ~isnan(integratedDataTable.peakRD(existingBiopacDataIdx));

        
        if exist(biopacTrialFile, 'file')
            if reprocessResp || ~hasExistingRespData
                biopacRawData = load(biopacTrialFile);
                    [avgRR, avgRD, peakRD] = processResp(biopacRawData, subj, t);
                        %calling processRespData function
            else
                % Use existing values from the integratedDataTable
                avgRR = integratedDataTable.RR(existingBiopacDataIdx);
                avgRD = integratedDataTable.RD(existingBiopacDataIdx);
                peakRD = integratedDataTable.peakRD(existingBiopacDataIdx);
            end
        else
            warning('No Biopac .mat file found for Subject %s, Trial %d.', subjectName, t);
            avgRR = NaN; avgRD = NaN; peakRD = NaN;
        end
      
                
            
       %%%%8 CREATE PER TRIAL ROWS (singleTrialRow) for non DV data that can be mapped to subject ID or trial
         %(temp-to be added to per subject toAdd table
            singleTrialRow = struct();
                %clears it for each trial
            
            %8a label subject ID, trial, condition
            singleTrialRow.Subject = string(subjectName);
            singleTrialRow.Trial = t;
            conditionName = strtrim(string(ConditionMap(t)));
    
            %8b assign subject group 
            if startsWith(subjectName, 'H')
                singleTrialRow.Group = "H";
            elseif startsWith(subjectName, "S")
                singleTrialRow.Group = "CVA";
            else
                warning('subject ID does not belong in either group')
            end

            %8c assign mapping fields:
            singleTrialRow.Distractor = string(DistractorMap(t));
            singleTrialRow.SpeedCategory = string(SpeedCategoryMap(t));
            singleTrialRow.Condition = string(ConditionMap(t));

  %%9 CREATE PER SUBJECT DATA ROWS for extra by subject and by trial variables 
    
    %9a by subject variables:
            subjMatchIdx = strcmp(extraBySubjVars.ID, subjectName) & strcmp(extraBySubjVars.Condition, conditionName);
            rowMatchSubj = extraBySubjVars(subjMatchIdx, :);
                %find the right subject/trial row
           
            for v = 1:length(bySubjVars)
                varName = bySubjVars(v);
                if ~isempty(rowMatchSubj) && ismember(varName, rowMatchSubj.Properties.VariableNames)
                    singleTrialRow.(varName) = rowMatchSubj.(varName);
                else
                    singleTrialRow.(varName) = NaN;
                end
            end

    %9b by trial variables:
            trialMatchIdx = strcmp(extraByTrialVars.ID, subjectName) & strcmp(extraByTrialVars.Condition, conditionName); 
                %rows in .extraByTrialVars matching subject/trial
            
            rowMatchTrial = extraByTrialVars(trialMatchIdx, :);
                %find the right subject/trial row
        
         %'Subjective' column: normalize all missing/non-Y to "NaN" string
           if isempty(rowMatchTrial)
                continue;
            end
                %is S1 trial 1 is missing 

            subjectiveRaw = string(rowMatchTrial.Subjective);
                %makes sure value in subjective column is a string
            
         

            if ismissing(subjectiveRaw) || subjectiveRaw ~= "Y"
                singleTrialRow.Subjective = "NaN"; 
                    %if it's empty or isn't a Y, then makes it a NaN
            else
                singleTrialRow.Subjective = "Y"; %otherwise Y stays Y
            end
                
         %order column
            singleTrialRow.Order = rowMatchTrial.Order;
         
         %RR column
            %singleTrialRow.RR = rowMatchTrial.RR;
                %RR is now a biopacVar
       

        %subjective variables (IMI, ISA)
            %%find rows where subjective=Y and only assign IMI/ISA values for these trials
             for v = 1:length(subjectiveVars)
                varName = subjectiveVars(v);
                if singleTrialRow.Subjective == "Y"
                    singleTrialRow.(varName) = rowMatchTrial.(varName);
                else
                    singleTrialRow.(varName) = NaN;
                end
            end
         
    
   %%%%10. extracts .mat DVs for each trial and add to temp singleTrialTable
            for v = 1:length(matVariables)
                varName = matVariables{v};
                if isfield(data, varName) %if that DV exists in .mat file
                    val = data.(varName);
                    if isnumeric(val)
                        val = val(1); %extract scalar
                    else
                        val = NaN;
                    end
                else
                    val = NaN; %if it's not there
                end
    
                singleTrialRow.(varName) = val;
                    %adds DV to row
            end

            
    %%%11. add biopac data rows:
            singleTrialRow.RR = avgRR;
            singleTrialRow.RD = avgRD;
            singleTrialRow.peakRD = peakRD;
            %singleTrialRow.HRnew = NaN;  
                    %planning to create and integrate function for ECG processing 
                        %and add HR
     
    %%%12.add singleTrialRow table for that subject/trial to singleSubjectDataTable
         %first use struct2table to converts singleTrialRow struct array to table 
            singleTrialRowTable = struct2table(singleTrialRow);
            
         %merge them with  mergeTables function
            singleSubjectDataTable = mergeTables(singleTrialRowTable, singleSubjectDataTable);
    end %of trial loop
    
% ======= END TRIAL LOOP =======

%%13. add singleSubjectDataTable  to  tempIntegratedDataTable
tempIntegratedDataTable = mergeTables(singleSubjectDataTable, tempIntegratedDataTable);


end %of whole subject loop
% ======= END SUBJECT LOOP =======

%NOW OUTSIDE SUBJECT LOOP:  

%14. add tempIntegratedDataTable to final integratedDataTable
integratedDataTable = mergeTables(tempIntegratedDataTable, integratedDataTable);

%%%15. add SubjectiveS and SubjectiveF rows for each subject 
    %(for subjective correlations with speed)
         %subjectiveS is slow or slow+ row where subjective = Y
        %subjectiveF is fast or fast+ row where subjective = Y
subjList = unique(integratedDataTable.Subject);
    %grab list of subjects (unique stops dulicate IDs)

% double checks again that key columns are string-typed and trimmed or strcmp doesn't work below
integratedDataTable.Subject = strtrim(string(integratedDataTable.Subject));
integratedDataTable.Condition = strtrim(string(integratedDataTable.Condition));
integratedDataTable.Subjective = strtrim(string(integratedDataTable.Subjective));

for s = 1:length(subjList) %for each subject
    subj = subjList(s); 
           
    % Filter for slow trials with Subjective == "Y"
    slowSubjTrials = integratedDataTable( ...
        integratedDataTable.Subject == subj & ...
        ismember(integratedDataTable.Trial, [4, 5]) & ...
        integratedDataTable.Subjective == "Y", :);

    % Filter for fast trials with Subjective == "Y"
    fastSubjTrials = integratedDataTable( ...
        integratedDataTable.Subject == subj & ...
        ismember(integratedDataTable.Trial, [6, 7]) & ...
        integratedDataTable.Subjective == "Y", :);

    % --- Add subjectiveS (4 or 5 with subj = Y)
    if ~isempty(slowSubjTrials)
        subjectiveSRow = slowSubjTrials(1, :); % take the first valid one (only one will exist)
        subjectiveSRow.Condition = "subjectiveS";
        subjectiveSRow.Trial = 4.5;
        integratedDataTable = mergeTables(subjectiveSRow, integratedDataTable);
    end

    % --- Add subjectiveF (6 or 7 with subj = Y)
    if ~isempty(fastSubjTrials)
        subjectiveFRow = fastSubjTrials(1, :); % again, only one should match
        subjectiveFRow.Condition = "subjectiveF";
        subjectiveFRow.Trial = 6.5;
        integratedDataTable = mergeTables(subjectiveFRow, integratedDataTable);
    end
end

       
%16 manually adjust some variables for certain trials and add normalized DVs:

 %make MeanAccuracy  NaN for all trial 1 (baseline) rows
if any(integratedDataTable.Trial == 1)
    integratedDataTable.MeanAccuracy(integratedDataTable.Trial == 1) = NaN;
end
    
 %add columns for 
    % DVs nornmalized to BL (+%HR max)
    % DV change from BL (raw)
    %zscores

        %columns/calcs prepared to add for HRnew
            %but currently commented out

    %first create new columns 
        %for norm_BL:
integratedDataTable.HR_normBL = NaN(height(integratedDataTable),1);
%integratedDataTable.HRnew_normBL = NaN(height(integratedDataTable),1);
integratedDataTable.Percent_HR_Max = NaN(height(integratedDataTable),1);
integratedDataTable.Pupil_normBL = NaN(height(integratedDataTable),1);
integratedDataTable.RR_normBL = NaN(height(integratedDataTable),1);
integratedDataTable.RD_normBL = NaN(height(integratedDataTable), 1);

        
    %for raw change from BL:
integratedDataTable.Delta_HR_BL = NaN(height(integratedDataTable),1);
%integratedDataTable.Delta_HRnew_BL = NaN(height(integratedDataTable),1);
integratedDataTable.Delta_Pupil_BL = NaN(height(integratedDataTable),1);
integratedDataTable.Delta_RR_BL = NaN(height(integratedDataTable),1);
integratedDataTable.Delta_RD_BL = NaN(height(integratedDataTable),1);

        %for z scores:
integratedDataTable.z_HR = NaN(height(integratedDataTable),1);
%integratedDataTable.z_HRnew = NaN(height(integratedDataTable),1);
integratedDataTable.z_Pupil = NaN(height(integratedDataTable),1);
integratedDataTable.z_RR = NaN(height(integratedDataTable),1);
integratedDataTable.z_RD = NaN(height(integratedDataTable),1);


subjects = unique(integratedDataTable.Subject);


for s = 1:length(subjects)
    subj = subjects(s);
    

    % Grab all this subject's rows
    subjIdx = integratedDataTable.Subject == subj;
            %all rows for that subject
    baselineIdx = subjIdx & integratedDataTable.Trial == 1;
            % trial 1 rows for that subject only
    normTrialIdx = subjIdx & integratedDataTable.Trial ~= 1;
            %all other rows but trial 1 for that subject


    % all rows DV values for that subject):
    subjHR = integratedDataTable.MeanHeartRate(subjIdx);
    %subjHRnew = integratedDataTable.HRnew(subjIdx); %new from biopac
    subjPupil = integratedDataTable.MeanPupilDiameter(subjIdx);
    subjRR = integratedDataTable.RR(subjIdx);
    subjRD = integratedDataTable.RD(subjIdx); 


    %baseline DV values (trial 1):
    HR_baseline = integratedDataTable.MeanHeartRate(baselineIdx);
    %HRnew_baseline = integratedDataTable.HRnew(baselineIdx);
    Pupil_baseline = integratedDataTable.MeanPupilDiameter(baselineIdx);
    RR_baseline = integratedDataTable.RR(baselineIdx);
    RD_baseline = integratedDataTable.RD(baselineIdx);



    % do BL normalizations
    if any(baselineIdx) % if baseline exists
        % Define DVs, normalized columns, and delta columns
        DVs = ["MeanHeartRate", "MeanPupilDiameter", "RR", "RD"];
            %add "HRnew
        NormCols = ["HR_normBL", "Pupil_normBL", "RR_normBL", "RD_normBL"];
           %add "HRnew_normBL
        DeltaCols = ["Delta_HR_BL", "Delta_Pupil_BL", "Delta_RR_BL", "Delta_RD_BL"];
            %add "Delta_HRnew_BL 
    
        % loop through HR, pupil, RR, and RD to do norm and raw delta columns:
        for d = 1:length(DVs)
            dv = DVs(d);
            normCol = NormCols(d);
            deltaCol = DeltaCols(d);
    
            integratedDataTable.(normCol)(normTrialIdx) = integratedDataTable.(dv)(normTrialIdx) ./ integratedDataTable.(dv)(baselineIdx);
            integratedDataTable.(deltaCol)(normTrialIdx) = integratedDataTable.(dv)(normTrialIdx) - integratedDataTable.(dv)(baselineIdx);
        end

    else %if no baseline, all normalized/delta columns are NaN
        integratedDataTable.HR_normBL(subjIdx) = NaN;
        %integratedDataTable.HRnew_normBL(subjIdx) = NaN;
        integratedDataTable.Pupil_normBL(subjIdx) = NaN;
        integratedDataTable.RR_normBL(subjIdx) = NaN;
        integratedDataTable.RD_normBL(subjIdx) = NaN;

        integratedDataTable.Delta_HR_BL(subjIdx) = NaN;
        %integratedDataTable.Delta_HRnew_BL(subjIdx) = NaN;
        integratedDataTable.Delta_Pupil_BL(subjIdx) = NaN;
        integratedDataTable.Delta_RR_BL(subjIdx) = NaN;
        integratedDataTable.Delta_RD_BL(subjIdx) = NaN;

    %and trial 1 is left as NaN
    end


    %for all trials (subjIdx), add %age adjusted HRmax for HR values
    Age = integratedDataTable.Age(find(subjIdx,1));
    if ~isnan(Age)
        maxHR = 220 - Age;
        integratedDataTable.Percent_HR_Max(subjIdx) = (integratedDataTable.MeanHeartRate(subjIdx) ./ maxHR) * 100;
    end  

    %for all trials (subjIdx), add zscores
        %ADD FOR HRNEW IF DECIDE TO SWITCH

    if sum(~isnan(subjHR)) > 1 %(ie if have at least 1 HR value across trials)
        integratedDataTable.z_HR(subjIdx) = (subjHR - nanmean(subjHR)) / nanstd(subjHR);
            %nanmean = avg of HRs across all trials (-NaNs)
            %nanSD = SD across all trials (-NaNs)
    end

    if sum(~isnan(subjPupil)) > 1
        integratedDataTable.z_Pupil(subjIdx) = (subjPupil - nanmean(subjPupil)) / nanstd(subjPupil);
    end
    
    if sum(~isnan(subjRR)) > 1
        integratedDataTable.z_RR(subjIdx) = (subjRR - nanmean(subjRR)) / nanstd(subjRR);
    end

    if sum(~isnan(subjRD)) > 1
         integratedDataTable.z_RD(subjIdx) = (subjRD - nanmean(subjRD)) / nanstd(subjRD);
    end

    %ADD Z SCORES FOR HRNEW IF DECIDE TO
    % if sum(~isnan(subjHRnew)) > 1
    %     integratedDataTable.z_HRnew(subjIdx) = (subjHRnew - nanmean(subjHRnew)) / nanstd(subjHRnew);
    % end
  
end


%%% 17 organize and save updated .mat file

% Reorder integratedDataTable columns
coreCols = ["Subject", "Trial", "Condition"];

% Combine in desired order
desiredOrder = [coreCols, matVariables, biopacVars, byTrialVars, bySubjVars];
% Get any remaining columns not already included
existingCols = integratedDataTable.Properties.VariableNames;
remainingCols = setdiff(existingCols, desiredOrder, 'stable');

% Final reordered table
integratedDataTable = integratedDataTable(:, [desiredOrder, remainingCols]);

save(matOutputFile, 'integratedDataTable');

% 18. Export if user selected to
if exportNow
    run('exportDatatoFiles.m');
end
