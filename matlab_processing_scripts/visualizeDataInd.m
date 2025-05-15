%this script takes integratedDataTable (created by extractall.m) and
%creates individual bar plots to visualize raw data per subject (grid for each group) for selected:
    %raw DV and conditions
%options for:
        %individualized Y axis
        %standardized y axis across groups
%can choose to run all DV options with both y axis options
    %will export PNGs to PDF 
%or select ind DVs and y axis options
    %emphasis on usability for less-ML experienced individuals
%saves all figures/PDF in DataFigures/Individual folder

thesisDataAnalysisSettings;  % call script 

load (integratedDataTableDir);

%CHANGE FOR WHICH SPEED CONDITIONS TO PLOT:
conditionsToPlot = fixedSpeedConditionsWithBL;
%conditionsToPlot = fixedSpeedConditionsNoBL

%CHANGE FOR WHICH DVs TO PLOT
DVsToPlot = DVraw;

% order of x axis bars:
conditionOrder = conditionsToPlot;


% Define different colors for each condition
colorMap = lines(numel(conditionOrder));
    %lines function-generates matrix of n colors





% Ask user whether to run all DVs or select manually
modeChoice = questdlg('Run all DVs with both Y-axis options, or select manually?', ...
                      'DV Selection Mode', ...
                      'Run All', 'Select Manually', 'Select Manually');  % Default to manual

if strcmp(modeChoice, 'Run All')
    selectedDVs = string(DVsToPlot);   % Use all DVs
    yAxisModes = {'Yes', 'No'};    % loop through both standardized and individualized Y-axis
    exportPDF = true;  
else
    exportPDF = false;
    %prompts you to pick DV:
    availableDVs = string(DVsToPlot);
        %pulling list from thesisDataAnalysisSettings  
    [selectionIdx, ok] = listdlg('PromptString', 'Select a DV to plot:', 'SelectionMode', 'single', 'ListString', availableDVs);
        %listdlg --> popup GUI to select
            %inputs:
                %promptstring-whats printed
                %selection mode single- can pick one DV
                %ListString = printed choices
            %outputs:
                %selection Idx =  index of selected DV in list
                %ok --> 1 if ok/double click; 0 if cancel
    
    DV = availableDVs(selectionIdx);
    selectedDVs = DV; %so works in the loop if manually select DV

    %pick standardized or scaled per subject Y axis:
    standardizeY = questdlg('Standardize Y axis across subjects?', ...
                           'Y Axis Scaling', ...
                           'Yes', 'No', 'Yes');  % Default = Yes
        %questdlg -->yes/no question- inputs:
            %question
            %title
            %button labels (last yes is default)
    
       yAxisModes = {standardizeY};  % Wrap into cell so can loop if run all
end


if exportPDF
    currentDate = datestr(now, 'yyyymmdd');
    combinedPDFfile = fullfile(dataFiguresFolderDir, 'individual', ...
                      sprintf('IndRawDataFigures_%s.pdf', currentDate));
    if isfile(combinedPDFfile)
        delete(combinedPDFfile);  % Clean up if already exists
    end
end


