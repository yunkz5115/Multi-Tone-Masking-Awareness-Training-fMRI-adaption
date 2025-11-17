%%
fprintf('Run configuration script.\n')
%%
global cfg
cfg.Fs          = 48000;                                                        % sampling freq
cfg.Nbits       = 32;                                                           % 32-bit precision
cfg.tnln        = 100;                                                          % individual tone length, in ms
cfg.l           = floor(cfg.Fs * (cfg.tnln/1000));                              % tone length in samples
cfg.t           = (1:cfg.l) ./ cfg.Fs;                                          % time vector for individual tones
cfg.W           = tukeywin(cfg.l, 20/cfg.tnln)';                                % 10 ms on- and off-ramps 

if length(cfg.W) ~= length(cfg.t)
    if length(cfg.W) > length(cfg.t)
        cfg.W(round(end/2)) = [];
    end
end

cfg.SOA         = 0.4;                                                          % 400 ms target-tone SOA, also defines window size
cfg.n_wndws     = 40;                                                           % how many 400-ms windows?
cfg.L           = floor(cfg.Fs * cfg.SOA * cfg.n_wndws);                        % overall trial stimulus length, in samples
%cfg.F           = round(logspace(log10(500), log10(3000), 25));                 % log frequency space between 239 and 2924 Hz
F_temp           = round(logspace(log10(200), log10(5000), 37));                 % log frequency space between 239 and 2924 Hz
cfg.F = F_temp(F_temp>=500&F_temp<=3000);
%% add jitter - see Gutschalk et al 2008
% Two frequency bands on either side of the target frequency were excluded,
% as a protected region,� such that the masker comprised the remaining 13
% frequency bands. Within each frequency band, the masker-tone frequency
% was chosen randomly around the center frequency (fc) within the width of
% one estimated equivalent rectangular bandwidths [ERB = 24.7 � (4.37 � f c
% + 1)], where fc is in kHz [1].

cfg.n_mskrs     = 5;                                                            % | # of possible maskers+Target Tones within a given time segment
cfg.istarget_window_index = [3,4,5,6];                                          % | which window to be selected including target
cfg.prtctdrgn   = 2;                                                            % | # of bands on either side of target in spectral protected region

%% add frequencies that to avoid fMRI noise
cfg.remove_F_list = [500,1000,4000];

%% Set Experiment Parameters
exp.trial_num_per_block = 36;

exp.normal_repeated = 1;
exp.catch_repeated = 1;

exp.block_num = 4;

exp.total_trial_num = exp.trial_num_per_block*exp.block_num;

exp.targ_f_list = [836,1196,1564];

exp.block_in_training = 30;
exp.force_block_num = 4;
exp.playduration_in_training = 4; % play 4 second in training session.
%% set key parameters

% Verify when set up on a new device!
% Here we used unify windows key code for testing.
KbName('UnifyKeyNames')
KbName('KeyNamesWindows');

key.escapeKey = KbName('ESCAPE');                                               % Escape key
key.yesKeys = KbName('RightArrow');                                             % Forward key
key.noKeys = KbName('LeftArrow');                                               % Back key
key.i1 = KbName('y');                                                           % Response type 1 in the experiment
key.i2 = KbName('n');                                                           % Response type 2 in the experiment
%key.MRI_trigger = 53;%KbName('5');                                             % MRI Trigger Key 5
key.MRI_trigger = KbName('T');                                                  % MRI Trigger Key T
key.SpaceKey = KbName('SPACE');                                                 % Space / Jump key
%% set screen index

% Skip sync test, 1 skip, 0 not skip.
if_skip_Screen_Sync_check = 1;
% Verify when set up on a new device!
screens = Screen('Screens');
screen_index = max(screens);
% screen_index = 0;

%% set sound card index

% Check sound card device
% Verify when set up on a new device!
% This will change on a different device
sound_card_index = 2; 

%% set scanner parameters

scanner.TR = 2;
scanner.TR_puluses_per_trial = cfg.SOA * cfg.n_wndws/scanner.TR;
scanner.TRs_to_be_wait_before_block = [5,5,5,5];
scanner.latency = 0.21;

if ~mod(scanner.TR_puluses_per_trial, 1) == 0
    warning('The length of trial is not an integer multiple of TR!');
    pause(1);
    warning('This can cause synchronization issues!');
    pause(1);
    warning('Change cfg.SOA and cfg.n_wndws to fix it!');
end
scanner.TR_puluses_per_trial = int64(scanner.TR_puluses_per_trial);

if length(scanner.TRs_to_be_wait_before_block) ~= exp.block_num
    error('TR wait parameter not match to the block number!');
end


exp.flipped_TR_index_list = [scanner.TR_puluses_per_trial,scanner.TR_puluses_per_trial-1,scanner.TR_puluses_per_trial-2];

exp.greenlight_TR_duration = 1; % Waiting for 1 TRs to turn green to red
exp.flip_green_TR_index_list = [3,4,5]; % TRs to flip the monitor to green

