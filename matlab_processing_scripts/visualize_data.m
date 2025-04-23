%still in progress-exploring best visualization for data

load('/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/gorin_CMBN_F4_project/DataTables/StatsFormatTable.mat');

%set group and speed category as categorical
statsFormatTable.Group = categorical(statsFormatTable.Group);
statsFormatTable.SpeedCategory = categorical(statsFormatTable.SpeedCategory, {'B', 'S', 'M', 'F'}, 'Ordinal', true); 


%for speed raw DV comparisons:
rawSpeedTrials = [1, 4, 6, 8];  
            %1=BL
            %4=S
            %5=S
            %8=M
            %6=F
            %7=F
            %so just keeping 1, 4, 6, and 8 for this graph
rawSpeedTrialsTable = statsFormatTable(ismember(statsFormatTable.Trial, rawSpeedTrials), :);


%for speed normalized DV comparisons:
BLnormSpeedTrials = [4, 6, 8];  
            %1=BL
            %4=S
            %5=S
            %8=M
            %6=F
            %7=F
            %so just keeping 4, 6, and 8 for this graph
BLnormSpeedTrialsTable = statsFormatTable(ismember(statsFormatTable.Trial, BLnormSpeedTrials), :);


groupedMeansRaw = groupsummary(rawSpeedTrialsTable, ...
    ["Subject", "Group", "SpeedCategory", "Condition", "Trial"], ...
    "mean", ["MeanHeartRate", "MeanPupilDiameter", "RR", "Delta_HR_BL", "Delta_Pupil_BL", "Delta_RR_BL"]);

groupedMeansBLNorm = groupsummary(BLnormSpeedTrialsTable, ...
    ["Subject", "Group", "SpeedCategory", "Condition", "Trial"], ...
    "mean", ["MeanHeartRate", "MeanPupilDiameter", "RR", "Delta_HR_BL", "Delta_Pupil_BL", "Delta_RR_BL"]);

%pupil vs speed by group:
    %line plot:
        figure;
        hold on;
        gscatter(groupedMeansRaw.SpeedCategory, groupedMeansRaw.mean_MeanPupilDiameter, ...
            groupedMeansRaw.Group, 'br', 'ox')
        
        xlabel('Speed Category');
        ylabel('Mean Pupil Diameter');
        title('Pupil Diameter Across Speeds by Group');
        legend('Healthy', 'CVA');
   
    %boxplot:
        figure;
        boxchart(categorical(rawSpeedTrialsTable.SpeedCategory), ...
                 rawSpeedTrialsTable.MeanPupilDiameter, ...
                 'GroupByColor', rawSpeedTrialsTable.Group);
        ylabel('Mean Pupil Size');
        title('Pupil Size by Speed and Group');
        legend('Healthy', 'CVA');

%HR vs speed by group:
    %line plot:
        figure;
        hold on;
        gscatter(groupedMeansRaw.SpeedCategory, groupedMeansRaw.means.MeanHeartRate, ...
            groupedMeansRaw.Group, 'br', 'ox')
        
        xlabel('Speed Category');
        ylabel('Mean Heart Rate');
        title('Heart Rate Across Speeds by Group');
        legend('Healthy', 'CVA');    
    
    %boxplot:
        figure;
        boxchart(categorical(rawSpeedTrialsTable.SpeedCategory), ...
                 rawSpeedTrialsTable.MeanHeartRate, ...
                 'GroupByColor', rawSpeedTrialsTable.Group);
        ylabel('Mean HR');
        title('Heart Rate by Speed and Group');
        legend('Healthy', 'CVA')    
        
%RR vs speed by group:
    %line plot:
        figure;
        hold on;
        gscatter(groupedMeansRaw.SpeedCategory, groupedMeansRaw.mean_RR, ...
            groupedMeansRaw.Group, 'br', 'ox')
        
        xlabel('Speed Category');
        ylabel('Mean Respiratory Rate');
        title('Respiratory Rate Across Speeds by Group');
        legend('Healthy', 'CVA');
   
    %boxplot:
        figure;
        boxchart(categorical(rawSpeedTrialsTable.SpeedCategory), ...
                 rawSpeedTrialsTable.RR, ...
                 'GroupByColor', rawSpeedTrialsTable.Group);
        ylabel('Mean Respiratory Rate');
        title('Respiratory Rate by Speed and Group');
        legend('Healthy', 'CVA');