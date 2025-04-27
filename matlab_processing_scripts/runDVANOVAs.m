function runDVANOVAs(dvNames, anovaData, speedConditions)
    %inputs:
        %dvNames = DVs to run ANOVAS on
        %anovaData = subset of StatsFormatTable with desired
            %speed conditions    
    %this function runs mixed methods ANOVAS on the data stored in StatsFormatTable (created by extractall script)
    %also runs post-hoc t-tests if anova effect p<0.05
        %repeated measures with turkey-kramer correction for significant effect of speed conditions
    %It also checks assumptions for mixed methods ANOVA (within and between subjects) and
        %compares to group size and symmetry
        %prompts for nonparametric alternative when warranted
            %using runNonParametricTests subfunction


    % Get subject id list w no duplicates
    Subjects = unique(anovaData.Subject);
        

    %initialize trackers for assumptions:
    withinNormalityViolations = {};
    betweenNormalityViolations = {};
    betweenVarianceViolations = {};
    sphericityViolations = {};



    for v = 1:length(dvNames)
        
        dvName = dvNames{v};
        fprintf('\nRunning ANOVA for %s\n', dvName);

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
       

%%%%%%CHECK NORMALITY ASSUMPTIONS AND EVAL IF NONPARAMETRIC TESTING IS WARRANTED%%%%%%%%   
        %initialize assumption violation warnings to prompt move to nonparametrics:
        betweenNormalityOK = true;
        withinNormalityOK = true;
        %variance violations will still proceed with ANOVA, just with Welch's F for between group comparisons


    %%%%check between subject normality (shapiro-wilke)
            %violations ok if equal sized groups and groups have n=10+ each
            %otherwise, violations --> kruskal wallis
        groups = categories(dvPerCondition.Group);
        for g = 1:length(groups)
            grpIdx = dvPerCondition.Group == groups{g};
            grpData = mean(dvPerCondition{grpIdx, speedConditions}, 2, 'omitnan'); % average across conditions
            [h, p] = swtest(grpData, 0.05); % Shapiro-Wilk test
            fprintf('S-W for between-group normality, Group %s: p = %.4f\n', groups{g}, p);
            if h == 1
                fprintf('\nAssessing assumptions for for %s:\n', dvName);
                fprintf('Warning: Between subjects normality violated for Group %s (p=%.4f)\n', groups{g}, p);
                betweenNormalityViolations{end+1} = dvName; % ADD DV name to tracking list
                betweenNormalityOK = false; %flags it
            end
        end
           
    
  %%%%%%%check within subject normality (shapiro-wilke for each speed)
        %violations ok if total n >15-20 (30) (all groups combined) 
        %otherwise, use Friedman's
       % Test normality of each speed condition
        for c = 1:length(speedConditions)
            condData = dvPerCondition{:, speedConditions(c)};
            condData = condData(~isnan(condData)); % remove any NaNs
            [h, p] = swtest(condData, 0.05);
            fprintf('Shapiro-Wilk for condition %s: p=%.4f\n', speedConditions(c), p);
            if h == 1
                fprintf('\nAssessing assumptions for for %s:\n', dvName);
                fprintf('Warning: Normality violated at condition %s (p=%.4f)\n', speedConditions(c), p);
                withinNormalityViolations{end+1} = sprintf('%s - %s', dvName, speedConditions(c)); %ADD DV name to tracking list
                withinNormalityOK = false; %flags it
            end
        end
        
       %%testing normality of difference scores via shapiro-wilke (not warranted here)
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


