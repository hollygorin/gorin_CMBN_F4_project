
%this script creates spaghetti plots for selected DV with options for:
    %plotting by group separately or plotting together
    %adding a mean/SEM line


thesisDataAnalysisSettings;  % Load paths/settings
load(integratedDataTableDir);  % Load data

%1 general settings:
conditionsToPlot = fixedSpeedConditionsWithBL;  % or fixedSpeedConditionsNoBL
conditionOrder = conditionsToPlot;
availableDVs = ["MeanHeartRate", "Percent_HR_Max", "HR_normBL", ...
                "MeanPupilDiameter", "Pupil_normBL", "RR_normBL"];

%2 selecting DV, group/combined, and mean representation:

%select DV:
fprintf('\nSelect a DV to plot:\n');
for i = 1:numel(availableDVs)
    fprintf('  %d: %s\n', i, availableDVs(i));
end
selectionIdx = input('Which DV? (pick a number): ');
DV = availableDVs(selectionIdx);

%pick separate or combined plots:
plotOption = input('\nPlot mode (1 = Separate by group, 2 = Combined): ');
if plotOption == 2
    plotTogether = true;
else
    plotTogether = false;
end

%pick +/- group mean:
% === Overlay group mean? ===
meanOption = input('\nOverlay group mean ± SEM? (1 = Yes, 2 = No): ');
if meanOption == 1
    overlayGroupMean = true;
else
    overlayGroupMean = false;
end


%3 group vs combined set up
groups = ["H", "CVA"];
groupLabels = ["Healthy", "Post-Stroke"];
colors = rainbow;  % For individual subjects
    %colors defined in thesisDataAnalysisSettings

 
if plotTogether %then loopGroups struct is all subjects together
    loopGroups = {...
        struct('data', integratedDataTable(ismember(integratedDataTable.Condition, conditionsToPlot), :), ...
               'label', 'All Subjects', ...
               'tag', 'combined')};
                %extracts DV of interest for all subjects
else %separate into H and CVA structs
    loopGroups = {};
    for g = 1:numel(groups) %loops through H and CVA
        groupID = groups(g);
        groupLabel = groupLabels(g);
        groupData = integratedDataTable( ...
            integratedDataTable.Group == groupID & ...
            ismember(integratedDataTable.Condition, conditionsToPlot), :);
                %creates on struct of DVs for H and one for CVA
        loopGroups{end+1} = struct( ...
            'data', groupData, ...
            'label', sprintf('%s Group', groupLabel), ...
            'tag', groupID);
    end
end

