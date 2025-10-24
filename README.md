# Multi-Tone-Masking-Awareness-Training-fMRI-adaption
Experiment on multi-tone masking, including target detection training and fMRI adaption experiment.

Operating environment: Matlab 2023b or later, Psychtoolbox 3.0.15 or later, Signal Processing toolbox.

Run Experiment_Startup_main.m to start the experiment.
Choose 1 to start offline training & MRI simulating experiment.
Choose 2 to start fMRI experiment.

Scanning / stimuli / experiment configuration could be modified through Training_exp_setting_main.m for training experiment, and MRI_exp_settings_main.m for fMRI experiment.

We provided a TR trigger simulator based on AutoHotKey Dash, install through https://www.autohotkey.com/.
To enable simulated TR trigger, download AutoHotKey and enable MRI_Trigger_Simulator.ahk by double clicking, then press ctrl + 8 to enable / disable trigger simulator.

Hope you enjoy!
