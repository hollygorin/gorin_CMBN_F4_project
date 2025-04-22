%DESCRIPTION:this script takes the:
    %.mat output files containing filtered, averaged DVs
    %.csv file with extra bySubject variables
    %.csv file with extra byTrial variables
    %adds additional variables mapped to trial#s and subject IDs
% and organizes them into a long format matlab table
    %separate script exportDatatoFiles script can then export info as:
        %.csv long format table
        %wide format excel file (for quick looks and use within lab)

%%%1.DEFINE PATHS (where to find input files and where to save output files)
% Where the subject folders are with .mat files:
rootDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/RawData/';

%Where the extra variables not found in .mat files are:
%load extra subject-level data:
extraBySubjVars = readtable('/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables/extraBySubjVars.csv');

%load extra trial-level data:
        %tellsmatlab to import bytrialvars in certain formats when uses readtable (fixes entire column being NaNs)
opts = detectImportOptions('/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables/extraByTrialVars.csv');
opts = setvartype(opts, 'Subjective', 'string');  % force it to import as string 
extraByTrialVars = readtable('/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables/extraByTrialVars.csv', opts);

%change ID and condition from cell arrays to strings so strcmp doesn't fail later 
extraBySubjVars.ID = strtrim(string(extraBySubjVars.ID));
extraBySubjVars.Condition = strtrim(string(extraBySubjVars.Condition));
    %strtrim cleans up extra spaces from csv just in case

extraByTrialVars.ID = strtrim(string(extraByTrialVars.ID));
extraByTrialVars.Condition = strtrim(string(extraByTrialVars.Condition));

% Where the output files go
outputDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables';


%%%%2.DEFINE VARIABLES, TRIALS, SPEED, DISTRACTOR, and CONDITION for each
%%%%trial
matVariables = ["epoch", "MeanAccuracy", "MeanHeartRate", "MeanPupilDiameter", "MeanSpeedMultiplier", "SD1", "SD2", "SDNN", "SDratio"];
    %changed to string array instead of cell array (which stores character vectors)
    %reminder string array is ["xxx","xxx"] and cell array is {'xxx','xxx'}
    %matVariables are just ones pulled from the .mat files
bySubjVars = ["BetaBlocker", "Sex", "DomHand", "BBTdom", "BBTnondom", "MOCA", "Lenses", "Age", "AffHand", "Chronicity", "FMA", "BBTa",	"BBTu"];
    %pull in from separate .csv
subjTrialVars = ["IMIt", "IMIrelaxed", "IMIattention", "IMIinteresting", "IMItry", "IMIboring", "IMIeffort", "IMIsatisfied", "IMIanxious", "ISA"];
byTrialVars = ["Subjective", subjTrialVars, "Order"];
    %pull in from separate .csv
    % all subjTrialVars are only assigned to rows where Subjective == yes
mappingVars = ["Trial", "Group", "SpeedCategory", "Distractor", "Condition"];
    %speedcategory, distrctor, and condition defined in maps below- have patterns to trials
    %group mapped in step 9
    %trial defined during step 4 by user input, then defined as t and added as column
allExpectedVars = unique(["Subject", mappingVars, matVariables, bySubjVars, byTrialVars]);
    %all above combined

SpeedCategoryMap = containers.Map({1, 4, 5, 8, 6, 7}, {'B', 'S', 'S', 'M', 'F', 'F'});
            %assigns speed categories to match conditions
DistractorMap    = containers.Map({1, 4, 5, 8, 6, 7}, {'NA','N', 'Y', 'NA','N', 'Y'});
            %assigns speed categories to match conditions
ConditionMap    = containers.Map({1, 4, 5, 8, 6, 7}, {'baseline','slow', 'slow+', 'mod','fast', 'fast+'});
            %assigns condition descriptors to match conditions

trialsOfInterest = [1, 4, 5, 8, 6, 7];
    %so can use to ignore trials 2, 3, 9 later (irrelevant to this script)


            
