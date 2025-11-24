%clc;
%clear
%close all
%% set basic stim parameters
Training_exp_settings_main

%% initialize experiment_log
ListenChar(1);
export_log_path = 'Practice_Result\';

participant_log.ID = input('\n Please enter participant''s ID: ', 's');

participant_log.name = [participant_log.ID,'_DateTime-',char(datetime('now', 'Format', 'yyyyMMdd-HHmm'))];
participant_log.scan_date = datestr(now);
participant_log.exp = exp;
participant_log.cfg = cfg;
participant_log.scanner = scanner;
participant_log.key = key;

participant_log.result = struct(...
    'trial',cell(exp.total_trial_num,1),...
    'reaction',cell(exp.total_trial_num,1),...
    'trial_type',cell(exp.total_trial_num,1),...
    'reaction_time',cell(exp.total_trial_num,1),...
    'targ_frequency',cell(exp.total_trial_num,1),...
    'block_num',cell(exp.total_trial_num,1),...
    'start_TR',cell(exp.total_trial_num,1),...
    'green_light_TR',cell(exp.total_trial_num,1),...
    'green_light_TR_at_which_sub_TR',cell(exp.total_trial_num,1));

estimated_TR_num = sum(scanner.TRs_to_be_wait_before_block*2+1) + exp.total_trial_num*scanner.TR_puluses_per_trial + 100; % Add 100 pulses redundancy

participant_log.timestamp_log = struct(...
    'System_Time',cell(estimated_TR_num*6,1),...
    'TR',cell(estimated_TR_num*6,1),...
    'green_flip',cell(estimated_TR_num*6,1),...
    'red_flip',cell(estimated_TR_num*6,1),...
    'Response',cell(estimated_TR_num*6,1),...
    'tone_time_freq',cell(estimated_TR_num*6,1),...
    'trial_type',cell(estimated_TR_num*6,1),...
    'tar_freq',cell(estimated_TR_num*6,1),...
    'esc_attempt',cell(estimated_TR_num*6,1),...
    'Block_num',cell(estimated_TR_num*6,1));

% scan envent 
% row 1: TR index; 
% row 2: TR time; 
% row 3: TR type; 
% row 4: which TR within a trial.
% row 5: 0 nothing, 1 sound onset, 2 flip green
% 
% For TR type (row 3), 
% 1: normal trial TR; 
% 0: sync TR before block start, or TRs in waiting
participant_log.scan_event = zeros(5,estimated_TR_num); 



%% Set up devices
close all;
ListenChar(2);

% Skip Screen Sync (or not)
Screen('Preference', 'SkipSyncTests', if_skip_Screen_Sync_check);

%--------------------------------------------------------------------------
%                       Sound device setup
%--------------------------------------------------------------------------

% Initialize Sounddriver
InitializePsychSound(1);

% Number of channels and Frequency of the sound
nrchannels = 2;
freq = cfg.Fs;

% How many times to we wish to play the sound
repetitions = 1;

% Length of the beep
beepLengthSecs = 1;

% Length of the pause between beeps
beepPauseTime = 2;

% Length of the jitter fixer before beeps
JitterFixTime1 = 0.6;
JitterFixTime2 = 0.2;

% Length of the accessment result after decision
AccessmentResultTime = 1;

% Start immediately (0 = immediately)
startCue = 0;

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 0;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
devices = PsychPortAudio('GetDevices');
PsychPortAudio('Close');
pahandle = PsychPortAudio('Open', sound_card_index, 1, 2, freq, nrchannels);
%pahandle = PsychPortAudio('Open', 18, 1, 2, freq, nrchannels);

% Set the volume to half for this demo
PsychPortAudio('Volume', pahandle, 0.5);

% Make a beep which we will play back to the user
[sig_mask,~,~,~,~] = prepare_stim_for_layer_fMRI_tono_adapted(cfg,1000,0,1,0,nan,scanner);
trigger_f = 1000;
myBeep = sig_mask';
coswin = cos(2*pi*trigger_f*(0:(1/length(myBeep(1,:))):(1-1/length(myBeep(1,:)))));
myBeep(2,:) = coswin;
% Fill the audio playback buffer with the audio data, doubled for stereo
% presentation
PsychPortAudio('FillBuffer', pahandle, myBeep);


