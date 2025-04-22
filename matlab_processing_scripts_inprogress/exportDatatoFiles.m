% DESCRIPTION: Export the long-format statsFormatTable.mat file as:
    %CSV (long format)
    %Excel (wide format, one sheet per DV) (for quick looks and use with lab)
    %Or both

outputDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables';

% 1 LOAD .MAT FILE
matFile = fullfile(outputDir, 'StatsFormatTable.mat');
load(matFile, 'statsFormatTable');

%2 specify output file location:
csvOut = fullfile(outputDir, 'StatsFormat.csv');
excelOut = fullfile(outputDir, 'ExtractedAllbyDV.xlsx');

%3. SAVE FORMAT SELECTION
%pick whether to save to ExtractedAllbyDV.xlsx, to StatsFormat.csv, or both
fprintf('1 = Only long format .csv file \n');
fprintf('2 = Only wide format excel file \n');
fprintf('3 = Both \n');
saveChoice = input('1, 2, or 3): ');

saveCSV  = ismember(saveChoice, [1, 3]);
saveXLSX = ismember(saveChoice, [2, 3]);


%3 write to statsFormat csv 
if saveCSV
    if isfile(csvOut)
        existingTable = readtable(csvOut);
            %loads existing output file
    
        %makes sure the column names and order match and,if they don't, makes them match
        missingCols = setdiff(existingTable.Properties.VariableNames, statsFormatTable.Properties.VariableNames);
        for mc = missingCols
            statsFormatTable.(mc{1}) = NaN(height(statsFormatTable), 1);
                %adds any missing
        end
    
        statsFormatTable = statsFormatTable(:, existingTable.Properties.VariableNames);
            %and makes sure order is the same
        
        %make sure matlab table and excel table are same type to avoid errors merging:
        statsFormatTable.Subject = string(statsFormatTable.Subject);
        existingTable.Subject = string(existingTable.Subject);
        statsFormatTable.Trial = double(statsFormatTable.Trial);
        existingTable.Trial = double(existingTable.Trial);

        % erase duplicate rows to be replaced
        [~, ids] = ismember(statsFormatTable(:, {'Subject','Trial'}), ...
                            existingTable(:, {'Subject','Trial'}), 'rows');
                %checks statsFormatTable for existing duplicate rows that the existing .csv file already has 
        existingTable(ids ~= 0, :) = [];  % remove duplicates from the existing .csv table
            %ie: if ids isn't 0
        statsFormatTable = [existingTable; statsFormatTable];
            %merges them
    end
    
    writetable(statsFormatTable, csvOut);
end %if save csv


%4 export wide format excel 
    %with one sheet per variable, one row per subject, and one column per condition
if saveXLSX
    desiredTrialOrder = [1, 4, 5, 8, 6, 7];
    

    %pull in DVs for wide format table:
    varsToSkip = ["Subject", "Trial", "Group", "Distractor", "SpeedCategory", "Condition"];
    variables = setdiff(statsFormatTable.Properties.VariableNames, varsToSkip, 'stable');

    for i = 1:length(variables)
        thisVar = variables(i);
            %to create one sheet per DV (thisVar)

        
        varData = statsFormatTable(:, {'Subject', 'Trial', char(thisVar)});
            % Pull DV, subject ID, and trial from the statsformat table
            %uses char() to turn into characters for column indexing purposes
        varData = renamevars(varData, char(thisVar), 'Value');
            %renames DV column to generic name temporarily so doesn't mess up pivoting' to wide format
         
        varData = unique(varData, 'rows');
                %to avoid error if running duplicate subject
                %removes duplicate rows

        % Pivot into wide format: 1 row per subject, 1 column per trial
        wide = unstack(varData, 'Value', 'Trial');
            %pivot = unstack 
                %spread out value column across columns 
                %make trial into new column header
            %turns trial#s into columns and fills in DVs
            %one row per subject

        % Rename columns from x1, x4, etc. to T1, T4, etc.
        oldTrialNames = setdiff(wide.Properties.VariableNames, "Subject"); 
        newTrialNames = replace("T" + extractAfter(oldTrialNames, "x"), ".", "_"); 
            %when matlab reads the excel file, it adds an x to the numbers
            %replacing the x with T so it matches matlab table for merging
        wide = renamevars(wide, oldTrialNames, newTrialNames);
        

        % Order columns so matches with existing
        wide = movevars(wide, 'Subject', 'Before', 1);
            %subject IDs in first column (movevars(table, varName, position)
        colOrder = ["Subject", "T1", "T4", "T5", "T4_5", "T8", "T6", "T7", "T6_5"];
            %confirm trial order is string just like column names
        colsToKeep = intersect(colOrder, wide.Properties.VariableNames, 'stable');
            %picks trials to keep
        wide = wide(:, colsToKeep);

        % Save to byDV's Excel sheet
        sheetName = char(thisVar);
            %finds sheet and converts DV name to character
        existing = readtable(excelOut, 'Sheet', sheetName, 'ReadVariableNames', true, 'VariableNamingRule', 'preserve');
             %Read existing sheet-updated to silence warning "Table
             %variable names that were not valid MATLAB identifiers have been modified..."


        %make sure are same type to avoid errors comparing/merging:
        wide.Subject = string(wide.Subject);
        existing.Subject = string(existing.Subject);


        % locate and remove duplicates in existing so can be replaced
        [~, idx] = ismember(wide.Subject, existing.Subject);
        existing(idx ~= 0, :) = [];  
             
        
        %make sure columns match to avoid errors merging
        commonCols = intersect(existing.Properties.VariableNames, wide.Properties.VariableNames, 'stable');
        existing = existing(:, commonCols);
        wide = wide(:, commonCols);


        updated = [existing; wide];
            % Combine existing and new rows

     
        % Order columns again after merge to avoid error
        updated = movevars(updated, 'Subject', 'Before', 1);
            %subject IDs in first column (movevars(table, varName, position)
        colOrder = ["Subject", "T1", "T4", "T5", "T4_5", "T8", "T6", "T7", "T6_5"];
            %confirm trial order is string just like column names
        colsToKeep = intersect(colOrder, updated.Properties.VariableNames, 'stable');
             %picks trials to keep
        updated = updated(:, colsToKeep);
        
        writetable(updated, excelOut, 'Sheet', sheetName);
    end
end %of if save excel