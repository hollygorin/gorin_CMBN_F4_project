data=readtable("Data11-8.csv")
healthy= data.Group == "H"
CVA=data.Group == "CVA"
slow=data.SpeedCategory == "S"
moderate=data.SpeedCategory == "M"
fast=data.SpeedCategory == "F"
withDistractors=data.Distractor == "Y"
withoutDistractors=data.Distractor == "N"
onBB=data.BetaBlocker == "Y"
notOnBB=data.BetaBlocker == "N"
slow_Dist=data.Condition == "five"
slow_NoDist=data.Condition == "four"
fast_Dist=data.Condition == "seven"
fast_noDist=data.Condition == "six"
baseline=data.Condition == "one"

%making tables for each group
healthyTable=data(healthy,:)
CVATable=data(CVA,:)
slowAllTable=data(slow,:)
fastAllTable=data(fast,:)
moderateTable=data(moderate,:)
slow_DistTable=data(slow_Dist,:)
slow_NoDistTable=data(slow_NoDist,:)
fast_DistTable=data(fast_Dist,:)
fast_noDistTable=data(fast_noDist,:)
baselineTable=data(baseline,:)

%figure out how to make tables for separate DVs when group sizes are
%unequal
%pupil=[baselineTable.Pupil slow_NoDistTable.Pupil slow_DistTable.Pupil  moderateTable.Pupil, fast_NoDistTable.Pupil fast_DistTable.Pupil slowAllTable.Pupil fastAllTable.Pupil]