%%%%%%%%%decide whether to proceed with ANOVA or switch to nonparametric
        
        safeForANOVA = true;

        if ~betweenNormalityOK 
            if nHealthy ~= nCVA || any(groupSizes < 10) 
                fprintf('..........Subjects included for %s: Healthy (H) = %d, CVA = %d, Total = %d\n', dvName, nHealthy, nCVA, nTotal);
                fprintf('S-W for between subject normality failed AND unequal groups or groups n<10 . Consider K-W Test\n');
                safeForANOVA = false;
            else
                fprintf('But groups are equal size and n ≥10 per group --> ANOVA still valid\n');          
            end
        end


        if ~withinNormalityOK
            %if nTotal < 20
            if nTotal < 25 %for testing nonparametric
                fprintf('..........Subjects included for %s: Healthy (H) = %d, CVA = %d, Total = %d\n', dvName, nHealthy, nCVA, nTotal);
                fprintf('S-W for within subject normality failed AND total n<20. Consider Friedmans Chi Square Test\n');
                safeForANOVA = false;
            else
                fprintf('But total n >20 --> ANOVA still valid\n');          
            end
        end
  
        if ~safeForANOVA
            userChoice = input('Assumptions not fully met as described above. Run nonparametric tests instead? (Y/N): ', 's');
            if strcmpi(userChoice, 'Y')
                runNonParametricTests(dvPerCondition, speedConditions, dvName, subjectGroups, betweenNormalityOK, withinNormalityOK);
                continue; % Skip normal ANOVA and move to next DV
            elseif strcmpi(userChoice, 'N')
                fprintf('Continuing with ANOVA anyway (interpret cautiously).\n');
            end
        end
           


