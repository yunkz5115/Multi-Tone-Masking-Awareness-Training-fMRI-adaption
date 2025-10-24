function [tar_freq_list,catch_index_list] = generate_target_catch_index(num_trail_per_block,tar_freq,catch_rate)

%in catch index list, 1 represent catch trail, and 0 is non-catch

tar_freq_index_small = 1:length(tar_freq);
len_catch = floor(num_trail_per_block/length(tar_freq)*catch_rate);
len_normal = ceil(num_trail_per_block/length(tar_freq)-len_catch);

catch_freq_index = repmat(tar_freq_index_small, 1, len_catch);
catch_index = repmat(ones(length(tar_freq),1), 1, len_catch);
normal_freq_index = repmat(tar_freq_index_small, 1, len_normal);
normal_index = repmat(zeros(length(tar_freq),1), 1, len_normal);

tar_freq_list = [catch_freq_index,normal_freq_index];
catch_index_list = [catch_index,normal_index];

if length(tar_freq_list)<num_trail_per_block
    tar_freq_list = [tar_freq_list,randi(length(tar_freq), 1, num_trail_per_block-length(tar_freq_list))];
    catch_index_list = [catch_index_list,zeros(num_trail_per_block-length(tar_freq_list),1)];
elseif length(tar_freq_list)>num_trail_per_block
    tar_freq_list(num_trail_per_block+1:end) = [];
    catch_index_list(num_trail_per_block+1:end) = [];
end

shuffle_index = randperm(length(tar_freq_list));
tar_freq_list = tar_freq_list(shuffle_index);
catch_index_list = catch_index_list(shuffle_index);

for i = 1:length(tar_freq)
    tar_freq_list(tar_freq_list==i) = tar_freq(i);
end

end

