function [Green_light_TR_index_list,Next_trial_TR_index_list] = generate_green_flip_and_TR_to_next_trial_index(exp)

%Randomize green flip TR in each trial
Next_trial_TR_index_list = zeros(1,exp.trial_num_per_block);
Green_light_TR_index_list = zeros(1,exp.trial_num_per_block);

for i = 1:exp.trial_num_per_block
    Green_light_TR_index_list(i) = exp.flip_green_TR_index_list(randi(length(exp.flip_green_TR_index_list)));
    Next_trial_TR_index_list(i) = exp.flipped_TR_index_list(randi(length(exp.flipped_TR_index_list)));
end

end

