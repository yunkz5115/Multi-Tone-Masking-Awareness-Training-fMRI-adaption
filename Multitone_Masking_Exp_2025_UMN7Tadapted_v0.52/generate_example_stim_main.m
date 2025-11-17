%%
clc;
clear;
close all;
%%
% Generate example stim
% To change the configration, including exclusion freq to avoid fMRI noise, chance from setting_main
MRI_exp_settings_main

masked_file_name = 'sound_demo_masked_target.wav';
pure_file_name = 'sound_demo_masked_pure.wav';
target_freq = 1196;

% Input parameters: 
% [1] cfg, configuration parameter
% [2] target freq, 1196Hz here as an example
% [3] if generate no target stim. If [3] is 1, keep [4] and [5] as 0.
% [4] if generate mask + target stim
% [5] if generate pure target stim
[sig_mask,sig_targ,sig_log,freq,trial_type] = prepare_stim_for_layer_fMRI(cfg,target_freq,0,1,1);

% write stim (mono) sample freq = 48000
audiowrite(masked_file_name,sig_mask(:,1),cfg.Fs);
audiowrite(pure_file_name,sig_targ(:,1),cfg.Fs);
