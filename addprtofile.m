%Select mat files where P(r) needs to be appended
[filename,filepath]=uigetfile('*.mat', ...
                               'MultiSelect','on');
cd(filepath);
INT = 1;
ASK = 1;
if ASK == 1
% The miminum P(r) is generally 0. The maximum P(r) should be same as that
% of experimental P(r). The bin size should also be same as that of
% experimental. Experimental and all simulated P(r) should have same number of
% bins. 
        prompt = {'Mimimum \it{r} (\mum)',...
           'Maximum \it{r} (\mum)',...
          'Bin size (\mum)'}; 
        u_name = 'Binning \it{r}';
        numlines = 1;
        defaultanswer = {'0','0.5','0.015'};
        options.Resize = 'on';
        options.WindowStyle = 'normal';
        options.Interpreter = 'tex';
        user_var = inputdlg(prompt,u_name,numlines,defaultanswer,options);
end

if iscell(filename)
    ntrials = size(filename,2);
    stackn = cell(1,ntrials);
    for i = 1:ntrials
        stackn{i} = filename{i};
    end

else
    ntrials = 1;
    stackn{1} = filename;
end
for ind = 1:ntrials
AA = [];
pr = [];
all_disp = [];
load(filename{ind})
% Calcualting single step displacement
for i = 1: size(Dfin, 2)
    for jj = 1:size(Dfin, 1)-1
disp(jj, i) = sqrt((Dfin(jj+1,i) - Dfin(jj, i))^2 + (Dfiny(jj+1,i) - Dfiny(jj, i))^2);
    end
end

% Collecting all displacement from all trajectories
for kk = 1:size(disp,2)
all_disp =vertcat( all_disp, disp(:,kk));
end

min_r = evalin('base',(user_var{1}));%Minimum r
max_r = evalin('base',(user_var{2}));%Maximum r
bin_r = evalin('base',(user_var{3}));%Binning in r
% Binning Displacements
AA = histc(all_disp,min_r:bin_r:max_r);
x_axis = min_r:bin_r:max_r; % x_axis for plotting data
pr = AA/sum(AA);%Normalize P(r)
save (filename{ind}, 'Dfin', 'Dfiny','pr','D1','AA','loc','all_disp')
end
clear