%%%%%%%%%%%%RUN ANOVA%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %mixed methods ANOVA with speeds as w/in subjects factor and group as between subejcts factor
        withinDesign = table(speedConditions', 'VariableNames', {'Condition'});
        modelSpec = strjoin(cellstr(speedConditions), ',') + " ~ Group";
        
        rm = fitrm(dvPerCondition, modelSpec, 'WithinDesign', withinDesign);
        %run it
        ranovatbl = ranova(rm, 'WithinModel', 'Condition');
        
        % Display results
        disp(ranovatbl);
            %intercept: overall mean
            %group- main effect
            %intercept:condition: condition main effect
            %group:condition: interaction effect
            %Error(Condition) = residual error for within-subjects
                % -not accounted for by main or interaction effects
           

    %%%% add effect size for ANOVA and rmANOVA?
        %ANOVA: η2 (“eta-squared”) 
            %= (F * df(between groups)) / (F * df(between groups) + DF(within groups)
                %0.01-0.059 small, 0.06-0.139 medium, >0.14 large 
                    %ie: 0.14 --> 14% of variance is due to group difference
        %RM ANOVA: partial η2 = (F * df(effect)) / ((F * df(effect)) + df(denominator))
        

        
%%%%%%%%%%CONSIDER VARIANCE AND SPHERICITY ASSUMPTION VIOLATIONS%%%%%%%%%  
          
        %%%issues with between subject variance (Levene's)
            %violations ok if equal sized groups and groups have n=10+ each
            %otherwise, use Welch's F
        groupLabels = dvPerCondition.Group;
        avgAcrossConditions = mean(dvPerCondition{:, speedConditions}, 2, 'omitnan'); % average across conditions
        [p_levene, tbl_levene] = vartestn(avgAcrossConditions, groupLabels, 'TestType', 'LeveneAbsolute', 'Display', 'off');
        fprintf('Levene''s Test for between-group variance: p = %.4f\n', p_levene);
        if p_levene < 0.05 
            fprintf('Warning: Between subjects variance violated between groups (Levene p=%.4f)\n', p_levene);
            betweenVarianceViolations{end+1} = dvName; % ADD DV name to tracking list

            %check group size:
            groupSizes = [nHealthy, nCVA];
            if nHealthy ~= nCVA || any(groupSizes < 10)
             %if Levene's test showed violation of between subjects variance and either unequal groups or n per group <10, use Welch's to assess for main effect of group
                    %%MLdoesn't have welch's F function, but Group only has 2 levels so can use Welch's T
                avgAcrossConditions = mean(dvPerCondition{:, speedConditions}, 2, 'omitnan');
                grp1 = avgAcrossConditions(groupLabels == 'H');
                grp2 = avgAcrossConditions(groupLabels == 'CVA');
                [~, p_welch, ~, stats_welch] = ttest2(grp1, grp2, 'Vartype', 'unequal');
                fprintf('\nLevene''s failed AND group sizes unequal or n<10 per group. Use Welchs T p value instead of ANOVAs row for Group. Can still use ANOVA for effect of speed and interaction effect\n');
                fprintf('Welch''s t-test result for effect of group: t(%.1f) = %.3f, p = %.4f\n', stats_welch.df, stats_welch.tstat, p_welch);
                fprintf('-----------------------------\n');
            else  
                fprintf('Between subjects variance violated between groups (Levene p=%.4f < 0.05). But groups are equal size and n ≥10 per group --> ANOVA still valid for Group.\n', p_levene);
                fprintf('-----------------------------\n');
            end
        end
              
      
        %%%issues with within subject sphericity (mauchleys))
            %done by RANOVA automatically and,if violated, applies GG correctio
            %%compare regular and GG adjusted p values to see if sphericity was violated
            %%if violated, prompts to use GG adjusted p  values 
        conditionRow = strcmp(ranovatbl.Properties.RowNames, '(Intercept):Condition');
        pVal = ranovatbl.pValue(conditionRow);
        pValGG = ranovatbl.pValueGG(conditionRow);
        if abs(pVal - pValGG) > 1e-6   % tiny allowance for numerical differences
            fprintf('Sphericity likely violated for %s. Use pValueGG (%.4f) instead of pValue (%.4f).\n', dvName, pValGG, pVal);
            sphericityViolations{end+1} = dvName; % ADD DV name to tracking list
        end


    %%%%%%%%%POST-HOC TESTS%%%%%%%%%%%%
        
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
            fprintf('\nPost-hoc t-tests for %s (because ANOVA p=%.4f < 0.05):\n', dvName, conditionP);
            posthoc = multcompare(rm, 'Condition', 'ComparisonType', 'tukey-kramer');
            % display only unique comparisons (no duplicates)
                %matlab only corrects p values for # of unique comparisons
            keepRows = posthoc.Condition_1 < posthoc.Condition_2;
            posthocUnique = posthoc(keepRows, :);

            disp(posthocUnique);
       
        end
    fprintf('\n===========================================\n\n');
    end

fprintf('\n========= SUMMARY OF ASSUMPTION VIOLATIONS =========\n');

fprintf('\nBetween-subjects normality violations:\n');
disp(unique(betweenNormalityViolations));

fprintf('\nBetween-subjects variance violations (Levene''s):\n');
disp(unique(betweenVarianceViolations));

fprintf('\nWithin-subjects normality violations:\n');
disp(unique(withinNormalityViolations));

fprintf('\nWithin-subjects sphericity violations:\n');
disp(unique(sphericityViolations));

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
                
%

function runNonParametricTests(dvPerCondition, speedConditions, dvName, subjectGroups, betweenNormalityOK, withinNormalityOK)
%this function 
    %checks assumptions for K-W and Friedman tests
   %runs K-W tests when between subject normality is violated and group sizes are unequal or n<10 each
   %runs Friedman when within subject normalty is violated and total n <20

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
  %%%%perform K-W test:
    if ~betweenNormalityOK %run K-W
        %average across conditions
        p_kw = kruskalwallis(dataMean, groupLabels, 'off');
        fprintf('Kruskal-Wallis Test for between-group effect: p=%.4f\n', p_kw);
        fprintf('Group sizes for K-W: H = %d, CVA = %d\n', nH, nCVA);
        %post-hoc with 2-sample Wilcoxin tests, but not needed bc only 2 grouplevels
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

 
%%%%%%%% issues with within subject normality and total n <20 
    %assumptions checked above
    if ~withinNormalityOK
        p_friedman = friedman(dataMatrix, 1, 'off');
        fprintf('Friedman Test for within-subjects effect (Condition): p=%.4f\n', p_friedman);
        fprintf('Group sizes for Friedman: H = %d, CVA = %d\n', nH, nCVA);
        
        %post-hoc tests with paired sample wilcoxin tests if Friedman p<0.05
        if p_friedman < 0.05
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
                fprintf('%s: p = %.4f\n', labels(i), pValues(i));
            end
        else
            fprintf('No post-hoc tests warranted (Friedman p>0.05)\n');
            
        end     

%%%%(No real nonparametric equivalent for interaction effect

    end


end