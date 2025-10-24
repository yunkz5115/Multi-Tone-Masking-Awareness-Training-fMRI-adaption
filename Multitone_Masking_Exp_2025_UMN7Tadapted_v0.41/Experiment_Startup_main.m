clc;
clear;
close all;
%%
fprintf('Please type in the index (1 or 2) to choose the experiment:\n');
fprintf(['    1 MTM Awarness Training / Practice Experiment\n',...
         '    2 UMN 7T MRI Adapted MTM Experiment.\n',...
         '    0 Exit.']);
%%
while 1
    exp_index = input('Please enter experiment index: ', 's');
    if strcmp('1',exp_index)
        Layer_fMRI_MultitoneMasker_Awerness_Training
        break
    elseif strcmp('2',exp_index)
        Layer_fMRI_MultitoneMasker_Experiment_main
        break
    elseif strcmp('0',exp_index)
        break
    end
end

ListenChar(1);

