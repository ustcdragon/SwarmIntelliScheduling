%% GPSO
%% author：Xiangbo Qi and Xu ma
%% 20260131
%% shenyang university
function [GlobalMins,GlobalSolution] = FJSP_PSO(ProblemStruct)
n=ProblemStruct.popSize;
maxEvaluation=ProblemStruct.Maxeva;
jobNum=ProblemStruct.iJobs;
jobInfo=ProblemStruct.jobInfo;
machineNum=ProblemStruct.iEQs;
operaVec=ProblemStruct.operaNumVec;
candidateMachine=ProblemStruct.candidateMachine;
C1=2;
C2=2;
Ud=jobNum;                  % Upper bound of independent variable
Ld=-jobNum;                 %  Lower bound of independent variable
Dim=2*sum(operaVec);
Vmax=0.1*Ud;
Vmin=0.1*Ld;
w_start=0.9;
w_end=0.7;
runtime=ProblemStruct.Run;
GlobalMins=ones(runtime,maxEvaluation);  %%Record the change in minimum value with the number of evaluations for each run
GlobalSolution=zeros(runtime,Dim);
for r=1:runtime
    evaluation=0;     %%Reset evaluation count to zero
    evaluationNow=0;  %%Record the evaluation count after assessment
    gen=1;
    initPop=Ld+(Ud-Ld)*rand(n,Dim);   %% Initialize positions
    V=Vmin+(Vmax-Vmin)*rand(n,Dim);   %%Initialize velocities
    P=initPop;                        %%Record the personal historical best of each individual
    PSeq=P;%%Record the personal historical best discrete solution of each individual
    
    Fit=zeros(n,1);
    for i=1:n
         [ objVal,~,~,discretePosition]=doComputingFJSPMakespan(initPop(i,:),machineNum,jobNum,jobInfo,operaVec,candidateMachine);
        Fit(i,:)=objVal;
        PSeq(i,:)=discretePosition;
    end
    evaluationNow=evaluationNow+n;    %%Update evaluation count
    [Fmin,index]=min(Fit);            %% Global best, single individual
    Pg=initPop(index,:);              %%Global best solution
    PgSeq=PSeq(index,:);%%Global best discrete solution
    GlobalMins(r,evaluation+1:evaluationNow)=Fmin;
    evaluation=evaluationNow;         %%Record the minimum value
    iter=1;

    while (evaluation < maxEvaluation)   %%Evaluation count not met
        w=w_start-(w_start-w_end)*evaluation/maxEvaluation;   %%Linearly decreasing
        for i=1:n                        
            V(i,:)=w*V(i,:)+C1*rand()*(P(i,:)-initPop(i,:))+C2*rand()*(Pg-initPop(i,:));
            V(i,:)=min(V(i,:),Vmax);             %%For those exceeding the upper bound, set to the upper bound
            V(i,:)=max(V(i,:),Vmin);

            initPop(i,:)=initPop(i,:)+V(i,:);     %%Update positions
            initPop(i,:)=min(initPop(i,:),Ud);
            initPop(i,:)=max(initPop(i,:),Ld);
        end
        tempFit=zeros(n,1);
        tempPop=zeros(n,Dim);
        for i=1:n           
            [ objVal,~,~,discretePosition]= doComputingFJSPMakespan(initPop(i,:),machineNum,jobNum,jobInfo,operaVec,candidateMachine);
            tempFit(i,:)=objVal;
            tempPop(i,:)=discretePosition;
        end

        evaluationNow=evaluationNow+n;
        for i=1:n
            if(tempFit(i)<Fit(i))           %%Determine whether to update individual best
                P(i,:)=initPop(i,:);
                Fit(i)=tempFit(i);
                PSeq(i,:)=tempPop(i,:);
            end
        end

        [tempFmin,tempindex]=min(tempFit);   %%Determine whether to update global best
        if(tempFmin<Fmin)
            Pg=initPop(tempindex,:);
            Fmin=tempFmin;
            PgSeq=PSeq(tempindex,:);
        end
        
        if(evaluationNow<maxEvaluation)     %%Record the trajectory of the minimum value
            GlobalMins(r,evaluation+1:evaluationNow)=Fmin;
            evaluation=evaluationNow;
        else
           GlobalMins(r,evaluation+1:maxEvaluation)=Fmin;
           break;
        end
        GlobalIterations(r,iter)=Fmin;
        GlobalSolution(r,:)=PgSeq;
        iter=iter+1;
    end  %% end of PSO
    
    fprintf('runs=%d ObjVal=%g\n',r,Fmin);
    
end  %% end of run
%%Data processing
tmpArr=[];
for i=1:runtime
    tmp=GlobalIterations(i,:);
    tmpInd=find(tmp==0);
    if(isempty(tmpInd))
        tmpArr(end+1)=length(GlobalIterations(1,:));
    else
        tmpArr(end+1)=tmpInd(1);
        GlobalIterations(i,tmpInd(1):end)=GlobalIterations(i,tmpInd(1)-1);
    end
end
[minVal,minInd]=min(tmpArr);
end


