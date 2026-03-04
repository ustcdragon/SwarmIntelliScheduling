%% %% author£ºXiangbo Qi and Xu ma
%% 20260131
%% shenyang university
function [machineTable,curJobTime,discretePostion]=sorting(machineTable,Position,jobNum,jobInfo,operaVec,...
    candidateMachine)
discretePostion=[];%%Discrete solution
%% Generate OS integer sequence
operaNum=sum(operaVec);
OS=[];
for i=1:jobNum
    OS=[OS,ones(1,operaVec(i))*i];
end
Position_OS=Position(1:operaNum);
Position_MS=Position(operaNum+1:2*operaNum);
[~,upIndex]=sort(Position_OS);
[~,osIndex]=sort(upIndex);
OS=OS(osIndex);                 % Convert decimal OS to integer OS commonly used in FJSP
discretePostion=[discretePostion OS];
%% Main loop: iterate over each chromosome
operaRec=zeros(1,jobNum);   % Record the current step of each job
curJobTime=zeros(1,jobNum);   % Record the end time of the previous operation of the current
for i=1:sum(operaVec)
    curJob=OS(i);
    operaRec(curJob)=operaRec(curJob)+1;
    jobOpera=operaRec(curJob);
    jobMsIndex=sum(operaVec(1:curJob-1))+jobOpera;  % Determine the position of the current operation of the current job in Position_MS
    decode_JobMsIndex=round(1/(2*jobNum)*(Position_MS(jobMsIndex)+jobNum)*(length(candidateMachine{...
        curJob,jobOpera})-1)+1);

    machine=candidateMachine{curJob,jobOpera}(decode_JobMsIndex);
    discretePostion=[discretePostion machine];
    %% Read the idle time slots of the machine
    for j=1:length(machineTable{machine})
        % Find idle time blocks
        if isequal(machineTable{machine}(j).job,0)
            %  Determine whether it can be inserted
            startT=max(machineTable{machine}(j).start,curJobTime(curJob));
            tmpJobInfo=jobInfo{curJob};
            tmpJobOperaArr=tmpJobInfo{jobOpera};
            endT=startT+tmpJobOperaArr(machine);
            % endT=startT+jobInfo{curJob}(jobOpera,machine);
            if endT<=machineTable{machine}(j).end           % Can be inserted
                insertion.start=startT;     % Start time of the inserted time block
                insertion.end=endT;         % End time of the inserted time block
                a=combination(insertion,machineTable{machine}(j),curJob,jobOpera);
                movement=length(a)-1;
                % Loop insertion: position j is the block to be inserted into the machineTable
                Len=length(machineTable{machine});
                % Move the original block
                if ~isequal(Len,j)
                    for m=Len:-1:j+1
                        machineTable{machine}(m+movement).start=machineTable{machine}(m).start;
                        machineTable{machine}(m+movement).end=machineTable{machine}(m).end;
                        machineTable{machine}(m+movement).job=machineTable{machine}(m).job;
                        machineTable{machine}(m+movement).opera=machineTable{machine}(m).opera;
                    end
                end
                % Insert the new block
                for m=1:length(a)
                    machineTable{machine}(j-1+m).start=a(m).start;
                    machineTable{machine}(j-1+m).end=a(m).end;
                    machineTable{machine}(j-1+m).job=a(m).job;
                    machineTable{machine}(j-1+m).opera=a(m).opera;
                end
                % Update curJobTime
                curJobTime(curJob)=endT;
                break;
            end
        end
    end

end
end

%%   Block reorganization
function [a]=combination(insertion,block,job,opera)
a=[];
if isequal(insertion.start,block.start)&&isequal(insertion.end,block.end)
    a.start=insertion.start;
    a.end=insertion.end;
    a.job=job;
    a.opera=opera;
elseif isequal(insertion.start,block.start)&&insertion.end<block.end
    a(1).start=insertion.start;
    a(1).end=insertion.end;
    a(1).job=job;
    a(1).opera=opera;
    a(2).start=insertion.end;
    a(2).end=block.end;
    a(2).job=0;
    a(2).opera=0;
elseif insertion.start>block.start&&isequal(insertion.end,block.end)
    a(1).start=block.start;
    a(1).end=insertion.start;
    a(1).job=0;
    a(1).opera=0;
    a(2).start=insertion.start;
    a(2).end=block.end;
    a(2).job=job;
    a(2).opera=opera;
elseif insertion.start>block.start&&insertion.end<block.end
    a(1).start=block.start;
    a(1).end=insertion.start;
    a(1).job=0;
    a(1).opera=0;
    a(2).start=insertion.start;
    a(2).end=insertion.end;
    a(2).job=job;
    a(2).opera=opera;
    a(3).start=insertion.end;
    a(3).end=block.end;
    a(3).job=0;
    a(3).opera=0;
end
end