%--------------------------------------------------------------------------
%                       Keyboard information
%--------------------------------------------------------------------------

% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key

% Initialize key code frame
KbName('UnifyKeyNames')
KbName('KeyNamesWindows');
escapeKey = key.escapeKey;
yesKeys = key.yesKeys;
noKeys = key.noKeys;
i1 = key.i1;
i2 = key.i2;
SpaceKey = key.SpaceKey;
mri_trigger = key.MRI_trigger;
%RestrictKeysForKbCheck([KbName('y'),KbName('n'),KbName('escape'),KbName('space')]);

%--------------------------------------------------------------------------
%                       Screen Set up
%--------------------------------------------------------------------------

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Select the external screen if it is present, else revert to the native
% screen
% screenNumber = 2;
screenNumber = screen_index;


% Define black, white and grey
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
%black = BlackIndex(1);
%white = WhiteIndex(1);
grey = white / 2;

% Open an on screen window and color it grey
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the on screen window in pixels
% For help see: Screen WindowSize?
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);
ifi = ifi*144/143.198;%Add a frame fixer because the stupid AW laptop monitor
fprintf(['frame duration = ',num2str(ifi),'\n']);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Set the text size
Screen('TextSize', window, 70);

% Calculate how long the beep and pause are in frames
beepLengthFrames = round(length(myBeep)/freq / ifi);
beepPauseLengthFrames = round(beepPauseTime / ifi);
JitterFixerLengthFrames1 = round(JitterFixTime1 / ifi);
JitterFixerLengthFrames = round(JitterFixTime2 / ifi);
AccessmentResultLengthFrames = round(AccessmentResultTime / ifi);


% Now we draw our sequence of silence and beeps. You could obviously put
% this in a loop, but we will just do everything sequentially code-wise to
% show what is going on

%%
% try
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Introduction start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

keyC = nan;
clear keyIsDown secs keyCode
exit_code = 0;
Screen('TextSize', window, 35);

for i = 1:beepPauseLengthFrames*20
    
    Screen('TextSize', window, 30);

    text1 = [...
         'Welcome\n\n', ...
         'In this experiment, \n' ...
         'you will hear sequences of random tones that sometimes include \n' ...
         'a regular "target-tone" sequence. \n\n' ...
         'As the sound plays, \n' ...
         'a ''+'' symbol will appear in the center of the screen. \n' ...
         'When the ''+'' symbol appears, please keep your eyes on it.\n\n' ...
         'Press the right arrow key to continue.'];

    % Draw text
    DrawFormattedText(window, text1, 'center', 'center', [1 1 1]);

    % Flip to the screen
    Screen('Flip', window);
    
    FlushEvents();
    [keyIsDown,~,keyCode] = KbCheck;
    if keyCode(yesKeys)
        clear keyIsDown secs keyCode ch
        FlushEvents();
        break
    elseif keyCode(escapeKey)
        % Close the audio device
        ListenChar(1);
        FlushEvents();
        ShowCursor;
        PsychPortAudio('Close', pahandle);
        PsychPortAudio('Close');
        % Clear up and leave the building
        sca
        exit_code = 1;
        break
    end
    KbReleaseWait;

end
clear keyIsDown secs keyCode

