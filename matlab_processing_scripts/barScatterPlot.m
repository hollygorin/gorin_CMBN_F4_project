thesisDataAnalysisSettings;  % Load paths/settings
load(integratedDataTableDir);  % Load data

%  Settings 
conditionsToPlot = fixedSpeedConditionsWithBL;
conditionOrder = fixedSpeedConditionsWithBL;  % ensures x-axis stays ordered
groups = ["H", "CVA"];
groupLabels = ["Healthy", "Post-Stroke"];
groupColors = [0 0.5 1; 1 0.3 0.3];  % blue for H, red for CVA

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

% Ask if want to separate by group
separateByGroup = questdlg('Plot groups separately or together?', ...
                           'Group Separation', ...
                           'Separate', 'Together', 'Separate');
plotGroupsSeparately = strcmp(separateByGroup, 'Separate');

% MAKE FIGURE
figure('Name', DV + " - Bar + Scatter", 'Units', 'normalized', 'Position', [0.2 0.3 0.6 0.5]);
hold on;

barWidth = 0.35;
xShift = [-0.15, 0.15];  % shifts for side-by-side bars

if plotGroupsSeparately
    barHandles = gobjects(2,1); % two groups: H and CVA
else
    barHandles = gobjects(1,1); % one pooled group
end

for c = 1:numel(conditionsToPlot)
    cond = conditionsToPlot(c);

    if plotGroupsSeparately
        for g = 1:2
            group = groups(g);
            groupData = integratedDataTable( ...
                integratedDataTable.Group == group & ...
                integratedDataTable.Condition == cond, :);

            y = groupData.(DV);
            xPos = c + xShift(g);

            % Plot bar for group mean
            meanVal = mean(y, 'omitnan');
            semVal = std(y, 'omitnan') / sqrt(sum(~isnan(y)));

            bh = bar(xPos, meanVal, barWidth, 'FaceColor', groupColors(g,:), 'EdgeColor', 'none');
            if c == 1  % Save handle only once
                barHandles(g) = bh;
            end

            % Plot error bar
            errorbar(xPos, meanVal, semVal, 'k', 'LineStyle', 'none', 'LineWidth', 1);

            % Overlay scatter points
            scatter(repelem(xPos, numel(y)) + randn(size(y))*0.02, y, ...
                    30, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', groupColors(g,:), 'MarkerFaceAlpha', 0.6);
        end

    else
        % Pool all groups together
        groupData = integratedDataTable( ...
            ismember(integratedDataTable.Condition, cond), :);

        y = groupData.(DV);
        xPos = c;  % no shift needed

        % Plot bar for mean
        meanVal = mean(y, 'omitnan');
        semVal = std(y, 'omitnan') / sqrt(sum(~isnan(y)));

        bh = bar(xPos, meanVal, barWidth, 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none'); % gray
        if c == 1
            barHandles(1) = bh;
        end

        % Plot error bar
        errorbar(xPos, meanVal, semVal, 'k', 'LineStyle', 'none', 'LineWidth', 1);

        % Overlay scatter points
        scatter(repelem(xPos, numel(y)) + randn(size(y))*0.02, y, ...
                30, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerFaceAlpha', 0.6);
    end
end

% Axes formatting
xticks(1:numel(conditionsToPlot));
xticklabels(conditionsToPlot);
xtickangle(30);
ylabel(sprintf('%s (%s)', DV, dvUnitLabel), 'Interpreter', 'none');
title(sprintf('%s - Bar + Scatter by Condition', DV), 'FontWeight', 'bold');

% Legend
if plotGroupsSeparately
    legend(barHandles, groupLabels, 'Location', 'best');
else
    legend(barHandles, "All Subjects", 'Location', 'best');
end

grid on;
hold off;

% === Save ===
saveFigDir = fullfile(dataFiguresFolderDir, 'group');
if plotGroupsSeparately
    saveNameGroup = "byGroup";
else
    saveNameGroup = "AllTogether";
end
saveas(gcf, fullfile(saveFigDir, sprintf('%s_%s_BarScatter.png', DV, saveNameGroup)));
