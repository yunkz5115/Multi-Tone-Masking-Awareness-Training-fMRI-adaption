function [tar_freq_list,catch_index_list,Green_light_TR_index_list,Next_trial_TR_index_list] = mtm_layer_fMRI_trial_organizer(exp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trial organizer per block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
norm_repeat_time = exp.normal_repeated;
catch_repeat_time = exp.catch_repeated;
% Align variable type
exp.targ_f_list = double(exp.targ_f_list);
exp.flipped_TR_index_list = double(exp.flipped_TR_index_list);
exp.flip_green_TR_index_list = double(exp.flip_green_TR_index_list);

% Check length (comment later)
normal_length = length(exp.targ_f_list)*length(exp.flipped_TR_index_list)*length(exp.flip_green_TR_index_list);
catch_length = length(exp.flipped_TR_index_list)*length(exp.flip_green_TR_index_list);

% Generate 3*conditions matrix for normal trial and catch trial seperately
% Normal trial
cond2_list = [];
cond3_list = [];

cond1_list = exp.targ_f_list;
for i = 1:length(exp.flip_green_TR_index_list)
    cond2_list = [cond2_list,[cond1_list;exp.flipped_TR_index_list(i)*ones(1,size(cond1_list,2))]];
end
for i = 1:length(exp.flipped_TR_index_list)
    cond3_list = [cond3_list,[cond2_list;exp.flip_green_TR_index_list(i)*ones(1,size(cond2_list,2))]];
end
full_cond_list = [];
for i = 1:norm_repeat_time
    full_cond_list = [full_cond_list,cond3_list];
end
normal_trial_matrix = [full_cond_list;ones(1,size(full_cond_list,2))];

% Catch trial
cond2_list = [];
cond3_list = [];

cond1_list = nan;
for i = 1:length(exp.flip_green_TR_index_list)
    cond2_list = [cond2_list,[cond1_list;exp.flipped_TR_index_list(i)*ones(1,size(cond1_list,2))]];
end
for i = 1:length(exp.flipped_TR_index_list)
    cond3_list = [cond3_list,[cond2_list;exp.flip_green_TR_index_list(i)*ones(1,size(cond2_list,2))]];
end
full_cond_list = [];
for i = 1:catch_repeat_time
    full_cond_list = [full_cond_list,cond3_list];
end
catch_trial_matrix = [full_cond_list;zeros(1,size(full_cond_list,2))];

% Combine two matrix
all_trial_matrix = [normal_trial_matrix,catch_trial_matrix];
% Shuffle matrix
shuffle_index = randperm(size(all_trial_matrix,2));
all_trial_matrix = all_trial_matrix(:,shuffle_index);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exp.trial_num_per_block~=size(all_trial_matrix,2)
    warning('Exp trial num and generated index trail num not matched. Result might be cutoff.');
end
tar_freq_list = all_trial_matrix(1,:);
Next_trial_TR_index_list = all_trial_matrix(2,:);
Green_light_TR_index_list = all_trial_matrix(3,:);
catch_index_list = all_trial_matrix(4,:);
end

