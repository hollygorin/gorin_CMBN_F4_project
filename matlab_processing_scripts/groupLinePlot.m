%this script creates line plots with options for:
    %plotting all DVs listed as DVsToPlot both 1 line per group, all combined, or showing all 3 lines  
    %or, if just want to quickly visualize one DV for either group or combined, 
        %can select one DV and customize grouping options
  

thesisDataAnalysisSettings;  % Load paths/settings
load(integratedDataTableDir);  % Load data

% === Settings (to change) ===
conditionsToPlot = fixedSpeedConditionsWithBL;
conditionOrder = conditionsToPlot;  % ensures x-axis stays ordered
DVsToPlot = DVraw;

groups = ["H", "CVA"];
groupLabels = ["Healthy", "Post-Stroke"];
groupColors = [0 0.5 1; 1 0.3 0.3];  % blue for H, red for CVA
allSubjectsColor = [0 0 0];  % black for all subjects

% === Select DVs ===
plotAllDVs = questdlg('Plot for all DVs or select one?', ...
                      'Plot Mode', 'All DVs', 'Select One', 'Select One');
plotAllDVs = strcmp(plotAllDVs, 'All DVs');

if plotAllDVs
    DVlist = string(DVsToPlot);
    saveToPDF = true;
    dateStr = datestr(now, 'yyyymmdd');
    pdfFilePath = fullfile(dataFiguresFolderDir, 'group', 'groupLinePlot', ...
                  sprintf('GroupLinePlots_%s.pdf', dateStr));
    if isfile(pdfFilePath)
        delete(pdfFilePath);
    end
    plotConfigs = ["Separate", "All Subjects Combined", "Both"];  % Auto-generate all 3 plots
else
    saveToPDF = false;
    availableDVs = string(DVsToPlot);
    [selectionIdx, ok] = listdlg('PromptString', 'Select a DV to plot:', ...
                                 'SelectionMode', 'single', ...
                                 'ListString', availableDVs);
    if ~ok
        disp('No DV selected. Exiting script.');
        return
    end
    DVlist = availableDVs(selectionIdx);

    % Ask how you want to group only if plotting one DV
    groupChoice = questdlg('Plot groups separately, all subjects combined, or both?', ...
                           'Group Option', ...
                           'Separate', 'All Subjects Combined', 'Both', 'Separate');

    if strcmp(groupChoice, 'Both')
        plotConfigs = ["Both"];
    elseif strcmp(groupChoice, 'Separate')
        plotConfigs = ["Separate"];
    else
        plotConfigs = ["All Subjects Combined"];
    end
end

% === Main Plot Loop ===
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

    for plotMode = plotConfigs
        % === Create Figure ===
        figure('Name', DV + " - Group Means", 'Units', 'normalized', 'Position', [0.2 0.3 0.6 0.5]);
        hold on;

        % Plot "Separate" (blue and red lines)
        if any(strcmp(plotMode, ["Separate", "Both"]))
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

        % Plot "All Subjects Combined" (black line)
        if any(strcmp(plotMode, ["All Subjects Combined", "Both"]))
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
        if plotMode == "Separate"
            saveNameGroup = "byGroup";
        elseif plotMode == "All Subjects Combined"
            saveNameGroup = "Combined";
        else
            saveNameGroup = "AllLines";
        end

        saveFigDir = fullfile(dataFiguresFolderDir, 'group', 'groupLinePlot');
        if ~exist(saveFigDir, 'dir')
            mkdir(saveFigDir);
        end
        saveas(gcf, fullfile(saveFigDir, sprintf('%s_%s_GroupLinePlot.png', DV, saveNameGroup)));

        if saveToPDF
            exportgraphics(gcf, pdfFilePath, 'Append', true);
            close(gcf);
        end
    end
end