%4: group over each dataset to plot:
for g = 1:numel(loopGroups)
    grp = loopGroups{g};
    data = grp.data;
    subjects = unique(data.Subject);
    labelData = [];  % reset for each group
    usedPointCoords = zeros(0,2);
        %to compare and see if need jittering


    %4a begin plot:
    figure('Name', sprintf('%s - %s', DV, grp.label), ...
           'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.7]);
    hold on;

    %4b set y axis range:
    allYVals = data.(DV);
    yMin = min(allYVals, [], 'omitnan');
    yMax = max(allYVals, [], 'omitnan');
    yRange = yMax - yMin;
    padding = 0.05 * yRange;  % 10% padding above/eblow
    
    ylim([yMin - padding, yMax + padding]); %set actual axis range

    % 4c Plot group mean first (so under all ind lines)
    if overlayGroupMean
        means = NaN(1, numel(conditionOrder));
        sems  = NaN(1, numel(conditionOrder));
            %prefill with NaNs to handle missing data
        for c = 1:numel(conditionOrder)
            condData = data(data.Condition == conditionOrder(c), :);
                    %pulls columns of DV data of interest
            vals = condData.(DV);
                    %pulls just the DV values
            means(c) = mean(vals, 'omitnan');
                    %calculates mean
            sems(c) = std(vals, 'omitnan') / sqrt(sum(~isnan(vals)));
                    %calculates SEM
        end
        % Behind: white halo
        plot(1:numel(conditionOrder), means, 'LineStyle', '--', 'Color', [0.9 0.9 0.9], 'LineWidth', 9);
        hlow = plot(1:numel(conditionOrder), means, '--', 'Color', [0.8 0.8 0.8], 'LineWidth', 7);
            hlow.Color(4) = 0.5;  % make glow partially transparent (if using R2018a+)
        errorbar(1:numel(conditionOrder), means, sems, '--k', ...
                 'LineWidth', 3, 'DisplayName', 'Group Mean');
    end

    % 4d then Plot each subject (subject loop)
    for i = 1:numel(subjects)
        subj = subjects(i);
        subjData = data(data.Subject == subj, :);
        [~, idx] = ismember(subjData.Condition, conditionOrder);
        valid = idx > 0;
        subjData = subjData(valid, :);
        idx = idx(valid);
        [~, sortOrder] = sort(idx);
        subjData = subjData(sortOrder, :);

        yVals = NaN(1, numel(conditionOrder));
        for c = 1:numel(conditionOrder)
            cond = conditionOrder(c);
            match = subjData.Condition == cond;
            if any(match)
                yVals(c) = subjData.(DV)(match);
            end
        end

        %plot individual lines
        lineColor = colors(mod(i-1, size(colors,1)) + 1, :);
                
        xVals = 1:numel(conditionOrder);
        xJittered = xVals;
        jitterAmount = 0.06;
        
        for p = 1:numel(yVals)
            if isnan(yVals(p)), continue; end %skip over missing data
        
            % Check if another point exists at same (x, y)
            isOverlap = any( abs(usedPointCoords(:,1) - xVals(p)) < 0.01 & ...
                             abs(usedPointCoords(:,2) - yVals(p)) < 0.01 );
                    %compares current coordinates to existing
                    %threshold for jittering is w/in 0.01 units
        
            if isOverlap
                xJittered(p) = xVals(p) + jitterAmount;
                    %jitters x coordinate
            end
        
            usedPointCoords(end+1, :) = [xJittered(p), yVals(p)];
                %adds it for comparison to future points
        end
        
        % Plot with jittered x values
        plot(xJittered, yVals, '-o', 'LineWidth', 1.75, 'Color', lineColor, ...
            'MarkerFaceColor', lineColor, ...
            'DisplayName', subj);

       

     % 4e Label end of line w/ subject ID
        %first extract fast DV value (so can use to sort below)
        lastIdx = find(~isnan(yVals), 1, 'last'); %find the F DV value
        if ~isempty(lastIdx)
            %create structs for , , ,
            labelData(end+1).Subject = subj; %subject ID
            labelData(end).Y = yVals(lastIdx); %fast DV value 
            labelData(end).Xval = find(conditionOrder == subjData.Condition(end));  %x-axis (so what condition)
                %should always be fast, but jic missing data
            labelData(end).Color = lineColor; %what color that line is
        end
    
    end

    % stagger subject labels horizontally for readability
    if exist('labelData', 'var') && ~isempty(labelData)
        % Sort by fast DV value position (--> order of labels)
        [~, sortIdx] = sort([labelData.Y]);
        labelData = labelData(sortIdx);

        hAlign = 'left';  % Always align labels left of their box
      

        for i = 1:numel(labelData) 
            s = labelData(i);
            xBase = s.Xval; %what cond. subject;s last point is
            yBase = s.Y; %DV value

            % Alternate horizontal label position to prevent overlap
            offsets = [0.08, 0.18, 0.28, 0.38];  % Customize spacing as needed
            xLabel = xBase + offsets(mod(i-1, numel(offsets)) + 1);
                %moves each in the descending line over one spot to the R
            yLabel = yBase;


            %draw connecting line from label to last point:
            plot([xBase, xLabel], [yBase, yLabel], ':', 'Color', s.Color, 'LineWidth', 1.5);

        % Draw subject ID text label
          %Label with matching colored background for clarity
            textColor = 'w';  % default white text
            if mean(s.Color) > 0.7  % auto contrast (if background color is light)
                textColor = 'k';
            end

            text(xLabel, yLabel, s.Subject, ...
                'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', s.Color, ... % box matches line color
                'Margin', 1.2, ... %padding inside box
                'EdgeColor', 'none', ... %no border
                'Color', textColor, ...
                'HorizontalAlignment', hAlign, ...
                'VerticalAlignment', 'middle');
        end
    end
       

    % --- Formatting
    title(sprintf('%s - %s', DV, grp.label), 'FontWeight', 'bold');
    legend({'Group Mean'}, 'Location', 'eastoutside');
    xticks(1:numel(conditionOrder));
    xticklabels(conditionOrder);
    xtickangle(45);
    ylabel(DV, 'Interpreter', 'none');
    xlim([0.5, numel(conditionOrder) + 1]);
    grid on;
    hold off;

    % --- Save figure
    if overlayGroupMean
        meanTag = "withMean";
    else
        meanTag = "noMean";
    end

    saveName = sprintf('%s_%s_%s_SpaghettiPlot.png', DV, grp.tag, meanTag);
    saveFigDir = fullfile(dataFiguresFolderDir, 'group');
    if ~exist(saveFigDir, 'dir'), mkdir(saveFigDir); end
    saveas(gcf, fullfile(saveFigDir, saveName));
end