%%%%3. SUBJECT SELECTION
%select subjects to process using selectSubject function and prompt for input
subjInput = input('Enter subject IDs ie H1 S5...(separated by a space) or press Enter to select all: ', 's');
if isempty(subjInput)
    selectedSubjects = selectSubject();  % all subjects
else
    subjInputFormatted = strsplit(strtrim(subjInput)); 
        %strsplit splits by spaces
    selectedSubjects = selectSubject(subjInputFormatted);  % specific ones
end %of if/else

%get map from createSubjectIDMap function
subjectMap = createSubjectIDMap();


%%%%%4.TRIAL SELECTION
%pick which trials from selectTrials function
userTrialInput = input('Enter trial numbers ie: 4 5 6... (separated by a space) or hit enter to run all: ', 's');
    %gets rid of specific formatting requirements 
if isempty(userTrialInput) %if don't specify, then:
    trialsToRun = trialsOfInterest; %run all
else
    userTrialInputFormatted = str2num(userTrialInput); 
        %str2num converts string to numbers
    trialsToRun = intersect(userTrialInputFormatted, trialsOfInterest);
        %run the trials user asks for (makes sure they're the appropriate trials for this script's functions)
end %of if-else


%%%%%5. SKIP EXPORT (default to only update .mat file)
%can use separate export mat data file


%%%6. LOAD FINAL MATLAB TABLES for stats format for use in matlab
% Load existing statsFormatTable.mat 
matOutputFile = fullfile(outputDir, 'StatsFormatTable.mat');
load(matOutputFile, 'statsFormatTable');

% Make sure Subject is a string and Trial is numeric so no errors w saving
statsFormatTable.Subject = string(statsFormatTable.Subject);
statsFormatTable.Trial   = double(statsFormatTable.Trial);


