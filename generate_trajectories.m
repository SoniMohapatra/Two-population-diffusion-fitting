%% Input parameters

%Input name of folder where you would like to store the mat files with trajectories 
foldername = inputdlg('Please enter output folder name:');
    mkdir(foldername{1})
    cd (foldername{1})
    
% User inputs variables
INT = 1;
ASK = 1;
if ASK == 1

        prompt = {'Cell length(\mum)',...
           'Cell radius(\mum)',...
           'Frame time (in sec)',...
           'Total number of trajectories',...
           'Length of trajectory',...
           'No. of microsteps in each frame',...
           'Localization error(\mum)',...
          'Min. D (\mum^2/s)',...
          'Max. D (\mum^2/s)',...
          'D spacing(\mum^2/s)'}; 
        u_name = 'Input parameters';
        numlines = 1;
        defaultanswer = {'3.5','0.41','0.03','5000','7','100','0.05','0.1','1','0.1'};
        options.Resize = 'on';
        options.WindowStyle = 'normal';
        options.Interpreter = 'tex';
        user_var = inputdlg(prompt,u_name,numlines,defaultanswer,options);
end

R = evalin('base',(user_var{2}));%Cell radius
Cyl_len = (evalin('base',(user_var{1}))-2*R)/2; %Half of cylinderlength; 
  N = evalin('base',(user_var{4}));%No. of trajectories
npoint =evalin('base',(user_var{5}));%Length of each trajectory
lag = evalin('base',(user_var{6}));% No. of microsteps in each frame

Loc_err = evalin('base',(user_var{7})); %Localization error
frame =evalin('base',(user_var{3}));% Exposure time of imaging
min_D = evalin('base',(user_var{8}));% minimum D for the simulation
max_D = evalin('base',(user_var{9}));% maximum D for simulation
bin_D = evalin('base',(user_var{10}));% increments in D
Diff = min_D:bin_D:max_D;
clear D

% parfor is used to reduce the time of computation
parfor dd = 1:size(Diff,2)
   
    m=matfile(sprintf('output%d.mat', dd),'writable',true)

    D(dd) = Diff(dd);
  
   Dfin=nan(npoint,N);
   Dfiny = nan(npoint,N);
num_particle = 0;
n = (npoint)*lag;
FinalX=nan(npoint,N);
FinalY=nan(npoint,N);
 FinalZ=nan(npoint,N);
t_micro = frame/lag;
D1 = D(dd)
all_disp=[];
micro_step = abs(sqrt(2*D1*t_micro));
 while num_particle <=N-1
    Xtemp=nan(1,n);% temp position store for checking geometric conditions
Ytemp=nan(1,n);%...
Ztemp=nan(1,n);%...
X=nan(1,n); % final position store
Y=nan(1,n); %...
Z=nan(1,n);
    start=2*(rand(1,3)-0.5);
    x_start = (Cyl_len+R)*2*start(1);
    y_start = R*2*start(2);
    z_start = R*2*start(3);
    if abs(x_start)<=Cyl_len && (y_start)^2+(z_start)^2 <(R^2)
        X(1)= x_start;
        Y(1)=y_start;
        Z(1)=z_start;
        num_particle = num_particle+1;
        traj_continue = 1;
    elseif abs(x_start)>=Cyl_len &&abs(x_start)<Cyl_len+R&& +(abs(x_start)-Cyl_len)^2+(y_start)^2+(z_start)^2 <(R^2)
        X(1)= x_start;
        Y(1)=y_start;
        Z(1)=z_start;
        traj_continue = 1;
        num_particle = num_particle+1;
    else traj_continue = 0;
    end
    
    if traj_continue == 1
        for step = 1:n-1
           step_move = randn(1,3);
        x_step = step_move(1)*micro_step;
        y_step = step_move(2)*micro_step;
        z_step =  step_move(3)*micro_step;
        Xtemp(step+1)=X(step)+x_step;
        Ytemp(step+1)=Y(step)+y_step;
        Ztemp(step+1)=Z(step)+z_step;
        if abs(Xtemp(step+1))<=Cyl_len&& (Ytemp(step+1))^2+(Ztemp(step+1))^2<(R^2)
            X(step+1)= Xtemp(step+1);
            Y(step+1)= Ytemp(step+1);
            Z(step+1)= Ztemp(step+1);
        elseif abs(Xtemp(step+1))>=Cyl_len&& abs(Xtemp(step+1))<Cyl_len+R && (abs(Xtemp(step+1))-Cyl_len)^2 +(Ytemp(step+1))^2+(Ztemp(step+1))^2<(R^2)
       
           X(step+1)= Xtemp(step+1);
            Y(step+1)= Ytemp(step+1);
            Z(step+1)= Ztemp(step+1);
        else X(step+1)= X(step);
             Y(step+1)= Y(step);
             Z(step+1)= Z(step);
        end
        
         
        end
        % Add localization errror to the centroid of microsteps to obtain
        % final position
       for c = 1:(n/lag)
       Dfin(c,num_particle) =mean(X(((c-1)*lag+1):((c)*lag)))+randn(1,1)*Loc_err;% x localizations
       Dfiny(c,num_particle)=mean(Y(((c-1)*lag+1):((c)*lag)))+randn(1,1)*Loc_err;% y localizations
  
       end

 
 
    end 
       
     
       
      
 end
 
 %The mat file contains x and y positions, Diffusion coefficent and
 %localization error. 
  m.Dfin = Dfin;%x localizations
   m.Dfiny = Dfiny;%y localizations
   m.D1 = D(dd);%Diffusion coefficient
   m.loc = Loc_err;%Localization error
end
clear