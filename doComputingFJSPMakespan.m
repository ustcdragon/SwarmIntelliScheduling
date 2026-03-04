%% author：Xiangbo Qi and Xu ma
%% 20260131
%% shenyang university
%%Calculate the objective function of FJSP；
function [makespan,curJobTime,machineTable,discretePostion]=doComputingFJSPMakespan(Position,machineNum,jobNum,jobInfo,operaVec,...
    candidateMachine)
%% machineTable Record the work schedule for each machine
% Create a structure workTable
workTable=[];
workTable.start=0;
workTable.end=Inf;
workTable.job=0;  % 0 Indicate idle
workTable.opera=0;
% Initialize machineTable
for i=1:machineNum
    machineTable{1,i}=workTable;
end
%% Decode and sort
[machineTable,curJobTime,discretePostion]=sorting(machineTable,Position,jobNum,jobInfo,operaVec,candidateMachine);
makespan=max(curJobTime);
end