%NOW,FOR ALL TRIALS OF SELECTED SUBJECTS (SUBJECT LOOP), 
for i = 1:length(selectedSubjects) %for each subject selected
    subjectName = selectedSubjects{i};
    subjectPath = fullfile(rootDir, subjectMap(subjectName),'MatlabOutputFiles');
    
  %%%7. create per subject matlab table (temp- to be added to final table)
    
    allExpectedVars = unique([ "Subject", mappingVars, matVariables, bySubjVars, byTrialVars ]);
    addToStatsFormatTable = cell2table(cell(0, numel(allExpectedVars)),'VariableNames', allExpectedVars);
        %otherwise subject header doesn't get stored as variable names --> error
        %unique avoids duplicate headers
    
    %Then go through each trial (TRIAL LOOP (w/in subject loop) and, for each trial:
%%%%%%%TRIAL LOOP: 8.load the data and extract DVs
    for t = trialsToRun
        trialFile = fullfile(subjectPath, sprintf('Output_Trial%d.mat', t));
            %filles in trial# w/ sprintf to find correct .mat file
                % ie: %d --> integer (ie;t--> '5')
           %loads the .mat files
        
    if exist(trialFile, 'file')
        data = load(trialFile,matVariables{:});
                %load the DVs from the mat files
        
   %%%%9 CREATE PER SUBJECT STATS ROWS for non DV data that can be mapped to subject ID or trial
     %(temp-to be added to per subject toAdd table
        statsRow = struct();
            %clears it for each trial
        statsRow.Subject = string(subjectName);
        statsRow.Trial = t;

        if startsWith(subjectName, 'H')
            statsRow.Group = "H";
        elseif startsWith(subjectName, "S")
            statsRow.Group = "CVA";
        else
            warning('subject ID does not belong in either group')
        end

        statsRow.Distractor = string(DistractorMap(t));
        statsRow.SpeedCategory = string(SpeedCategoryMap(t));
        statsRow.Condition = string(ConditionMap(t));

    %%%10 CREATE PER SUBJECT STATS ROWS for by subject and by trial variables not found in .mat files 
        %by subject variables:
            %reminder bySubjVars = ["BetaBlocker", "Sex", "DomHand", "BBTdom", "BBTnondom", "MOCA", "Lenses", "Age", "AffHand", "Chronicity", "FMA", "BBTa",	"BBTu"];
        
        %make sure these are strings bc using strcmp
        subjectName = strtrim(string(subjectName));
        conditionName = strtrim(string(ConditionMap(t)));

        subjMatchIdx = strcmp(extraBySubjVars.ID, subjectName) & strcmp(extraBySubjVars.Condition, conditionName);
        rowMatchSubj = extraBySubjVars(subjMatchIdx, :);
            %find the right subject/trial row
       
        for v = 1:length(bySubjVars)
            varName = bySubjVars(v);
            if ~isempty(rowMatchSubj) && ismember(varName, rowMatchSubj.Properties.VariableNames)
                statsRow.(varName) = rowMatchSubj.(varName);
            else
                statsRow.(varName) = NaN;
            end
        end


        %by trial variables:
            %reminder byTrialVars = ["Subjective", "IMIt", "IMIrelaxed", "IMIattention", "IMIinteresting", "IMItry", "IMIboring", "IMIeffort", "IMIsatisfied", "IMIanxious", "ISA", "Order"];
            %order has a value for all trials
            %Subjective is:
                %always NaN for trial1
                % Y for 2/4 of trials 4-7(diff for each subject)
                    %and NaN for other 2
                %Y for trial8
            %the rest of the byTrialVars (IMI/ISA subjective assessments) only have values for trials where subjectivs is Y
     
         %make sure these are strings bc using strcmp
        subjectName = strtrim(string(subjectName));
        conditionName = strtrim(string(ConditionMap(t)));

        trialMatchIdx = strcmp(extraByTrialVars.ID, subjectName) & strcmp(extraByTrialVars.Condition, conditionName);           
        
        rowMatchTrial = extraByTrialVars(trialMatchIdx, :);
            %find the right subject/trial row
        
        %  'Subjective' column: normalize all missing/non-Y to "NaN" string
        subjectiveRaw = string(rowMatchTrial.Subjective);
            %makes sure value in subjective column is a string

        if ismissing(subjectiveRaw) || subjectiveRaw ~= "Y"
                %if it's empty or isn't a Y, then makes it a NaN
            statsRow.Subjective = "NaN";  
        else
            statsRow.Subjective = "Y"; %otherwise Y stays Y (right format)
        end
        
        subjectiveVal = statsRow.Subjective;

        statsRow.Order = rowMatchTrial.Order;


        %%find rows where subjective=Y and only assign IMI/ISA values for trials w Subjective=Y
            %reminder: subjTrialVars = ["IMIt", "IMIrelaxed", "IMIattention", "IMIinteresting", "IMItry", "IMIboring", "IMIeffort", "IMIsatisfied", "IMIanxious", "ISA"];
            %set subejctive column to Y or NaN
         for v = 1:length(subjTrialVars)
            varName = subjTrialVars(v);
            if subjectiveVal == "Y"
                statsRow.(varName) = rowMatchTrial.(varName);
            else
                statsRow.(varName) = NaN;
            end
        end
     

    %%%%11. extracts values for .mat DVs for each trial and add to temp statsRowTable
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

            statsRow.(varName) = val;
                %adds DV to row
        end


    
     %%%12.add statsRow table for that subject/trial to addToStatsFormatTable
        statsRowTable = struct2table(statsRow);
                %struct2table converts structure array to table so can be merged with addToStatsFormatTable

        % Add missing columns to statsRowTable so it matches addToStatsFormatTable
        missingCols = setdiff(addToStatsFormatTable.Properties.VariableNames, statsRowTable.Properties.VariableNames);
        for m = 1:length(missingCols)
            statsRowTable.(missingCols{m}) = NaN;
        end
    
        % Reorder columns to match so can be merged
        statsRowTable = statsRowTable(:, addToStatsFormatTable.Properties.VariableNames);
        
        %merge them:
        addToStatsFormatTable = [addToStatsFormatTable; statsRowTable];
        end %of if exist (trialfile)
        end %of trial loop


 %%%13. add toAdd table to final statsformat ML table
    % both tables need to match formats
    addToStatsFormatTable.Subject = string(addToStatsFormatTable.Subject);
    addToStatsFormatTable.Trial = double(addToStatsFormatTable.Trial);
    statsFormatTable.Subject = string(statsFormatTable.Subject);
    statsFormatTable.Trial = double(statsFormatTable.Trial);


    % Convert cell array columns in addToStatsFormatTable to string (to match statsFormatTable)
        %shouldn't need anymore, but doesn't hurt to keep
    varTypes = varfun(@class, addToStatsFormatTable, 'OutputFormat', 'cell');
    for v = 1:numel(varTypes)
        varName = addToStatsFormatTable.Properties.VariableNames{v};
        if strcmp(varTypes{v}, 'cell') && ismember(varName, statsFormatTable.Properties.VariableNames)
            addToStatsFormatTable.(varName) = string(addToStatsFormatTable.(varName));
        end
    end

    % Ensure column order matches 
        %don't need anymore, but don't think it hurts to keep
    addToStatsFormatTable = addToStatsFormatTable(:, statsFormatTable.Properties.VariableNames);

    % Remove duplicates from existing .mat table
    [~, dupIdx] = ismember(addToStatsFormatTable(:, {'Subject','Trial'}), ...
               statsFormatTable(:, {'Subject','Trial'}), 'rows');
    statsFormatTable(dupIdx(dupIdx ~= 0), :) = [];
    % and add new rows
    statsFormatTable = [statsFormatTable; addToStatsFormatTable];

end %of whole subject loop

%NOW OUTSIDE SUBJECT LOOP:  

%%%14. add SubjS and SubjF rows for each subject 
    %(for subjective correlations with speed)
         %subjS is slow or slow+ row where subjective = Y
        %subjF is fast or fast+ row where subjective = Y
subjList = unique(statsFormatTable.Subject);
    %grab list of subjects (unique stops dulicate IDs)

for s = 1:length(subjList) %for each subject
    subj = subjList(s); 
        
        %logical index vectors for rows of interest:
    slowIdx = strcmp(statsFormatTable.Subject, subj) & ...
              ismember(statsFormatTable.Condition, ["slow", "slow+"]) & ...
              statsFormatTable.Subjective == "Y";
                %strcmp compares subject name
                %ismember checks if its one of the slow conditions       
    fastIdx = strcmp(statsFormatTable.Subject, subj) & ...
              ismember(statsFormatTable.Condition, ["fast", "fast+"]) & ...
              statsFormatTable.Subjective == "Y";
                %strcmp compares subject name
                %ismember checks if its one of the fast conditions

     %finding and adding those rows
        %%slow:
    subjSRow = statsFormatTable(slowIdx, :); 
        %pulls that row
    subjSRow.Condition(:) = "subjS";
        %condition filler
    subjSRow.Trial(:) = 4.5;
        %trial# filler
    statsFormatTable = [statsFormatTable; subjSRow];
        %add row to full table

        %%fast:
    subjFRow = statsFormatTable(fastIdx, :);
        %pulls that row
    subjFRow.Condition(:) = "subjF";
        %condition filler
    subjFRow.Trial(:) = 6.5;
        %trial# filler
    statsFormatTable = [statsFormatTable; subjFRow];
         %add row to full table
end
       
%14 manually adjust some variables for certain trials:
if any(statsFormatTable.Trial == 1)
    statsFormatTable.MeanAccuracy(statsFormatTable.Trial == 1) = NaN;
end
    % make MeanAccuracy  NaN for all trial 1 (baseline) rows

%%% 15 organize and save updated .mat file
statsFormatTable = sortrows(statsFormatTable, {'Subject','Trial'});

save(matOutputFile, 'statsFormatTable');