if ~exit_code
    text1 = ['Training: You will first hear a "cloud" of distractor tones that also includes a "target-tone" sequence.\n' ...
             'followed by the target-tone sequence by itself,\n' ...
             'and finally the same "cloud" tones as before.\n' ... 
             '\n It is usually difficult to hear the target-tone sequence the first time you hear the "cloud",' ...
             '\n but it is usually easier to hear it the second time.' ...
             '\n\n Please focus on the "+" whenever it appears \n' ...
             '\n Press the right arrow key to begin.'];
    
    % Draw text
    DrawFormattedText(window, text1, 'center', 'center', [1 1 1]);
    % Flip to the screen
    Screen('Flip', window);
    pause(0.2)
    
    for i = 1:beepPauseLengthFrames*20
        
        Screen('TextSize', window, 35);
    
        % Draw text
        DrawFormattedText(window, text1, 'center', 'center', [1 1 1]);
    
        % Flip to the screen
        Screen('Flip', window);
        
        FlushEvents();
        [keyIsDown,~,keyCode] = KbCheck;
        if keyCode(yesKeys)
            clear keyIsDown secs keyCode
            break
        elseif keyCode(escapeKey)
            % Close the audio device
            ListenChar(1);
            FlushEvents();
            ShowCursor;
            PsychPortAudio('Close', pahandle);
            PsychPortAudio('Close');
            % Clear up and leave the building
            sca
            exit_code = 1;
            break
        end
        KbReleaseWait;
    
    end
end
ListenChar(2);
fprintf('Training Session Started.\n');
ifcontinue = true;
response = 0;

% Press a buttun to skip training and jump to experiment.
jump_to_experiment = 0;
training_trail_count = 0;
force_trail_num = exp.force_block_num * length(exp.targ_f_list);
clear keyIsDown secs keyCode
freq_index_list = [];
for i = 1:exp.block_in_training
    freq_index_list = [freq_index_list,randperm(length(exp.targ_f_list))];
