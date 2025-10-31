# Multi-Tone-Masking-Awareness-Training-fMRI-adaption
Experiment on multi-tone masking, including target detection training and fMRI adaptation experiment.

Operating environment: 
  Matlab 2023b or later  (before Matlab 2023b not verified), Psychtoolbox 3.0.15 or later, Signal Processing toolbox.

Run Experiment_Startup_main.m to start the experiment.
  Choose 1 to start offline training & MRI simulating experiment.
  Choose 2 to start fMRI experiment.

Scanning / stimuli / experiment configuration could be modified through Training_exp_setting_main.m for training experiment, and MRI_exp_settings_main.m for fMRI experiment.

We provided a TR trigger simulator based on AutoHotKey Dash, install through https://www.autohotkey.com/.
To enable simulated TR trigger, download AutoHotKey and enable MRI_Trigger_Simulator.ahk by double clicking, then press ctrl + 8 to enable / disable trigger simulator.
TR is 2s (hard coded), to change simulated TR, change in MRI_Trigger_Simulator.ahk with notebook. In row SetTimer PressT, X ; replace X into the time you would prefer (unit: ms).

Run generate_example_stim_main.m to write an example stimulation sound with target frequency at 1196Hz.

offline training & MRI simulating experiment log will exported in Practice_Result folder, fMRI experiment log will exported in Result folder, 

Log file structure:
Participant_log
|
|—---------ID               % Paricipant id
|
|—---------name             % Participant log file name
|
|—---------scan_date        % Log create date and time
|
|—---------exp              % Experiment parameters (how many trials etc.)
|
|—---------result           % Participant behaviour result
|
|—---------timestamp_log    % Event timestamp record, including TR, sound, screen flipping, and response
|
|—---------scan_event       % TR record: including number of TR, time, TR in which run, how many TRs within one trial, TR triggered event (sound onset and screen flip)
|
|—---------time_event_log   % Similar to timestamp_log. Each individual tone was recorded in this log. Event Discription of TR: num of TR; Event Discription of Tone: frequency of Tone
|
|—---------cfg              % Sound configuration (sample rate, window length, SOA etc.)
|
|——-------scanner           % Scanner configuration (TR, # TRs before and after of each run, and TR to sound jitter)
|
|—---------key              % Response keys configuration

Hope you enjoy!
