function runDVANOVAs(dvNames, anovaData, speedConditions)
    %this function runs mixed methods ANOVAS on the data stored in StatsFormatTable (created by extractall script)
    %inputs:
        %dvNames = DVs to run ANOVAS on
        %anovaData = subset of StatsFormatTable with desired
            %speed conditions

    % Get subject id list w no duplicates
    Subjects = unique(anovaData.Subject);
        

    for v = 1:length(dvNames)
        dvName = dvNames{v};
        fprintf('\nRunning ANOVA for %s\n', dvName);

        %reorganize data:
        subjectGroups = []; 
        dvPerCondition = table();
        
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

        %repeated mesures ANOVA with speeds as w/in subjects factor:
        withinDesign = table(speedConditions', 'VariableNames', {'Condition'});
        modelSpec = strjoin(cellstr(speedConditions), ',') + " ~ Group";
        
        rm = fitrm(dvPerCondition, modelSpec, 'WithinDesign', withinDesign);
        %run it
        ranovatbl = ranova(rm, 'WithinModel', 'Condition');
        
        % Display results
        disp(ranovatbl);
    end
end