end
for block_training_count = 1:length(freq_index_list)
    training_trail_count = training_trail_count +  1;
    if ~exit_code
        ifcontinue = true;
        %load target / mask sound
        [sig_mask,sig_targ,sig_log,~,~] = prepare_stim_for_layer_fMRI_tono_adapted(cfg,exp.targ_f_list(freq_index_list(block_training_count)),0,1,1,nan,scanner);
        % If a certain target frequency will be forced to play multiple times, change the number of loops 
        ifcontinue = true;
        while (ifcontinue == true)&&(~exit_code)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Play mask
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            myBeep = sig_mask';
            PsychPortAudio('FillBuffer', pahandle, myBeep);
            Screen('TextSize', window, 70);
            %---------------------------------------------------------------------%
            for i = 1:JitterFixerLengthFrames

                % Draw text
                DrawFormattedText(window, '+', 'center', 'center', [1 1 1]);

                % Flip to the screen
                Screen('Flip', window);

            end
            %---------------------------------------------------------------------%
            % Start audio playback #1

            PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
            pause(exp.playduration_in_training)
            %---------------------------------------------------------------------%
            %Stop audio playback
            PsychPortAudio('Stop', pahandle);
            %---------------------------------------------------------------------%
            %Show jitter fixer after sound
            for i = 1:JitterFixerLengthFrames

                % Draw text
                DrawFormattedText(window, '+', 'center', 'center', [1 1 1]);

                % Flip to the screen
                Screen('Flip', window);

            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Play target
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            myBeep = sig_targ';
            PsychPortAudio('FillBuffer', pahandle, myBeep);
            Screen('TextSize', window, 70);
            %---------------------------------------------------------------------%
            for i = 1:JitterFixerLengthFrames

                % Draw text
                DrawFormattedText(window, '+', 'center', 'center', [1 1 1]);

                % Flip to the screen
                Screen('Flip', window);

            end
            %---------------------------------------------------------------------%
            % Start audio playback #1

            PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
            pause(exp.playduration_in_training)
            %---------------------------------------------------------------------%
            %Stop audio playback
            PsychPortAudio('Stop', pahandle);
            %---------------------------------------------------------------------%
            %Show jitter fixer after sound
            for i = 1:JitterFixerLengthFrames

                % Draw text
                DrawFormattedText(window, '+', 'center', 'center', [1 1 1]);

                % Flip to the screen
                Screen('Flip', window);

            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Play mask
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            myBeep = sig_mask';
            PsychPortAudio('FillBuffer', pahandle, myBeep);
            %---------------------------------------------------------------------%
            for i = 1:JitterFixerLengthFrames

                % Draw text
                DrawFormattedText(window, '+', 'center', 'center', [1 1 1]);

                % Flip to the screen
                Screen('Flip', window);

            end
            %---------------------------------------------------------------------%
            % Start audio playback #1

            PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
            pause(exp.playduration_in_training)
            %---------------------------------------------------------------------%
            %Stop audio playback
            PsychPortAudio('Stop', pahandle);
            %---------------------------------------------------------------------%
            %Show jitter fixer after sound
            for i = 1:JitterFixerLengthFrames

                % Draw text
                DrawFormattedText(window, '+', 'center', 'center', [1 1 1]);

                % Flip to the screen
                Screen('Flip', window);

            end

        respToBeMade = true;
        response = 0;
            while respToBeMade == true

                Screen('TextSize', window, 35);
                if (training_trail_count<force_trail_num)
                    text1 = ['To hear the last example again, press the' ... 
                             ' left arrow key. \n\n', ...
                             'To hear the next example, press the right' ...
                             ' arrow key.'];
                else
                    text1 = ['To hear the last example again, press the' ... 
                             ' left arrow key. \n\n', ...
                             'To hear the next example, press the right' ...
                             ' arrow key.\n\n'...
                             'To skip the training and jump to the experiment, press ''SPACE''.'];
                end

                % Draw text
                DrawFormattedText(window, text1, 'center', 'center', [1 1 1]);
                % Flip to the screen
                Screen('Flip', window);

                FlushEvents();
                [keyIsDown,~,keyCode] = KbCheck;
                if keyCode(yesKeys)
                    clear keyIsDown secs keyCode ch
                    FlushEvents();
                    respToBeMade = false;
                    ifcontinue = false;
                elseif keyCode(noKeys)
                    clear keyIsDown secs keyCode ch
                    FlushEvents();
                    respToBeMade = false;
                    continue
                elseif keyCode(escapeKey)
                    % Close the audio device
                    ListenChar(1);
                    FlushEvents();
                    ShowCursor;
                    PsychPortAudio('Close', pahandle);
                    PsychPortAudio('Close');
                    % Clear up and leave the building
                    sca
                    close all
                    exit_code = 1;
                    break
                elseif keyCode(SpaceKey) && (training_trail_count>=force_trail_num)
                    jump_to_experiment = 1;
                    break
                end
                KbReleaseWait;
                clear keyIsDown secs keyCode

            end
            if exit_code
                break
            end
            if jump_to_experiment
                break
            end
        end
        if exit_code
            break
        end
        if jump_to_experiment
            break
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Practice Start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exit_code
    ListenChar(2);
    fprintf('Assessment Session Started.\n');
    clear keyIsDown secs keyCode
    %Screen('TextSize', window, 35);
    text1 = ['Please read the text below carefully. \n\n' ...
             'Please be as still as possible, keep your eyes on the \n' ...
             'red ''+'', and listen for the target-tone sequences \n' ...
             'within the "clouds". \n\n'...
             'When the red ''+'' turns green, press "Y" if you heard \n' ...
             'the target tones or "N" if you didn''t.\n\n '...
             'Please do not move until the green ''+'' appears, and \n' ...
             'when it does, respond as quickly as possible.\n\n' ...
             'Press the right arrow key to begin.'];
    % Draw text
    DrawFormattedText(window, text1, 'center', 'center', [1 1 1]);
    % Flip to the screen
    Screen('Flip', window);
    pause(0.2)
    
    for i = 1:beepPauseLengthFrames*20
        
        Screen('TextSize', window, 35);
        % Draw text
        DrawFormattedText(window, text1, 'center', 'center', [1 1 1]);
    
        % Flip to the screen
        Screen('Flip', window);
        
        
        FlushEvents();
        [keyIsDown,~,keyCode] = KbCheck;
        if keyCode(yesKeys)
            clear keyIsDown secs keyCode ch
            FlushEvents();
            break
        elseif keyCode(escapeKey)
            % Close the audio device
            ListenChar(1);
            FlushEvents();
            ShowCursor;
            PsychPortAudio('Close', pahandle);
            PsychPortAudio('Close');
            % Clear up and leave the building
            sca
            close all
            exit_code = 1;
            break
        end
        KbReleaseWait;
    end
