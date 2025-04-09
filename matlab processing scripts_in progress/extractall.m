%takes the .mat output files containing filtered, averaged DVs and
%organizes them into 2 tables with different formats 

% Where the subject folders are
rootDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/RawData';

% Where the output excel file is 
outputDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables';

excelOutput = fullfile(outputDir, 'ExtractedAllbyDV.xlsx'); %streamlines path to output file
variables = {'epoch', 'MeanAccuracy', 'MeanHeartRate', 'MeanPupilDiameter', 'MeanSpeedMultiplier', 'SD1', 'SD2', 'SDNN', 'SDratio'};  

trialsOfInterest = [1, 4, 5, 8, 6, 7];
trialColumnMap = containers.Map(trialsOfInterest, 2:7); %puts columns in right order-creates directory


allRawDataFolder = dir(rootDir); %pulls everything from the raw data folder (folders and files) --> structure array
subjectFolders = allRawDataFolder([allRawDataFolder.isdir]); 
    %isdir gets rid of files and just keeps folders (aka directories)
subjectFolders = subjectFolders(~ismember({subjectFolders.name}, {'.', '..'}));
    %gets rid of 'system entry' folders so just takes subject folders
    %pulls the name of each subject folder to display below

subjectList = {subjectFolders.name};

%lists all subjects numbered
for i = 1:length(subjectList)
    fprintf('%2d: %s\n', i, subjectList{i});
        %%2d=right aligned # labeling each subject
        %s = string = folder name (subjectsFolders)
        %\n = new line
end

%pick which subject from the numbered list
subjectIndex = input('\nWhich subject?');
subjectName = subjectFolders(subjectIndex).name; %pulls folder name for selected subject

%pull the right .mat files:
subjectPath = fullfile(rootDir, subjectName, 'MatlabOutputFiles');

%lists which trials are there
trialFiles = dir(fullfile(subjectPath, 'Output_Trial*.mat'));
%pulls just the file names
trialNames = {trialFiles.name};

%pulls just the number from the file name- pulls the %d part
trialNumbers = cellfun(@(x) sscanf(x, 'Output_Trial%d.mat'), trialNames);

