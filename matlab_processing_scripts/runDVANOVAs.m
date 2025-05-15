function runDVANOVAs(dvNames, anovaData, speedConditions)
    %inputs:
        %dvNames = DVs to run ANOVAS on
        %anovaData = subset of integratedDataTable with desired speed conditions and DVs    
    %this function runs mixed methods ANOVAS on the data stored in integratedDataTable (created by extractall script)
    %also runs post-hoc t-tests if anova effect p<0.05
        %repeated measures with turkey-kramer correction for significant effect of speed conditions
        %no need for post-hoc group comparisons, as only 2 factors
    %It also checks assumptions for mixed methods ANOVA (within and between
    %subjects) and, if violated:
        %compares to group size and symmetry to determine ANOVA validity
        %provides adjusted p values when warranted
        %runs nonparametric alternative when warranted
            %using nested runNonParametricTests subfunction
    %marks statistically significant results with "***"
    %provides summary of assumption violations


    % Get subject id list w no duplicates
    Subjects = unique(anovaData.Subject);

    % Initialize assumption summaries
    assumptionSummary = struct('BetweenNormality', [], 'WithinNormality', [], ...
        'BetweenVariance', [], 'Sphericity', []);

    %initialize sig post-hoc results tracker
    allSignificantResults = table();
    sigResultsSavePath = fullfile(dataTablesFolderDir, 'SignificantComparisons.mat');



    for v = 1:length(dvNames)
        dvName = dvNames{v};
        fprintf('*********************************\n'); 
        fprintf('\nRunning Analysis for %s\n', dvName);

        %reorganize data:
        subjectGroups = []; 
        dvPerCondition = table();


        %build dvPerCondition
        for i = 1:length(Subjects)
            subj = Subjects(i);
            dvData = anovaData(anovaData.Subject == subj, :);
                 %only include subjects if they have data for all speed conditions
                    %ie: skip S1 (missing baseline)
            if all(ismember(speedConditions, dvData.Condition))
                row = table(subj, 'VariableNames', {'Subject'});
                for c = 1:length(speedConditions)
                    cond = speedConditions(c);
                    val = dvData.(dvName)(dvData.Condition == cond);
                    row.(char(cond)) = val;
                end
                dvPerCondition = [dvPerCondition; row];
                subjectGroups = [subjectGroups; dvData.Group(1)];
                    %store that group's data for selected DV
            end
        end

     
        %make group a categorical variable
        dvPerCondition.Group = categorical(subjectGroups);
        dvPerCondition.Subject = categorical(dvPerCondition.Subject);


        %calculate n per group and total n for displaying later
        nHealthy = sum(dvPerCondition.Group == 'H');
        nCVA = sum(dvPerCondition.Group == 'CVA');
        nTotal = nHealthy + nCVA;
       

