thesisDataAnalysisSettings;  % Load paths/settings
load(integratedDataTableDir);  % Load data

% === Settings ===
conditionsToPlot = fixedSpeedConditionsWithBL;
conditionOrder = fixedSpeedConditionsWithBL;  % ensures x-axis stays ordered
groups = ["H", "CVA"];
groupLabels = ["Healthy", "Post-Stroke"];
groupColors = [0 0.5 1; 1 0.3 0.3];  % blue for H, red for CVA
allSubjectsColor = [0 0 0];  % black for all subjects

% === Select DV ===
availableDVs = ["MeanHeartRate", "Percent_HR_Max", "HR_normBL", ...
                "MeanPupilDiameter", "Pupil_normBL", "RR", "RR_normBL"];
[selectionIdx, ok] = listdlg('PromptString', 'Select a DV to plot:', ...
                             'SelectionMode', 'single', ...
                             'ListString', availableDVs);
if ~ok
    disp('No DV selected. Exiting script.');
    return
end
DV = availableDVs(selectionIdx);

% Assign unit label based on DV
switch DV
    case 'MeanHeartRate'
        dvUnitLabel = 'beats per minute';
    case 'Percent_HR_Max'
        dvUnitLabel = '% HR max';
    case {'HR_normBL', 'Pupil_normBL', 'RR_normBL'}
        dvUnitLabel = 'normalized';
    case 'MeanPupilDiameter'
        dvUnitLabel = 'mm';
    case 'RR'
        dvUnitLabel = 'breaths per minute';
    otherwise
        dvUnitLabel = '';
end


% Ask how you want to group
groupChoice = questdlg('Plot groups separately, together, or both?', ...
                       'Group Option', ...
                       'Separate', 'Together', 'Both', 'Separate');
plotSeparate = strcmp(groupChoice, 'Separate') || strcmp(groupChoice, 'Both');
plotTogether = strcmp(groupChoice, 'Together') || strcmp(groupChoice, 'Both');

% === Create Figure ===
figure('Name', DV + " - Group Means", 'Units', 'normalized', 'Position', [0.2 0.3 0.6 0.5]);
hold on;

% Plot separate groups if selected
if plotSeparate
    for g = 1:numel(groups)
        group = groups(g);
        groupLabel = groupLabels(g);
        
        groupData = integratedDataTable( ...
            integratedDataTable.Group == group & ...
            ismember(integratedDataTable.Condition, conditionsToPlot), :);

        means = NaN(1, numel(conditionOrder));
        sems = NaN(1, numel(conditionOrder));

        for c = 1:numel(conditionOrder)
            cond = conditionOrder(c);
            condData = groupData(strcmp(groupData.Condition, cond), :);
            dvVals = condData.(DV);

            means(c) = mean(dvVals, 'omitnan');
            sems(c) = std(dvVals, 'omitnan') / sqrt(sum(~isnan(dvVals)));
        end

        % Plot
        errorbar(1:numel(conditionOrder), means, sems, '-o', ...
                 'LineWidth', 2, 'Color', groupColors(g,:), ...
                 'DisplayName', groupLabel, 'MarkerFaceColor', groupColors(g,:));
    end
end

% Plot all subjects pooled if selected
if plotTogether
    allData = integratedDataTable(ismember(integratedDataTable.Condition, conditionsToPlot), :);

    means = NaN(1, numel(conditionOrder));
    sems = NaN(1, numel(conditionOrder));

    for c = 1:numel(conditionOrder)
        cond = conditionOrder(c);
        condData = allData(strcmp(allData.Condition, cond), :);
        dvVals = condData.(DV);

        means(c) = mean(dvVals, 'omitnan');
        sems(c) = std(dvVals, 'omitnan') / sqrt(sum(~isnan(dvVals)));
    end

    % Plot
    errorbar(1:numel(conditionOrder), means, sems, '--s', ...
             'LineWidth', 2, 'Color', allSubjectsColor, ...
             'DisplayName', 'All Subjects', 'MarkerFaceColor', allSubjectsColor);
end

% Formatting
xticks(1:numel(conditionOrder));
xticklabels(conditionOrder);
xtickangle(30);
ylabel(sprintf('%s (%s)', DV, dvUnitLabel), 'Interpreter', 'none');
title(sprintf('%s - Group Means ± SEM', DV), 'FontWeight', 'bold');
legend('Location', 'best');
grid on;
hold off;

% === Save ===
if strcmp(groupChoice, 'Separate')
    saveNameGroup = "byGroup";
elseif strcmp(groupChoice, 'Together')
    saveNameGroup = "Combined";
else
    saveNameGroup = "AllSep";
end

saveFigDir = fullfile(dataFiguresFolderDir, 'group');
if ~exist(saveFigDir, 'dir')
    mkdir(saveFigDir);
end
saveas(gcf, fullfile(saveFigDir, sprintf('%s_%s_GroupLinePlot.png', DV, saveNameGroup)));
