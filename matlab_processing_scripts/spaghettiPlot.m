%this script creates spaghetti plots with options for:
    %plotting all DVs listed as DVsToPlot
        %both by group and together 
        % both with and without amean/SEM line, adding a mean/SEM line
    %or, if just want to quickly visualize one DV for either group orcombined, 
        %can select one DV and customize group/ mean bar options


thesisDataAnalysisSettings;  % Load paths/settings
load(integratedDataTableDir);  % Load data

%CHANGE HERE TO SELECT AVAILABLE DVs:
DVsToPlot = DVraw

%1 general settings:
conditionsToPlot = fixedSpeedConditionsWithBL;  % or fixedSpeedConditionsNoBL
conditionOrder = conditionsToPlot;
availableDVs = string(DVsToPlot);
groups = ["H", "CVA"];
groupLabels = ["Healthy", "Post-Stroke"];
colors = rainbow;  % Colors defined in thesisDataAnalysisSettings

%2 selecting DV, group/combined, and mean representation (or all):

%give option to plot all DVs both by group and individually, both with and
%w/o mean lean
plotAllDVs = input('\nPlot all DVs? (1 = Yes, 2 = No): ') == 1;

if plotAllDVs
    saveToPDF = true;
    pdfFilePath = fullfile(dataFiguresFolderDir, 'group', 'spaghettiPlot', 'All_SpaghettiPlots.pdf');
    if isfile(pdfFilePath)
        delete(pdfFilePath); %clear old pdf
    end
    
    DVsToPlot = availableDVs;  % Plot all availableDVs
    groupConfigs = {...
        struct('groups', ["H"], 'label', 'Healthy'), ...
        struct('groups', ["CVA"], 'label', 'Post-Stroke'), ...
        struct('groups', ["H", "CVA"], 'label', 'AllSubjects') ...
    };
    meanOptions = [false, true];  % Without and with mean line

%or to select DV/ group/ +/- mean line:
else
    fprintf('\nSelect a DV to plot:\n');
    for i = 1:numel(availableDVs)
        fprintf('  %d: %s\n', i, availableDVs(i));
    end
        selectionIdx = input('Which DV? (pick a number): ');
    DVsToPlot = availableDVs(selectionIdx);

    fprintf('\nPlot Mode Options:\n  1: Separate by Group\n  2: Combined\n  3: Both\n');
    plotOption = input('Select plot mode (enter number): ');
    
    switch plotOption
        case 1
            groupConfigs = { ...
                struct('groups', ["H"], 'label', 'Healthy'), ...
                struct('groups', ["CVA"], 'label', 'Post-Stroke') ...
            };
        case 2
            groupConfigs = {struct('groups', ["H", "CVA"], 'label', 'AllSubjects')};
        case 3
            groupConfigs = { ...
                struct('groups', ["H"], 'label', 'Healthy'), ...
                struct('groups', ["CVA"], 'label', 'Post-Stroke'), ...
                struct('groups', ["H", "CVA"], 'label', 'AllSubjects') ...
            };
        otherwise
            error('Invalid selection. Exiting script.');
    end
    
    meanOption = input('Overlay group mean ± SEM? (1 = Yes, 2 = No): ');
    meanOptions = (meanOption == 1);

    saveToPDF = false;  % only save PDF if run all
end