end
%% 
% Initialize trial
ifcontinue = true;
response = 0;
clear keyIsDown secs keyCode
participant_log_trial_count = 0;
timestemp_event_count = 0;

% Initialize event cache
event_code_cache = zeros(3,length(fieldnames(key)));
event_time_cache = [0,0,0];
Total_TR_count = 0;
escape_press_count = 0;
time_start = GetSecs();
if_green_light = 0;

for block_count = 1:exp.block_num
    if ~exit_code
        Wait_TR_text = '\nWaiting for the block to start and Scanner to be synchronized\n';
        TR_sub_count = 0;
        TR_wait_count = 0;
        pre_fill_count = 0;
        if_green_light = 0;
        [tar_freq_list,catch_index_list,Green_light_TR_index_list,Next_trial_TR_index_list] = mtm_layer_fMRI_trial_organizer(exp);
        jump_in_jitter_count = 0;
        while ~exit_code

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Acquire event in real time
            clear keyIsDown keyTime keyCode;
            [keyIsDown,keyTime,keyCode] = KbCheck;
            
            event_code_cache(3,:) = event_code_cache(3,:);
            event_code_cache(2,:) = event_code_cache(1,:);
            real_time_event = find(keyCode);
            if ~isempty(real_time_event)
                event_code_cache(1,1:length(real_time_event)) = real_time_event;
            else
                event_code_cache(1,:) = 0;
            end
            
            event_time_cache(3) = event_time_cache(2);
            event_time_cache(2) = event_time_cache(1);
            event_time_cache(1) = keyTime;

            %%%%%%%%%%%%%%%%%%%%%%%%%
            % Check if escape
            % Press 'esc' two times in a row can escape the experiment.
            if keyCode(key.escapeKey)
                KbReleaseWait;
                escape_press_count = escape_press_count + 1;
                fprintf('\nPress ESC again to exit the experiment.\n');
                %record event
                timestemp_event_count = timestemp_event_count + 1;
                participant_log.timestamp_log(timestemp_event_count).esc_attempt = 1;
                participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                participant_log.timestamp_log(timestemp_event_count).Block_num = block_count;

                if escape_press_count>1
                    ListenChar(1);
                    FlushEvents();
                    ShowCursor;
                    PsychPortAudio('Close', pahandle);
                    PsychPortAudio('Close');
                    % Clear up and leave the building
                    sca
                    close all
                    exit_code = 1;
                    break
                end
            elseif (keyCode(key.MRI_trigger))||(keyCode(key.i1))||(keyCode(key.i2))
                escape_press_count = 0;
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%
            % Check event: TR or participant input

            if (sum(event_code_cache(1,:)==key.MRI_trigger)>0)&&(sum(event_code_cache(2,:)==key.MRI_trigger)==0)&&(sum(event_code_cache(3,:)==key.MRI_trigger)==0)
                % If TR was recorded
                Total_TR_count = Total_TR_count + 1;
                TR_wait_count = TR_wait_count + 1;
                % Record event
                timestemp_event_count = timestemp_event_count + 1;
                participant_log.timestamp_log(timestemp_event_count).TR = Total_TR_count;
                participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                participant_log.timestamp_log(timestemp_event_count).Block_num = block_count;
                
                if TR_wait_count<scanner.TRs_to_be_wait_before_block(block_count)
                    Screen('TextSize', window, 70);
                    DrawFormattedText(window, '+', 'center', 'center', [1 0 0]);
                    Screen('Flip', window);
                elseif TR_wait_count == (scanner.TRs_to_be_wait_before_block(block_count)+1)
                    TR_wait_count = nan;
                    jump_in_jitter_count = jump_in_jitter_count + 1;
                end

                if isnan(TR_wait_count)
                    % Judge if jitter or end block
                    if pre_fill_count==exp.trial_num_per_block
                        if (TR_sub_count==0)||(isnan(TR_sub_count))
                            if jump_in_jitter_count>=2
                                break
                            else
                                TR_wait_count = 1;
                                TR_sub_count = nan;
                                PsychPortAudio('Stop', pahandle);
                            end 
                        end
                    end

                    TR_sub_count = TR_sub_count + 1;
                    if TR_sub_count==1

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % TR = 1, load sound
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        pre_fill_count = pre_fill_count + 1;
                        participant_log_trial_count = participant_log_trial_count + 1;
                        if (pre_fill_count==1)||((pre_fill_count>1)&&(mod(Next_trial_TR_index_list(pre_fill_count-1),2)))
                            if_convert_freq_omit = 0;
                        else
                            if_convert_freq_omit = 1;
                        end
                        [sig_mask,~,sig_log,~,~] = prepare_stim_for_layer_fMRI_tono_adapted(cfg,tar_freq_list(pre_fill_count),1-catch_index_list(pre_fill_count),catch_index_list(pre_fill_count),0,if_convert_freq_omit,scanner);
                        status = PsychPortAudio('GetStatus', pahandle);
                        if status.Active == 1
                            PsychPortAudio('FillBuffer', pahandle, sig_mask',2);
                        else
                            PsychPortAudio('FillBuffer', pahandle, sig_mask');
                        end

                        % Flip screen and playsound
                        Screen('TextSize', window, 70);
                        DrawFormattedText(window, '+', 'center', 'center', [1 0 0]);
                        PsychPortAudio('Stop', pahandle);
                        PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
                        fprintf('New sound start to play.\n');
                        %DrawFormattedText(window, '+', 'center', 'center', [1 0 0]);
                        Screen('Flip', window);
                        %Block participant button press
                        if_green_light = 0;
                        
                        % Record event
                        timestemp_event_count = timestemp_event_count + 1;
                        sig_log_cutted = sig_log(sig_log(:,3)<(scanner.TR*Next_trial_TR_index_list(pre_fill_count)-scanner.latency),:);
                        participant_log.timestamp_log(timestemp_event_count).tone_time_freq = sig_log_cutted;
                        participant_log.timestamp_log(timestemp_event_count).trial_type = catch_index_list(pre_fill_count);
                        participant_log.timestamp_log(timestemp_event_count).tar_freq = tar_freq_list(pre_fill_count);
                        participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                        participant_log.timestamp_log(timestemp_event_count).Block_num = block_count;
                        
                        % Record trial type
                        participant_log.result(participant_log_trial_count).trial = participant_log_trial_count;
                        participant_log.result(participant_log_trial_count).trial_type = catch_index_list(pre_fill_count);
                        participant_log.result(participant_log_trial_count).targ_frequency = tar_freq_list(pre_fill_count);
                        participant_log.result(participant_log_trial_count).block_num = block_count;
                        participant_log.result(participant_log_trial_count).start_TR = Total_TR_count;

                        participant_log.scan_event(5,Total_TR_count) = 1;
                        

                    elseif TR_sub_count==Green_light_TR_index_list(pre_fill_count)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Green light, start to recording.
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %Enable participant button press
                        if_green_light = 1;
                        DrawFormattedText(window, '+', 'center', 'center', [0 1 0]);
                        Screen('Flip', window);
                        time_start = GetSecs();
                        participant_log.result(participant_log_trial_count).green_light_TR = Total_TR_count;
                        participant_log.result(participant_log_trial_count).green_light_TR_at_which_sub_TR = TR_sub_count;
                        participant_log.scan_event(5,Total_TR_count) = 2;
                        % Record event
                        timestemp_event_count = timestemp_event_count + 1;
                        participant_log.timestamp_log(timestemp_event_count).green_flip = 1;
                        participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                        participant_log.timestamp_log(timestemp_event_count).Block_num = block_count;

                        fprintf('Enable participant button press.\n');
                    elseif TR_sub_count==(Green_light_TR_index_list(pre_fill_count)+exp.greenlight_TR_duration)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Turn back to red light.
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %Enable participant button press
                        if_green_light = 0;
                        DrawFormattedText(window, '+', 'center', 'center', [1 0 0]);
                        Screen('Flip', window);
                        participant_log.scan_event(5,Total_TR_count) = 3;
                        % Record event
                        timestemp_event_count = timestemp_event_count + 1;
                        participant_log.timestamp_log(timestemp_event_count).red_flip = 1;
                        participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                        participant_log.timestamp_log(timestemp_event_count).Block_num = block_count;
                        
                        fprintf('Disable participant button press.\n');
                    end
                    if TR_sub_count==Next_trial_TR_index_list(pre_fill_count)
                        TR_sub_count = 0;
                        fprintf('Prepare next trial.\n');
                    end

                end
                
                % Record TR time
                fprintf(['Block ',num2str(block_count),' | Trial ', num2str(pre_fill_count),' | TR trigger ',num2str(Total_TR_count),' ---  Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),' | Sub TR: ',num2str(TR_sub_count),'\n']);
                participant_log.scan_event(1,Total_TR_count) = Total_TR_count;
                participant_log.scan_event(2,Total_TR_count) = keyTime;
                if isnan(TR_wait_count)
                    participant_log.scan_event(3,Total_TR_count) = block_count;
                end
                participant_log.scan_event(4,Total_TR_count) = TR_sub_count;
                

                clear keyIsDown keyTime keyCode;
            else
                %Check if green light
                if if_green_light==1
                    % If participant response was recorded
                    if (sum(event_code_cache(1,:)==key.i1)>0)&&(sum(event_code_cache(2,:)==key.i1)==0)&&(sum(event_code_cache(3,:)==key.i1)==0)
                        time_end = GetSecs();

                        % Record event
                        timestemp_event_count = timestemp_event_count + 1;
                        participant_log.timestamp_log(timestemp_event_count).Response = 1;
                        participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                        
                        %fprintf(['Event 1 ---  Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),'\n']);
                        participant_log.result(participant_log_trial_count).reaction = 1;
                        participant_log.result(participant_log_trial_count).reaction_time = time_end - time_start;
                        clear keyIsDown keyTime keyCode;
                        fprintf(['Button response at trial ',num2str(participant_log_trial_count),' ---  Time: ',num2str(time_end - time_start),' | Response: ',num2str(participant_log.result(participant_log_trial_count).reaction),'\n']);
                    elseif (sum(event_code_cache(1,:)==key.i2)>0)&&(sum(event_code_cache(2,:)==key.i2)==0)&&(sum(event_code_cache(3,:)==key.i2)==0)
                        time_end = GetSecs();

                        % Record event
                        timestemp_event_count = timestemp_event_count + 1;
                        participant_log.timestamp_log(timestemp_event_count).Response = 0;
                        participant_log.timestamp_log(timestemp_event_count).System_Time = GetSecs(0);
                        
                        %fprintf(['Event 2 ---  Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),'\n']);
                        participant_log.result(participant_log_trial_count).reaction = 0;
                        participant_log.result(participant_log_trial_count).reaction_time = time_end - time_start;
                        clear keyIsDown keyTime keyCode;
                        fprintf(['Button response at trial ',num2str(participant_log_trial_count),' ---  Time: ',num2str(time_end - time_start),' | Response: ',num2str(participant_log.result(participant_log_trial_count).reaction),'\n']);
                    end
                end
            end
        end
    end
end
%%
% Prepare time_event_log
fprintf('\n ...Preparing time event log... \n');
participant_log.time_event_log = generate_time_event_log(participant_log.timestamp_log,participant_log.result);
fprintf('\n Done. \n');
%%
% Shutdown experiment and export data
if exit_code
    save([export_log_path,participant_log.name,'_Behaviour_Result_Not_Finished.mat'],'participant_log');
else
    save([export_log_path,participant_log.name,'_Behaviour_Result.mat'],'participant_log');
end
ShowCursor;
if exit_code||(trial_count==exp.total_trial_num(3))
    PsychPortAudio('Close');
    %PsychPortAudio('Close', pahandle);
    fprintf('Experiment stopped.\n');
end
ListenChar(1);
Screen('CloseAll');
sca
close all