%%%%%%CHECK  ASSUMPTIONS AND EVAL IF NONPARAMETRIC TESTING IS WARRANTED%%%%%%%%   
        %initialize assumption violation warnings to prompt move to nonparametrics:
        % betweenNormalityOK = true;
        % withinNormalityOK = true;
        %variance violations will still proceed with ANOVA, just with Welch's F for between group comparisons


    %%%%check between subject normality (shapiro-wilke)
            %violations ok if equal sized groups and groups have n=10+ each
            %otherwise, violations --> kruskal wallis
        groups = categories(dvPerCondition.Group);
        betweenSW = struct();
        fprintf('\n---Between-Subjects Normality (Shapiro-Wilk per group)---\n');
        for g = 1:length(groups)
            grpIdx = dvPerCondition.Group == groups{g};
            grpData = mean(dvPerCondition{grpIdx, speedConditions}, 2, 'omitnan'); % average across conditions
            [~, pVal] = swtest(grpData, 0.05); % Shapiro-Wilk test
            betweenSW.(groups{g}) = pVal;
            fprintf('  %s: p = %.4f\n', groups{g}, pVal);
        end

        bn_pvals = struct2array(betweenSW);
        if all(bn_pvals > 0.05)
            BNstatus = "BNgood";
            BNreadable = "intact";
        elseif any(bn_pvals < 0.05) && nHealthy >= 15 && nCVA >= 15 && nHealthy == nCVA
            BNstatus = "BNok";
            BNreadable = "Violated but acceptable due to sample size";
        else
            BNstatus = "BNbad";
            BNreadable = "Violated (use nonparametrics)";
        end
        
        switch BNstatus
            case "BNgood"
                fprintf('  All groups p > 0.05. Normality assumption met.\n');
            case "BNok"
                violators = fields(betweenSW);
                violators = violators(bn_pvals < 0.05);
                fprintf('  Warning: Normality violated for group(s): %s, but group sizes are equal and ≥10 per group — ANOVA still valid.\n', strjoin(violators, ', '));
            case "BNbad"
                violators = fields(betweenSW);
                violators = violators(bn_pvals < 0.05);
                fprintf('  WARNING: Normality violated for group(s): %s AND groups unequal or n <10. Consider Kruskal-Wallis results below.\n', strjoin(violators, ', '));              
        end


          %%%%%%%check within subject normality (shapiro-wilke for each speed)
        %violations ok if total n >15-20 (30) (all groups combined) 
        %otherwise, use Friedman's
       % Test normality of each speed condition
        withinSW = struct();
        fprintf('\n---Within-Subjects Normality (Shapiro-Wilk per speed Condition)---\n');
        for c = 1:length(speedConditions)
            condData = dvPerCondition{:, speedConditions(c)};
            condData = condData(~isnan(condData));
            [~, pVal] = swtest(condData, 0.05);
            withinSW.(char(speedConditions(c))) = pVal;
            fprintf('  %s: p = %.4f\n', speedConditions(c), pVal);
        end
            
                    %%testing normality of difference scores via shapiro-wilke (not warranted here)
                    %saving for future use
                    %Create difference scores
                    %differences = [];
                    %for i = 1:length(speedConditions)
                     %   for j = i+1:length(speedConditions)
                     %      diff = dvPerCondition{:, speedConditions(i)} - dvPerCondition{:, speedConditions(j)};
                     %       differences = [differences; diff];
                     %   end
                    %end
                    % Test normality of difference scores
                    %[h_diff, p_diff] = swtest(differences(:), 0.05);
                    %if h_diff == 1
                    %    fprintf('\nAssessing assumptions for for %s:\n', dvName);
                    %    fprintf('Warning: Within-subjects normality violated (S-W p=%.4f)\n', p_diff);
                    %    withinNormalityViolations{end+1} = dvName; % ADD DV name to tracking list
                    %    withinNormalityOK = false; %flags it
                    %end

        wn_pvals = struct2array(withinSW);

        if all(wn_pvals > 0.05)
            WNstatus = "WNgood";
            WNreadable = "intact";
        elseif any(wn_pvals < 0.05) && nTotal >= 25
            WNstatus = "WNok";
            WNreadable = "Violated but acceptable due to sample size";
        else
            WNstatus = "WNbad";
            WNreadable = "Violated (use nonparametrics)";
        end

        switch WNstatus
            case "WNgood"
                fprintf(' W/in subject normality intact for all conditions (SW p > 0.05).\n');
            case "WNok"
                violators = fields(withinSW);
                violators = violators(wn_pvals < 0.05);
                fprintf('W/in subject normality violated at condition(s): %s, but total n ≥ 20 —-> ANOVA still valid.\n', strjoin(violators, ', '));
            case "WNbad"
                violators = fields(withinSW);
                violators = violators(wn_pvals < 0.05);
                fprintf('W/in subject normality violated at condition(s): %s AND total n < 20 —-> Consider Friedman Test results below.\n', strjoin(violators, ', '));
        end
          
            
    %%%check between subject variance (Levene's)
            %violations ok if equal sized groups and groups have n=10+ each
            %otherwise, use Welch's F
            
        fprintf('\n--Between-Subjects Variance (Levene''s Test) ---\n');

        avgDV = mean(dvPerCondition{:, speedConditions}, 2, 'omitnan'); % average across conditions
        [p_levene, ~] = vartestn(avgDV, dvPerCondition.Group, 'TestType', 'LeveneAbsolute', 'Display', 'off');
        
        fprintf('  Levene''s Test p = %.4f\n', p_levene);
 
        grp1 = avgDV(dvPerCondition.Group == 'H');
        grp2 = avgDV(dvPerCondition.Group == 'CVA');
        [~, p_welch, ~, stats_welch] = ttest2(grp1, grp2, 'Vartype', 'unequal');


        if p_levene > 0.05
            BVstatus = "BVgood";
            BVreadable = "intact"
        elseif p_levene < 0.05 && nHealthy >= 10 && nCVA >= 10 && nHealthy == nCVA
            BVstatus = "BVok";
            BVreadable = "Violated but acceptable due to sample size"
        else
            BVstatus = "BVbad";
            readable = "Violated (use Welch's T)"
        end
    
        switch BVstatus
            case "BVgood"
                fprintf('Variance assumption met b/n groups.\n');
                fprintf('\n');  % Adds a blank line
            case "BVok"
                fprintf('Variance violated b/n groups, but groups equal size and n ≥ 10 —-> ANOVA still valid.\n');
                fprintf('\n');                 
            case "BVbad"
                fprintf('Variance violated b/n groups AND groups unequal or n < 10 —-> Use Welchs T p value instead of ANOVAs row for Group. Can still use ANOVA for effect of speed and interaction effect.\n');
                fprintf('Welch''s t-test result for effect of group: t(%.1f) = %.3f, p = %.4f\n', stats_welch.df, stats_welch.tstat, p_welch);
                fprintf('\n'); 
        end

        assumptionSummary.BetweenNormality = [assumptionSummary.BetweenNormality; 
            struct('DV', dvName, 'Status', BNreadable, 'Groups', {groups}, 'pVals', {bn_pvals})];
        assumptionSummary.WithinNormality = [assumptionSummary.WithinNormality; 
            struct('DV', dvName, 'Status', WNreadable, 'Conditions', {speedConditions}, 'pVals', {wn_pvals})];        
        assumptionSummary.BetweenVariance = [assumptionSummary.BetweenVariance; 
            struct('DV', dvName, 'Status', BVreadable, 'pVal', p_levene)];


        safeForANOVA = ~(strcmp(BNstatus, 'BNbad') || strcmp(WNstatus, 'WNbad'));

      
        %mixed design ANOVA with speeds as w/in subjects factor and group as between subejcts factor
        withinDesign = table(speedConditions', 'VariableNames', {'Condition'});
        modelSpec = strjoin(cellstr(speedConditions), ',') + " ~ Group";
        rm = fitrm(dvPerCondition, modelSpec, 'WithinDesign', withinDesign);
        ranovatbl = ranova(rm, 'WithinModel', 'Condition');
         
            %%%issues with within subject sphericity (mauchleys))
                %done by RANOVA automatically and,if violated, applies GG correctio
                %%compare regular and GG adjusted p values to see if sphericity was violated
                %%if violated, prompts to use GG adjusted p  values 
        conditionRow = strcmp(ranovatbl.Properties.RowNames, '(Intercept):Condition');
        pVal = ranovatbl.pValue(conditionRow);
        pValGG = ranovatbl.pValueGG(conditionRow);
        if abs(pVal - pValGG) > 1e-6   % tiny allowance for numerical differences
            fprintf('Sphericity likely violated for %s. Use pValueGG (%.4f) instead of pValue (%.4f).\n', dvName, pValGG, pVal);
            fprintf('\n');  %  blank line

            assumptionSummary.Sphericity = [assumptionSummary.Sphericity; {dvName, 'Violated (use GG-adjusted values)'}];
            conditionP = pValGG;
        else
            fprintf('Sphericity assumption met. Use regular p value\n');
            assumptionSummary.Sphericity = [assumptionSummary.Sphericity; {dvName, 'Intact'}];
            conditionP = pVal;
        end
        
        fprintf('\n----- Full ANOVA Results for %s -----\n', dvName);
        fprintf('Subjects included for %s: Healthy (H) = %d, CVA = %d, Total = %d\n', dvName, nHealthy, nCVA, nTotal);
        if ~ safeForANOVA 
            fprintf('\n');
            fprintf('ANOVA ASSUMPTIONS VIOLATED. See nonparametric results below. Interpret ANOVA results with caution\n');
        end


        disp(ranovatbl);
            %intercept: overall mean
            %group- main effect
            %intercept:condition: condition main effect
            %group:condition: interaction effect
            %Error(Condition) = residual error for within-subjects
                % -not accounted for by main or interaction effects

        % --- Significant ANOVA Effects ---
               %isolate rows for main and interaction effects to check for p<.05
        rowsOfInterest = ismember(ranovatbl.Properties.RowNames, {'Group', '(Intercept):Condition', 'Group:Condition'});
        fprintf('\n----- Significant Effects -----\n');
        for i = 1:height(ranovatbl)
            if rowsOfInterest(i)
                rowName = ranovatbl.Properties.RowNames{i};
                pVal = ranovatbl.pValue(i);
                %pValue = ranovatbl.pValueGG(i);  % Use GG-corrected when available

                %if BVstatus= BVbad, use welch's p value instead
                label = '';
                if strcmp(rowName, 'Group') && strcmp(BVstatus, 'BVbad')
                    p_val = p_welch;
                    label = ' (Welch Corrected)';
                    fprintf('Using Welch''s t-test for Group effect due to variance violation: p = %.4f\n', p_welch);
                elseif contains(rowName, 'Condition') && ismember('pValueGG', ranovatbl.Properties.VariableNames) && ...
                       ~isnan(ranovatbl.pValueGG(i))
                    p_val_gg = ranovatbl.pValueGG(i);
                    if abs(p_val - p_val_gg) > 1e-6
                        p_val = p_val_gg;
                        label = ' (GG-corrected)';
                    end
                else
                    p_val = ranovatbl.pValue(i);
                end

                


                 % Mark stat. significant results
                if pVal < 0.05
                    if contains(rowName, 'Group:Condition')
                        fprintf('*** %s%s: p = %.4f️ *** --> SIGNIFICANT interaction between Group and Condition\n', rowName, label, pVal);
                    elseif contains(rowName, '(Intercept):Condition')
                        fprintf('*** %s%s: p = %.4f *** --> SIGNIFICANT effect of Condition\n', rowName, label, pVal);
                    elseif contains(rowName, 'Group')
                        fprintf('*** %s%s: p = %.4f *** --> SIGNIFICANT effect of Group\n', rowName, label, pVal);
                    else
                        fprintf('*** %s%s: p = %.4f ***\n', rowName, label, pVal); % fallback
                    end
                else
                    fprintf('%s%s: p = %.4f (>0.05)\n', rowName, label, pVal);
                end
            end
        end
                          

    %%%% To do: add effect size for ANOVA and rmANOVA
        %ANOVA: η2 (“eta-squared”) 
            %= (F * df(between groups)) / (F * df(between groups) + DF(within groups)
                %0.01-0.059 small, 0.06-0.139 medium, >0.14 large 
                    %ie: 0.14 --> 14% of variance is due to group difference
        %RM ANOVA: partial η2 = (F * df(effect)) / ((F * df(effect)) + df(denominator))
        
      
        %ANOVA post-hocs
        %no post-hoc tests needed for main effect of group (only 2 levels)
        %post-hocs for main effect of speed condition:
            %check p-value for condition main effect:
        conditionP = ranovatbl.pValueGG(conditionRow);
            %using pValueGG bc:
                %if sphericity isn't violated, it will = reg p value
                %if sphericity is violated, want to reference pValueGG

        % Run post-hoc comparisons for speed condition only if ^^is significant
            %paired samples t-tests:
        if conditionP < 0.05
            posthoc = multcompare(rm, 'Condition', 'ComparisonType', 'tukey-kramer');
            % display only unique comparisons (no duplicates)
                %matlab only corrects p values for # of unique comparisons
            keepRows = posthoc.Condition_1 < posthoc.Condition_2;
            posthocUnique = posthoc(keepRows, :);

            %make table for sig results
            posthocUnique.Significant = posthocUnique.pValue < 0.05;
            % Add DV column for traceability
            posthocUnique.DV = repmat({dvName}, height(posthocUnique), 1);
            
            % Append only significant results to the master table
            significantResults = posthocUnique(posthocUnique.Significant, :);
            allSignificantResults = [allSignificantResults; significantResults];


            fprintf('\n--- Full Post-hoc Results for %s (Tukey-Kramer) ---\n', dvName);
            disp(posthocUnique);

            fprintf('\n--- Significant Post-hoc Results (Tukey-Kramer) ---\n');
            for i = 1:height(posthocUnique)
                c1 = posthocUnique.Condition_1(i);
                c2 = posthocUnique.Condition_2(i);
                pVal = posthocUnique.pValue(i);
            
                if pVal < 0.05
                    fprintf('%s vs %s: p = %.4f *** SIGNIFICANT\n', c1, c2, pVal);
                else
                    fprintf('%s vs %s: p = %.4f (>0.05)\n', c1, c2, pVal);
                end
            end
        end
    
        if ~ safeForANOVA        
            nonParamResults = runNonParametricTests(dvPerCondition, speedConditions, dvName, subjectGroups, BNstatus, WNstatus);
            if ~isempty(allSignificantResults)
                save(sigResultsSavePath, 'allSignificantResults');
            end
        end


    if ~isempty(allSignificantResults)
        save('SignificantComparisons.mat', 'allSignificantResults');
    end



    fprintf('\n========= SUMMARY OF ASSUMPTION VIOLATIONS =========\n');

    WNbad = "violated";
    
    fprintf('\nBetween-Subjects Normality:\n');
    for i = 1:length(assumptionSummary.BetweenNormality)
        thisEntry = assumptionSummary.BetweenNormality(i);
        pValsStr = sprintf('%.4f, ', thisEntry.pVals);
        pValsStr = pValsStr(1:end-2); % Remove the trailing comma and space
        fprintf('  %s: %s, p-values = [%s]\n', thisEntry.DV, thisEntry.Status, pValsStr);
    end
    
    fprintf('\nWithin-Subjects Normality:\n');
    for i = 1:length(assumptionSummary.WithinNormality)
        thisEntry = assumptionSummary.WithinNormality(i);
        pValsStr = sprintf('%.4f, ', thisEntry.pVals);
        pValsStr = pValsStr(1:end-2); % Remove the trailing comma and space
        fprintf('  %s: %s, p-values = [%s]\n', thisEntry.DV, thisEntry.Status, pValsStr);
    end
    
    fprintf('\nBetween-Subjects Variance:\n');
    for i = 1:length(assumptionSummary.BetweenVariance)
        thisEntry = assumptionSummary.BetweenVariance(i);
        fprintf('  %s: %s (p = %.4f)\n', thisEntry.DV, thisEntry.Status, thisEntry.pVal);
    end
    
    fprintf('\nSphericity Violations:\n');
    for i = 1:size(assumptionSummary.Sphericity, 1)
        fprintf('  %s: %s\n', assumptionSummary.Sphericity{i, 1}, assumptionSummary.Sphericity{i, 2});
    end
    end

    if ~isempty(allSignificantResults)
        fprintf('\n========= SIGNIFICANT POST-HOC RESULTS =========\n');
        disp(allSignificantResults);
    else
        fprintf('\n========= NO SIGNIFICANT POST-HOC RESULTS FOUND =========\n');
    end
end
    
    



%ANOVA next steps:
    %do factorial ANOVA with BetaBlocker as additional categorical factor for pupil 
        %assumptions:
            %between subjects normality (shapiro-wilke for each factor)
                %ok if groups are the same size
            %between subjects variance (levene's for each factor)
                %ok if all groups are same size
        %post-hocs (if factor has >2 levels)
            %pairwise t-tests
        %factorial ANOVA effect size
            %Partial η2 (for each effect/interaction)
                %= (F * df(effect)) / ((F *df(effect) + df(denom))
                

function runNonParametricTests(dvPerCondition, speedConditions, dvName, subjectGroups, BNstatus, WNstatus)
%this function 
    %checks assumptions for K-W and Friedman tests
   %runs K-W tests when between subject normality is violated and group sizes are unequal or n<10 each
   %runs Friedman when within subject normalty is violated and total n <20

    nonParametricResults = table();

    fprintf('\n===== Running NONPARAMETRIC tests for %s =====\n', dvName);
      
    %prepare data:
    dataMatrix = table2array(dvPerCondition(:, speedConditions));
    dataMean = mean(dataMatrix, 2, 'omitnan');
    groupLabels = dvPerCondition.Group;


    % Remove any rows of subjects that have NaNs
    nanSubjects = any(ismissing(dataMatrix), 2); % rows with any NaN
    if any(nanSubjects)
        dataMatrix(nanSubjects, :) = []; % Remove those rows
        subjectGroups(nanSubjects) = []; % remove matching group labels too
        groupLabels = subjectGroups; %update groupLabels to have no NaN subjects
    end

    % update dataMean with no NaNs
    dataMean = mean(dataMatrix, 2, 'omitnan');


    %find n#s per group
    nH = sum(groupLabels == 'H');
    nCVA = sum(groupLabels == 'CVA');

    %%check assumptions of K-W and Friedman (few to no tied scores, each group has 5+ scores)
    % Check group sample sizes
    fprintf('Group sizes: H = %d, CVA = %d\n', nH, nCVA);
    if nH < 5 || nCVA < 5
        warning('Warning: One or more groups has <5 subjects. K-W / Friedman test assumptions may be violated.');
    end

    %check tied scores
    [uniqueVals, ~, counts] = unique(dataMean);
    numTies = length(dataMean) - length(uniqueVals);
    fprintf('Number of tied scores: %d out of %d total\n', numTies, length(dataMean));
    
    % Warning if too many ties
    if numTies / length(dataMean) > 0.2 % more than 20% tied (accepted threshold)
        warning('Warning: >20%% of scores are tied. K-W / Friedman test assumptions may be violated.');
    end


 %%%%%%%% issues with between subject normality and unequal groups/small n  
        % --> use kruskal wallis to assess between subjects main effect of group
  %%%%perform Kruskal-Wallis for Between-Subjects Effect
    if BNstatus == "BNbad" %run K-W
        %average across conditions
        p_kw = kruskalwallis(dataMean, groupLabels, 'off');
        fprintf('Kruskal-Wallis Test for between-group effect: p=%.4f\n', p_kw);
        fprintf('Group sizes for K-W: H = %d, CVA = %d\n', nH, nCVA);
        %post-hoc with 2-sample Wilcoxin tests, but not needed bc only 2 grouplevels
        %keeping code here for future use if ever needed
        %if p_kw < 0.05
            %fprintf('Running post-hoc Wilcoxon rank-sum test between H and CVA...\n');
            % Separate groups
            %dataH = dataMean(groupLabels == 'H');
            %dataCVA = dataMean(groupLabels == 'CVA');
            % Wilcoxon rank-sum test (Mann-Whitney U)
            %[p_wilcoxon, h_wilcoxon, stats] = ranksum(dataH, dataCVA);
            %fprintf('Wilcoxon rank-sum p = %.4f\n', p_wilcoxon);
        %end
    end

 
%%%%%%%%% Friedman for Within-Subjects Effect
            %issues with within subject normality and total n <20 
    %assumptions checked above
    if WNstatus == "WNbad"
        fprintf('Group sizes for Friedman: H = %d, CVA = %d\n', nH, nCVA);
        p_friedman = friedman(dataMatrix, 1, 'off');
        if p_friedman <0.05
            fprintf('Friedman Test for within-subjects condition effect (Condition): p=%.4f *** SIGNIFICANT ️\n', p_friedman);
        else 
            fprintf('Friedman Test for within-subjects condition effect (Condition): p=%.4f (>0.05) ️\n', p_friedman);
        end

        
        %post-hoc tests with paired sample wilcoxin tests if Friedman p<0.05
        if p_friedman < 0.05

            % Prepare results table for significant post-hoc comparisons
            for i = 1:nComparisons
                if pValues(i) < alphaCorrected
                    newRow = table(...
                        string(speedConditions(comparisons(i,1))), ...
                        string(speedConditions(comparisons(i,2))), ...
                        NaN, NaN, pValues(i), NaN, NaN, true, ... % Placeholder for missing values (like Difference, StdErr, etc.)
                        'VariableNames', {'Condition_1', 'Condition_2', 'Difference', 'StdErr', 'pValue', 'Lower', 'Upper', 'Significant'});
                    newRow.DV = {dvName}; % Add DV information
                    nonParametricResults = [nonParametricResults; newRow];
                end
            end

            fprintf('Running post-hoc paired Wilcoxon tests between speed conditions with Bonferroni correction (adjusted alpha)...\n');
            
            nConditions = length(speedConditions);
            comparisons = nchoosek(1:nConditions,2);  % all unique pairs
            nComparisons = size(comparisons,1);
    
            %adjusted alpha:
            alphaCorrected = 0.05 / nComparisons;
            fprintf('Bonferroni-adjusted significance threshold: %.4f\n', alphaCorrected);
    
            pValues = zeros(nComparisons,1);
            labels = strings(nComparisons,1);
            
            % loop over all unique pairs of conditions
            for i = 1:nComparisons
                cond1 = comparisons(i,1);
                cond2 = comparisons(i,2);
    
                data1 = dataMatrix(:,cond1);
                data2 = dataMatrix(:,cond2);
                
                p = signrank(data1, data2); % Paired Wilcoxon signed-rank test
                pValues(i) = p;
                labels(i) = sprintf('%s vs %s', speedConditions(cond1), speedConditions(cond2));
                 % Display results  
            end
            for i = 1:nComparisons
                if pValues(i)<alphaCorrected
                    fprintf('%s: p = %.4f️ *** SIGNIFICANT (after Bonferroni)️\n', labels(i), pValues(i));
                else
                    fprintf('%s: p = %.4f (>bonferonni adjusted threshold) \n', labels(i), pValues(i));
                end
            end
        end
    end
end
      


%%%%(No real nonparametric equivalent for interaction effect

  