%3 plotting loop
for dvIdx = 1:numel(DVsToPlot)
    DV = DVsToPlot(dvIdx);


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

    for grpIdx = 1:numel(groupConfigs)
        grpConfig = groupConfigs{grpIdx};

    
        for overlayGroupMean = meanOptions

            %  Data Selection 
            loopGroups = {...
                struct('data', integratedDataTable( ...
                ismember(integratedDataTable.Group, grpConfig.groups) & ...
                ismember(integratedDataTable.Condition, conditionsToPlot), :), ...
                'label', grpConfig.label, ...
                'tag', strjoin(grpConfig.groups, "_"))};


            %  Plot for Each Group Config 
            for g = 1:numel(loopGroups)
                grp = loopGroups{g};
                data = grp.data;
                subjects = unique(data.Subject);

                figure('Name', sprintf('%s - %s', DV, grp.label), ...
                       'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.7]);
                hold on;

                % set Y-Axis Range
                allYVals = data.(DV);
                yMin = min(allYVals, [], 'omitnan');
                yMax = max(allYVals, [], 'omitnan');
                yRange = yMax - yMin;
                padding = 0.05 * yRange;
                     %10% padding above/eblow
                
                 ylim([yMin - padding, yMax + padding]);

                % Plot Group Mean ± SEM
                if overlayGroupMean
                    means = NaN(1, numel(conditionOrder));
                    sems = NaN(1, numel(conditionOrder));
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
                
               % Plot Mean and SEM
                  %white behind mean line to add contrast
                    plot(1:numel(conditionOrder), means, '--', 'Color', [0.9 0.9 0.9], 'LineWidth', 9, 'HandleVisibility', 'off');
                    plot(1:numel(conditionOrder), means, '--', 'Color', [0.8 0.8 0.8], 'LineWidth', 7, 'HandleVisibility', 'off');
                    
                    % Final black mean line WITH legend entry
                    plot(1:numel(conditionOrder), means, '--k', 'LineWidth', 3, 'DisplayName', 'Group Mean');

                    errorbar(1:numel(conditionOrder), means, sems, '--k', ...
                        'LineWidth', 3, 'DisplayName', 'Group Mean');
                end

                 % Plot Each Subject (subject loop)
                usedPointCoords = zeros(0, 2);
                            %to compare and see if need jittering
                labelData = [];
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
                    lineColor = colors(mod(i-1, size(colors, 1)) + 1, :);
                    xVals = 1:numel(conditionOrder);
                    xJittered = xVals;
                    jitterAmount = 0.06;

                    % Jitter overlapping points
                    for p = 1:numel(yVals)
                        if isnan(yVals(p)), continue; end %skip over missing data

                        %Check if another point exists at same (x, y)
                        isOverlap = any(abs(usedPointCoords(:, 1) - xVals(p)) < 0.01 & ...
                                        abs(usedPointCoords(:, 2) - yVals(p)) < 0.01);
                        if isOverlap
                            xJittered(p) = xVals(p) + jitterAmount;
                        end
                        usedPointCoords(end+1, :) = [xJittered(p), yVals(p)];
                            %adds it for comparison to future points
                    end

                    % Plot with jittered x values
                    plot(xJittered, yVals, '-o', 'LineWidth', 1.75, 'Color', lineColor, ...
                        'MarkerFaceColor', lineColor);


                 %Label end of line w/ subject ID
                    %first extract fast DV value (so can use to sort below)
                        lastIdx = find(~isnan(yVals), 1, 'last');
                    if ~isempty(lastIdx)
                        %create structs for:
                        labelData(end+1).Subject = subj; %subject ID
                        labelData(end).Y = yVals(lastIdx); %fast DV value 
                        labelData(end).Xval = find(conditionOrder == subjData.Condition(end));  %x-axis (so what condition)
                            %should always be fast, but jic missing data
                        labelData(end).Color = lineColor; %what color that line is
                    end
                end

                % Plot Subject Labels at End of Lines
                    % stagger subject labels horizontally for readability
                if ~isempty(labelData)
                    [~, sortIdx] = sort([labelData.Y]);
                    labelData = labelData(sortIdx);

                    hAlign = 'left';
                    offsets = [0.08, 0.18, 0.28, 0.38];

                    for i = 1:numel(labelData)
                        s = labelData(i);
                        xBase = s.Xval; %what cond. subject;s last point is
                        yBase = s.Y; %dv value
                        % Alternate horizontal label position to prevent overlap
                        xLabel = xBase + offsets(mod(i-1, numel(offsets)) + 1);
                            %moves each in the descending line over one spot to the R
                        yLabel = yBase;

                        % Connector line from label to last point
                        plot([xBase, xLabel], [yBase, yLabel], ':', 'Color', s.Color, 'LineWidth', 1.5);

                        % Label box-Label with matching colored background for clarity
                        textColor = 'w';
                        if mean(s.Color) > 0.7
                            textColor = 'k';
                        end

                        text(xLabel, yLabel, s.Subject, ...
                            'FontSize', 9, 'FontWeight', 'bold', ...
                            'BackgroundColor', s.Color, ...
                            'Margin', 1.2, ...
                            'EdgeColor', 'none', ...
                            'Color', textColor, ...
                            'HorizontalAlignment', hAlign, ...
                            'VerticalAlignment', 'middle');
                    end
                end

                % Final Formatting
                title(sprintf('%s - %s', DV, grp.label), 'FontWeight', 'bold', 'Interpreter', 'none');

                xticks(1:numel(conditionOrder));
                xticklabels(conditionOrder);
                xtickangle(45);
                ylabel(sprintf('%s (%s)', DV, dvUnitLabel), 'Interpreter', 'none');
                xlim([0.5, numel(conditionOrder) + 1.5]);  % Extra space for labels
                grid on;
                hold off;

                % Legend
                if overlayGroupMean
                    legend({'Group Mean'}, 'Location', 'eastoutside');
                end

                % Save Figure
                meanTag = "withMean";
                if ~overlayGroupMean, meanTag = "noMean"; end
                saveName = sprintf('%s_%s_%s_SpaghettiPlot.png', DV, grp.tag, meanTag);
                saveFigDir = fullfile(dataFiguresFolderDir, 'group', 'spaghettiPlot');
                if ~exist(saveFigDir, 'dir'), mkdir(saveFigDir); end
                saveas(gcf, fullfile(saveFigDir, saveName));

                % Export to PDF
                if plotAllDVs && saveToPDF
                    exportgraphics(gcf, pdfFilePath, 'Append', true);
                    close(gcf);
                end
            end
        end
    end
end