%Main Loop Over DVs and Y-Axis Modes =
for dvIdx = 1:length(selectedDVs)
    DV = selectedDVs(dvIdx);

    % Assign unit based on DV
    switch DV
        case 'MeanHeartRate'
            dvUnitLabel = 'beats per minute';
        case 'Percent_HR_Max'
            dvUnitLabel = '% HR max';
        case {'HR_normBL', 'Pupil_normBL', 'RR_normBL'}
            dvUnitLabel = '% of baseline';
        case 'MeanPupilDiameter'
            dvUnitLabel = 'mm';
        case 'RR'
            dvUnitLabel = 'breaths per minute';
        otherwise
            dvUnitLabel = '';  % fallback
    end

    for yModeIdx = 1:length(yAxisModes)
        useStandardY = strcmp(yAxisModes{yModeIdx}, 'Yes');

        groups = ["H", "CVA"];
            %from integratedDataTable
        groupLabels = ["Healthy", "Post-Stroke"];
            %for graph
            
        %for each group
        for g = 1:2 
            group = groups(g);
            groupLabel = groupLabels(g);
            %g is index (1 for H, 2 for CVA (order of group and groupLabel string)
          
        
            %filter data for group of interest:
            groupData = integratedDataTable(integratedDataTable.Group == group, :);
                %subtable (select row by group, :=all columns)
            subjects = unique(groupData.Subject);
                %list of subjects
            numSubjects = numel(subjects);
                %gets n count to determine grid sizing below
        
             % Determine grid rows/columns based on how many graphs to fit 
            nRows = ceil(sqrt(numSubjects));
            nCols = ceil(numSubjects / nRows);
            %ceil rounds *up* to nearest whole number
        
         %for each subject in each group:
            %collect all Y (DV) values so can standardize y axis for comparison
            yValsAll = [];
            for i = 1:numSubjects
                subj = subjects(i);
              
                %extract their data for conditionsToPlot- subtable per subject
                subjData = groupData(groupData.Subject == subj & ismember(groupData.Condition, conditionsToPlot), :);
                    %compare condition of all rows with each subject to the conditionsToPlot 
                        %and (:) keeps all columns of matching rows
                
                %order subject's data in condition order:
                [~, idx] = ismember(subjData.Condition, conditionOrder);
                    %ismember 
                [~, sortOrder] = sort(idx);
                subjData = subjData(sortOrder, :);
        
                yVals = NaN(1, numel(conditionOrder)); %empty row of NaNs
                for c = 1:numel(conditionOrder) %for each condition
                    cond = conditionOrder(c);
                    idx = subjData.Condition == cond;
                    if any(idx)
                        yVals(c) = subjData.(DV)(idx);
                    end
                end
                yValsAll = [yValsAll; yVals];
                    %matrix with subject rows/condition columns)
            end
        
            %calculates standardized y axis for all subjects in group
            yAxisLimits = [floor(min(yValsAll(:), [], 'omitnan')), ceil(max(yValsAll(:), [], 'omitnan'))];
                %yValsAll(:) --> makes matrix a vector
                %finds min/max value and rounds up/down --> ylim
        
        
        
        
            %create figure
            figure('Name', DV + " - " + groupLabel, 'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.8]);
                %opens new figure, titles it
                %units, normalized --> scales size
            tiledlayout(nRows, nCols, 'TileSpacing', 'compact', 'Padding', 'compact');  
        
            for i = 1:numSubjects
                subj = subjects(i);
                subjData = groupData(groupData.Subject == subj & ismember(groupData.Condition, conditionsToPlot), :);
                
                %ensure bar order:
                yVals = NaN(1, numel(conditionOrder)); 
                    %makes empty row
                for c = 1:numel(conditionOrder) %for each condition
                    cond = conditionOrder(c);
                    idx = subjData.Condition == cond; %finds rows for those conds
                    if any(idx)
                        yVals(c) = subjData.(DV)(idx); %extracts DV value
                    end
                end
                
                    nexttile;
        
                    if mod(i - 1, nCols) == 0
                        ylabel(sprintf('%s (%s)', DV, dvUnitLabel), 'FontSize', 8, 'Interpreter', 'none');
                    end
        
        
            
                    %plot:
                    xLabels = conditionOrder;
                   
                    %make each bar a different color:
                   hold on;
                    for k = 1:numel(yVals) %loop through each condition
                        if ~isnan(yVals(k)) %if it exists for that subject
                            bar(k, yVals(k), 'FaceColor', colorMap(k, :), 'BarWidth', 0.5);
                                %and makes each bar a diff color
                        end
                    end
                    hold off;
        
        
                title(subj, 'Interpreter', 'none', 'FontSize', 8);
                xticks(1:numel(conditionOrder));
                xticklabels(conditionOrder);
                xtickangle(45); %angles axis titles
        
        
                    %individualized y axis range
                if useStandardY
                    ylim(yAxisLimits);  % standardize y axis across subjects
                        %calculated above
                else %use individualized
                    subjYLimits = [floor(min(yVals, [], 'omitnan')), ceil(max(yVals, [], 'omitnan'))]; 
                        %gets min/max DV value for each subject

                    ylim(subjYLimits); yticks(linspace(subjYLimits(1), subjYLimits(2), 5)); 
                end 
            end 
        
            %add title: DV - Group
            sgtitle(sprintf('%s - %s', DV, groupLabel), 'FontWeight', 'bold');
        
                % Auto-saves  
            saveFigDir = fullfile(dataFiguresFolderDir, 'individual');
        
        
            yModeLabel = "standardY";
            if ~useStandardY
                yModeLabel = "indY";
            end
            
            filename = sprintf('%s_%s_%s.png', DV, group, yModeLabel);
            saveas(gcf, fullfile(saveFigDir, filename));

          % If exporting combined PDF, append the current figure
            if exportPDF
                exportgraphics(gcf, combinedPDFfile, 'Append', true, 'ContentType', 'vector');
            end
            close(gcf);  % Close figure after saving     
        end
    end
end
        
    

