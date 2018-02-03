function []=fit_pr()
%Make sure the workspace already has unnormalized Experimental P(r) loaded
%in the name of "ribo_pr_n" in form of a column
%% Input parameters
INT = 1;
ASK = 1;
if ASK == 1

        prompt = {'No. of bins to be included in fitting',...
           'No. of fitted parameters'}; 
        u_name = 'Fitting parameters';
        numlines = 1;
        defaultanswer = {'130','1'};
        options.Resize = 'on';
        options.WindowStyle = 'normal';
        options.Interpreter = 'tex';
        user_var = inputdlg(prompt,u_name,numlines,defaultanswer,options);
end

bin=evalin('base',(user_var{1}));%No. of bins used in fitting (Please select the maximum number of bins until 
%which the bins are occupied and significant)
constraints=evalin('base',(user_var{2}));%No. of fitted parameters

% Select all mat files with P(r) in slow folder

[filename,filepath]=uigetfile('*.mat', ...
                               'MultiSelect','on');
cd(filepath);


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


% Select all mat files with P(r) in fast folder
[fast_filename,fast_filepath]=uigetfile('*.mat', ...
                               'MultiSelect','on');
cd(fast_filepath);


if iscell(fast_filename)
    fast_ntrials = size(fast_filename,2);
    fast_stackn = cell(1,fast_ntrials);
    for i = 1:fast_ntrials
        fast_stackn{i} = fast_filename;
    end

else
    fast_ntrials = 1;
    fast_stackn{1} = fast_filename;
end

All_pr=[];
    chi_sq_all = [];
   
slow_frac =0:0.05:1; %Range of slow fractions from 0% to 100% in increments of 5%
for ind = 1:ntrials
    slow_pr = [];
    cd(filepath);
    load(filename{ind})  

    slow_pr = pr;
    for ind_1 = 1:fast_ntrials
        cd(fast_filepath);
          fast_pr = [];
        load(fast_filename{ind_1})
        fast_pr = pr;
for i = 1:size(slow_frac,2)
  
All_pr_new(ind).kk(ind_1,i,:) = (slow_frac(i)*slow_pr + (1-slow_frac(i))*fast_pr); %This creates all combinations of P(r)


end
    end
end
exp_pr_n=evalin('base','exp_pr_n');
x_axis=evalin('base','x_axis');

exp_pr_total = sum(exp_pr_n);

exp_pr_t =exp_pr_n';
exp_pr = reshape(exp_pr_t,1,1,[]);
%Calculating chisquare
 for uu = 1:size(All_pr_new,2)
     for ll = 1:size(All_pr_new(uu).kk,1)
        for tt = 1:size(All_pr_new(uu).kk,2)
   All_pr(uu).kk(ll,tt,:)  =    All_pr_new(uu).kk(ll,tt,:) .* exp_pr_total;
chi_sq(uu).chi(ll,tt,1:bin) = ((All_pr(uu).kk(ll,tt,1:bin) -  exp_pr(1,1,1:bin)).^2)./exp_pr(1,1,1:bin);
        end
     end
 end
 All_chi_red = [];
 for u = 1:size(All_pr,2)
          for ml = 1:size(All_pr(u).kk,1)
             for yy = 1:size(All_pr(u).kk,2) 
    
    chi_sq(u).red_chi(ml,yy)= nansum(chi_sq(u).chi(ml,yy,1:bin))/(bin - constraints);%Reduced chi_sq
                      All_chi_red = vertcat(All_chi_red, chi_sq(u).red_chi(ml,yy));%Collecting all reduced chi_sq
% The total number of All_chi_red = (number of slow D x No. of fast D x Total no. of fractions)
             end

             end
 end

 % Finding the minimum chi_sq and corresponding 
 [min_chi_sq, idx] = min(All_chi_red);

first_D= rem(idx,u);
slow_frac_idx = rem(idx,yy);
left_over = fix(idx/yy);
slow_D_idx = fix(left_over/u)+1;

fast_D_idx = rem(left_over,u)+1;
best_fit_slow_frac = slow_frac(slow_frac_idx);
cd(filepath);
    load(filename{slow_D_idx})
best_fit_slow_D = D1;
slow_pr = pr;
cd(fast_filepath);
    load(fast_filename{fast_D_idx})
best_fit_fast_D = D1;
fast_pr = pr;
plot(x_axis, (best_fit_slow_frac*slow_pr + (1-best_fit_slow_frac)*fast_pr)*exp_pr_total );
hold on
plot(x_axis, exp_pr_n);
assignin('base','slow_D',best_fit_slow_D)
assignin('base','fast_D',best_fit_fast_D)
assignin('base','slow_frac',best_fit_slow_frac)
assignin('base','minimum_chi_sq',min_chi_sq)
