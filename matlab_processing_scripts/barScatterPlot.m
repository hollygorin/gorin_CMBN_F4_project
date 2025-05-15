%this script creates bar scatter plots with options for:
    %plotting all DVs listed as DVsToPlot both by group and combined 
    %or, if just want to quickly visualize one DV for either group orcombined, 
        %can select one DV and customize grouping options
    %for plots of all subjects together, marks significant differences
        %founds via simpleStatsComparisons.m




thesisDataAnalysisSettings;  % Load paths/settings
load(integratedDataTableDir);  % Load data
load(fullfile(dataTablesFolderDir, 'SignificantComparisons.mat'));
    %from simpleStatsComparisons (runDVANOVAS)

%  Settings 
%  Settings 
DVsToPlot = DVraw;  % Plot all DVs

%conditionsToPlot = fixedSpeedConditionsWithBL;
conditionsToPlot = fixedSpeedConditionsNoBL

conditionOrder = conditionsToPlot;  % ensures x-axis stays ordered
groups = ["H", "CVA"];
groupLabels = ["Healthy", "Post-Stroke"];
groupColors = [0 0.5 1; 1 0.3 0.3];  % blue for H, red for CVA


% === User Choice: Plot All or Select One ===
plotAllDVs = questdlg('Plot for all DVs or select one?', ...
                      'Plot Mode', 'All DVs', 'Select One', 'Select One');
plotAllDVs = strcmp(plotAllDVs, 'All DVs');

% Prepare PDF if plotting all
if plotAllDVs
    saveToPDF = true;
    pdfFilePath = fullfile(dataFiguresFolderDir, 'group', 'barScatterPlot', 'All_BarScatterPlots.pdf');
    if isfile(pdfFilePath)
        delete(pdfFilePath); % clear old PDF
    end
    DVlist = string(DVsToPlot);
else
    saveToPDF = false;
    availableDVs = string(DVsToPlot);
    [selectionIdx, ok] = listdlg('PromptString', 'Select a DV to plot:', ...
                                 'SelectionMode', 'single', ...
                                 'ListString', availableDVs);
  
    DVlist = availableDVs(selectionIdx);
end

% === Plot Loop ===
for dvIdx = 1:numel(DVlist)
    DV = DVlist(dvIdx);

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

    % Loop for separate and combined plots
    for plotGroupsSeparately = [true, false]

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


        %%% Add Significance Markers if Combined Plot 
        if ~plotGroupsSeparately
            if ~exist('allSignificantResults', 'var')
                try
                    load('SignificantComparisons.mat');  % Adjust path if needed
                catch
                    warning('SignificantComparisons.mat not found. Skipping significance markers.');
                end
            end

            if exist('allSignificantResults', 'var')
                sigRows = allSignificantResults(strcmp(allSignificantResults.DV, DV), :);

                if ~isempty(sigRows)
                    yLimits = ylim;
                    yMax = yLimits(2);
                    for s = 1:height(sigRows)
                        cond1 = sigRows.Condition_1(s);
                        cond2 = sigRows.Condition_2(s);

                        idx1 = find(strcmp(conditionsToPlot, cond1));
                        idx2 = find(strcmp(conditionsToPlot, cond2));

                        if isempty(idx1) || isempty(idx2)
                            continue;  % Skip invalid condition names
                        end

                        % Add horizontal line for significance bar
                        plot([idx1, idx2], [yMax, yMax] * 1.05, '-k', 'LineWidth', 1.5);

                        % Add asterisk above line
                        text(mean([idx1, idx2]), yMax * 1.08, '*', ...
                            'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
                    end
                    % Expand Y-axis to fit significance bars
                    ylim([yLimits(1), yMax * 1.15]);
                end
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
        saveFigDir = fullfile(dataFiguresFolderDir, 'group', 'barScatterPlot');
        if ~exist(saveFigDir, 'dir'), mkdir(saveFigDir); end

        if plotGroupsSeparately
            saveNameGroup = "byGroup";
        else
            saveNameGroup = "AllTogether";
        end
        saveas(gcf, fullfile(saveFigDir, sprintf('%s_%s_BarScatter.png', DV, saveNameGroup)));

        % Export to PDF only if plotting all
        if saveToPDF
            exportgraphics(gcf, pdfFilePath, 'Append', true);
            close(gcf);
        end
    end
end