%pick which trial(s)
disp(trialNumbers') 

trialChoice = input('Which trial? (or put 0 to run all): ');

if trialChoice == 0
    trialsToRun = trialNumbers;  %run all trials
else
    trialsToRun = trialChoice;   %run the selected trial
end

%pick whether to save to ExtractedAllbyDV.xlsx, to StatsFormat.csv, or both
fprintf('1 = Only ExtractedAllbyDV.xlsx \n');
fprintf('2 = Only StatsFormat.csv \n');
fprintf('3 = Both \n');
saveChoice = input('1, 2, or 3): ');

saveExtractedAllbyDV = ismember(saveChoice, [1, 3]);
saveStatsFormat   = ismember(saveChoice, [2, 3]);

%FOR EXTRACTEDALLBYDV:
%structure output table:
trialsToRun = intersect(trialsToRun, trialsOfInterest); % will ignore alg trials 3 and 9

%loop through all the variables:
for v = 1:length(variables)
    varName = variables{v}; %pulls the variable names defined before
    subjectData.(varName) = NaN(1, max(trialsOfInterest));  % put NaNs as placeholders to fix the variables not existing in the subjectData struct error
        %creates structure for subjectData struct that can then hold all the info
end

%extract data:


for t = trialsToRun
    trialFile = fullfile(subjectPath, sprintf('Output_Trial%d.mat', t));
        %sprintf inserts the trial number

    if exist(trialFile, 'file')
        load(trialFile, variables{:});  % opens the .mat file
        for v = 1:length(variables) %for all variables
            varName = variables{v}; %pulls variable name
            if exist(varName, 'var')
                value = eval(varName); %takes the value
                subjectData.(varName)(1, t) = value; %stores it in subjectData struct
            end
        end
    end
end

%check and make sure it exists (helped troubleshoot):
disp('subjectData before writecell to excel:');
disp(subjectData);

%store in output excel file
if saveExtractedAllbyDV
    for v = 1:length(variables)
        sheetName = variables{v};  % names the excel sheets
        varRow = subjectData.(sheetName);  
            %the row holds the DV designated by the sheet name
    
        outputInProgress = readcell(excelOutput, 'Sheet', sheetName);
           
        existingSubjects = outputInProgress(2:end, 1);  %pulls the subject's names from the first column
        rowIdx = find(strcmp(existingSubjects, subjectName)) + 1;  % Find existing row for that subject 
            %strcmp compares existing subjects list with the subject you pick
            %to see if it's there and which row
            %(+1 to account for trial label row); ie excel row 3 = rowIDx of 4

        % if the subject hasn't been run before, makes a row for that subject
        if isempty(rowIdx)
            rowIdx = size(outputInProgress, 1) + 1;  
        end

        %put everything in the right column (subject ID, trials 1, 4, 5, 8, 6, 7)
        outputInProgress{rowIdx, 1} = subjectName;  % first column = subject name 
        
        for t = trialsToRun
            if isKey(trialColumnMap, t) %checks to see if a column for that trial # exists
                colIdx = trialColumnMap(t); %looks up what column we assigned that trial# to in the directory
                outputInProgress{rowIdx, colIdx} = varRow(t);
            end
        end
    
        % writecell doesn't support 'missing' but sometimes readcell inserts 'missing', so convert to Nan 
        for r = 1:size(outputInProgress, 1) %for all excel rows
            for c = 1:size(outputInProgress, 2) %and all columns
                if ismissing(outputInProgress{r, c}) %checks each cell to see if it's 'missing'
                    if c == 1
                        outputInProgress{r, c} = "";  % first column is subject name, so replace 'missing' with string
                    else
                        outputInProgress{r, c} = NaN; % data columns, so replace 'missing' with NaN
                    end
                end
            end
        end

        writecell(outputInProgress, excelOutput, 'Sheet', sheetName);
    end
end


%FOR STATSFORMAT:
if saveStatsFormat
    statsFormatCSV = fullfile(outputDir, 'StatsFormat.csv');

    existingTable = readtable(statsFormatCSV); %takes existing statsformat.csv and brings into ML

    % Trials and their classifications
    SpeedCategoryMap = containers.Map({1, 4, 5, 8, 6, 7}, {'B', 'S', 'S', 'M', 'F', 'F'});
    DistractorMap    = containers.Map({1, 4, 5, 8, 6, 7}, {'NA','N', 'Y', 'NA','N', 'Y'});
    TrialNumMap    = containers.Map({1, 4, 5, 8, 6, 7}, {'one','four', 'five', 'eight','six', 'seven'});

    %building new rowss:
    statsFormatRows = []; %creates structure for array that will hold data
    for t = trialsToRun %run through all the trials
        row.Subject = subjectName; %labels rows with subject ID
        
        %assign subject group by creating row structs
        if startsWith(subjectName, 'H')
            row.Group = "H";
                %adds Group field, which later becomes a table column
        elseif startsWith(subjectName, 'S')
            row.Group = "CVA";
        end
        
        %assign trial speed and distractor
        row.Trial = t; %saves trial #
        row.SpeedCategory = SpeedCategoryMap(t); %assigns right speed category
        row.Distractor = DistractorMap(t); %assigns right distractor category
        row.TrialNum = TrialNumMap(t);  %assigns right trial# category

        
        %now loop through all DVs
        for v = 1:length(variables)
            varName = variables{v}; %gets variable name 
            val = subjectData.(varName)(1, t); %looks at the column for that condition
            if ismissing(val)
                val = NaN;
            end
            row.(varName) = val; %adds DV value in right spot
        end
        statsFormatRows = [statsFormatRows; row]; %to add that trial's row
            %takes all of the row.Var row structs and --> struct array
    end

    %transform ^^struct array into a matlab table, then add it to CSV file
    dataToAddTable = struct2table(statsFormatRows);
   

    %check and see if that row exists already:
    for i = 1:height(dataToAddTable)
        subj = dataToAddTable.Subject(i);
        trial = dataToAddTable.Trial(i);
        match = strcmp(existingTable.Subject, subj) & existingTable.Trial == trial;
        existingTable(match, :) = [];  % Remove matching old row (if any)
    end

    updatedTableAll = [existingTable; dataToAddTable]; %adds new rows from dataToAddTable

    writetable(updatedTableAll, statsFormatCSV);
end


    


