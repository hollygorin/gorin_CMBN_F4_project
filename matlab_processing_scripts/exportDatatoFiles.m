% DESCRIPTION: Export the long-format masterDataTable.mat file as:
    %CSV (long format)
    %Excel (wide format, one sheet per DV) (for quick looks and use with lab)
    %Or both

thesisDataAnalysisSettings;  % call script with directories/variables

outputDir = dataTablesFolderDir;

% 1 LOAD .MAT FILE
matFile = integratedDataTableDir;
load(matFile, 'integratedDataTable');

%2 specify output file location:
csvOut = fullfile(outputDir, 'dataLongFormat.csv');
excelOut = fullfile(outputDir, 'dataWideFormat.xlsx');

%3. SAVE FORMAT SELECTION
%pick whether to save to dataWideFormat.xlsx, to dataLongFormat.csv, or both
fprintf('1 = Only long format .csv file \n');
fprintf('2 = Only wide format excel file \n');
fprintf('3 = Both \n');
saveChoice = input('1, 2, or 3): ');

saveCSV  = ismember(saveChoice, [1, 3]);
saveXLSX = ismember(saveChoice, [2, 3]);


%3 write to dataLongFormat.csv  
if saveCSV
    if isfile(csvOut)
        existingTable = readtable(csvOut);
            %loads existing output file
    
        %make sure matlab table and excel table are same type to avoid errors merging:
        integratedDataTable.Subject = string(integratedDataTable.Subject);
        existingTable.Subject = string(existingTable.Subject);
        integratedDataTable.Trial = double(integratedDataTable.Trial);
        existingTable.Trial = double(existingTable.Trial);

        %Make sure columns match between existing and new 
        % Add any missing columns to the new table (with NaNs)
        missingInNew = setdiff(existingTable.Properties.VariableNames, integratedDataTable.Properties.VariableNames);
        for mn = missingInNew
            integratedDataTable.(mn{1}) = NaN(height(integratedDataTable), 1);
        end
        
        % Add any missing columns to the old table (with NaNs)
        missingInExisting = setdiff(integratedDataTable.Properties.VariableNames, existingTable.Properties.VariableNames);
        for me = missingInExisting
            existingTable.(me{1}) = NaN(height(existingTable), 1);
        end
        
        % match column order of existing to integratedDataTable
        existingTable = existingTable(:, integratedDataTable.Properties.VariableNames);

        % erase duplicate rows in .csv that will be replaced
        [~, ids] = ismember(existingTable(:, {'Subject','Trial'}), ...
                            integratedDataTable(:, {'Subject','Trial'}), 'rows');
                %iemember checks integratedDataTable for existing duplicate rows that the existing .csv file already has
                %ids returns the row# of the match 
        existingTable(ids ~= 0, :) = [];  % remove duplicates from the existing .csv table
        
        
        %now merge them
        integratedDataTable = [existingTable; integratedDataTable];
    end
    
    writetable(integratedDataTable, csvOut);
end %of save csv


%4 export wide format excel 
    %with one sheet per variable, one row per subject, and one column per condition
if saveXLSX
    desiredTrialOrder = [1, 4, 5, 8, 6, 7];
    colOrder = ["Subject", "T1", "T4", "T5", "T4_5", "T8", "T6", "T7", "T6_5"];


    %pull in DVs for wide format table:
    varsToSkip = ["Subject", "Trial", "Group", "Distractor", "SpeedCategory", "Condition"];
    variables = setdiff(integratedDataTable.Properties.VariableNames, varsToSkip, 'stable');

    for i = 1:length(variables)
        thisVar = variables(i);
            %to create one sheet per DV (thisVar)

        
        varData = integratedDataTable(:, {'Subject', 'Trial', char(thisVar)});
            % Pull DV, subject ID, and trial from the integratedDataTable
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
            %confirm trial order is string just like column names
        colsToKeep = intersect(colOrder, wide.Properties.VariableNames, 'stable');
            %picks trials to keep
        wide = wide(:, colsToKeep);

        % Save to byDV's Excel sheet
        sheetName = char(thisVar);
            %finds sheet and converts DV name to character
        sheetList = sheetnames(excelOut);

        if ismember(sheetName, sheetList)
            existing = readtable(excelOut, 'Sheet', sheetName, 'ReadVariableNames', true, 'VariableNamingRule', 'preserve');
        else
            existing = table(); % empty table if the sheet doesn't exist
        end


        %make sure are same type to avoid errors comparing/merging:
        wide.Subject = string(wide.Subject);
        if ~isempty(existing) && ismember('Subject', existing.Properties.VariableNames)
                %doesn't try to find nonexistant columns in empty tables created for new sheets
            existing.Subject = string(existing.Subject);
        end

        % locate and remove duplicates in existing so can be replaced
        if ~isempty(existing) && ismember('Subject', existing.Properties.VariableNames)
                %existing.subject doesn't exist for new sheets that are just empty tables
            [~, idx] = ismember(existing.Subject, wide.Subject);
            existing(idx ~= 0, :) = [];
        end
               
        
        %make sure columns match to avoid errors merging
        if isempty(existing)
            updated = wide;  % just use wide data if no existing sheet
        else
            % otherwise: match columns and merge
            commonCols = intersect(existing.Properties.VariableNames, wide.Properties.VariableNames, 'stable');
            existing = existing(:, commonCols);
            wide = wide(:, commonCols);
            updated = [existing; wide];
        end


        updated = [existing; wide];
            % Combine existing and new rows

     
     %for sheets that exist, order columns again after merge to avoid error
        if ismember('Subject', updated.Properties.VariableNames)
            updated = movevars(updated, 'Subject', 'Before', 1);
        end
            %subject IDs in first column (movevars(table, varName, position)
        colsToKeep = intersect(colOrder, updated.Properties.VariableNames, 'stable');
             %picks trials to keep
        updated = updated(:, colsToKeep);
        
        writetable(updated, excelOut, 'Sheet', sheetName, 'WriteMode', 'overwritesheet');
    end
end

    
 %of if save excel