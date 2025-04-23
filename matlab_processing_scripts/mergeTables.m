function [finalTable] = mergeTables(sourceTable, targetTable)

%Description: merges sourceTable and targetTable into finalTable
    %ensures that sourceTable and targetTable are compatible to be merged:
        %sourceTable contains all variables in targetTable 
        %data types match when needed
        %managing missing data
    %inputs:
        %sourceTable is table with full set of expected columns
        %targetTable is table to modify so that it matches sourceTable's columns
            %so that sourceTable can be added to targetTable
    %outputs:
        %finalTable is the result of merging sourceTable and targetTable, where:
            %all duplicate rows are deleted and replaced with updated rows from sourceTable
    %uses subfunction defaultColumnFiller to create placeholder columns for table merge compatability

   % list variables in each table
    sourceVars = sourceTable.Properties.VariableNames;
    targetVars = targetTable.Properties.VariableNames;
    allVars = unique([sourceVars, targetVars]);


        %%1: make sourceTable and targetTable columns match  
    for i = 1:length(allVars)
        var = allVars{i};

        %add columns to sourceTable if missing
        if ~ismember(var, sourceVars)
            targetSample = targetTable.(var);
            sourceTable.(var) = defaultColumnFiller(targetSample, height(sourceTable));
        end

        %add columns to targetTable if missing:
        if ~ismember(var, targetVars)
            sourceSample = sourceTable.(var);
            targetTable.(var) = defaultColumnFiller(sourceSample, height(targetTable));
        end
    end
     
    % Step 2: Ensure consistent data types across both tables
    for i = 1:length(allVars)
        var = allVars{i};
        sClass = class(sourceTable.(var));
        tClass = class(targetTable.(var));
    
        % Convert both to string if either is string-like
        if iscellstr(sourceTable.(var)) || ischar(sourceTable.(var)) || isstring(sourceTable.(var)) || ...
           iscellstr(targetTable.(var)) || ischar(targetTable.(var)) || isstring(targetTable.(var))
            sourceTable.(var) = string(sourceTable.(var));
            targetTable.(var) = string(targetTable.(var));

        
        % Convert both to double if either is numeric
        elseif isnumeric(sourceTable.(var)) || isnumeric(targetTable.(var))
            try
                sourceTable.(var) = double(sourceTable.(var));
                targetTable.(var) = double(targetTable.(var));
            catch
                warning("Problem converting. Keeping original format.", var);
            end

        
        % Convert both to logical if either is logical
        elseif islogical(sourceTable.(var)) || islogical(targetTable.(var))
            sourceTable.(var) = logical(sourceTable.(var));
            targetTable.(var) = logical(targetTable.(var));
    
        % or, if none of the above,: convert both to cell arrays of strings
        elseif ~strcmp(sClass, tClass)
            warning("Incompatible types for variable '%s'.", var);
            sourceTable.(var) = cellstr(string(sourceTable.(var)));
            targetTable.(var) = cellstr(string(targetTable.(var)));
        end
    end
                 
       
     
    %%3: reorder columns to match
    sourceTable = sourceTable(:, allVars);
    targetTable = targetTable(:, allVars);


    %%4: Remove any duplicates in targetTable that will be replaced
    if all(ismember(["Subject", "Trial"], allVars)) 
        %if subject and trial values exist for that row, use them to find duplicate rows
        sourceTable.Subject = string(sourceTable.Subject);
        sourceTable.Trial = double(sourceTable.Trial);
        targetTable.Subject = string(targetTable.Subject);
        targetTable.Trial = double(targetTable.Trial);
    
        [~, dupIdx] = ismember(sourceTable(:, {'Subject','Trial'}), ...
                               targetTable(:, {'Subject','Trial'}), 'rows');
        targetTable(dupIdx(dupIdx ~= 0), :) = [];
    end
         
    %%5 merge tables
    finalTable = [targetTable; sourceTable];

     %%6 sort finalTable by subject/trial
    if all(ismember({'Subject','Trial'}, finalTable.Properties.VariableNames))
    finalTable = sortrows(finalTable, {'Subject','Trial'});
end
end
    
    
function col = defaultColumnFiller(sample, nRows)
%defaultColumnFiller Creates a default column for table merging
    %Based on the type of data in `sample`, this function returns a column
        %with the correct placeholder values (e.g., NaN, "", false, etc.)

%inputs:
    %sample: column (ie from targetTable) used to infer desired variable type
    %nRows = how many rows long the filler column should be
%output:col = default empty placeholder column of appropriate type


   if iscell(sample)
        col = cell(nRows, 1);
    
   elseif isstring(sample) || ischar(sample)
        col = strings(nRows, 1);
    
   elseif isnumeric(sample)
        col = NaN(nRows, 1);
    
   elseif islogical(sample)
        col = false(nRows, 1);
    
   else %default to missing
        col = repmat(missing, nRows, 1);
    end
end