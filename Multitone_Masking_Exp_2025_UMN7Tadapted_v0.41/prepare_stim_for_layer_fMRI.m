function [sig_mask,sig_targ,sig_log,freq,trial_type] = prepare_stim_for_layer_fMRI(cfg,freq,ifcatch,ifmask,iftarget)

    %----------------------------------------------------------------------
    if ifcatch
        trial_type = 2;
        [sig_mask,sig_log] = write_trial(cfg,nan);
        sig_targ = nan;
        if ~isnan(freq)
            freq=nan;
        end
    else
        if isnan(freq)
            freq = cfg.F;
            freq = freq(randperm(length(freq)));
            freq = freq(1);
        elseif length(freq)>1
            freq = freq(randperm(length(freq)));
            freq = freq(1);
        end
        if iftarget
            trial_type = 0;
            sig_targ = build_targets_alone_trial(freq, cfg);
        else
            sig_targ = nan;
        end
        if ifmask
            trial_type = 1;
            [sig_mask,sig_log] = write_trial(cfg,freq);
        else
            sig_mask = nan;
            sig_log = nan;
        end
    end
    
    sig_mask = [sig_mask' sig_mask'];
    sig_targ = [sig_targ' sig_targ'];

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Supportive function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f_list = calculate_mask_f(cfg,t_freq,if_include_target)
    if isnan(t_freq)
        f_list = remove_freq_from_f_list(cfg.F,cfg,nan);
        f_list = f_list(randperm(length(f_list)));
        f_list = f_list(1:cfg.n_mskrs);
    else
        f_list = cfg.F;
        [~,t_index] = min(abs(f_list-t_freq));
        if t_index<=cfg.prtctdrgn
            %f_list(1:t_index+cfg.prtctdrgn) = [];
            remove_index = 1:t_index+cfg.prtctdrgn;
        elseif t_index>(length(f_list)-cfg.prtctdrgn)
            %f_list(t_index-cfg.prtctdrgn:length(f_list)) = [];
            remove_index = t_index-cfg.prtctdrgn:length(f_list);
        else
            %f_list(t_index-cfg.prtctdrgn:t_index+cfg.prtctdrgn) = [];
            remove_index = t_index-cfg.prtctdrgn:t_index+cfg.prtctdrgn;
        end

        %remove f from f list
        f_list = remove_freq_from_f_list(f_list,cfg,remove_index);

        f_list = f_list(randperm(length(f_list)));
        f_list = f_list(1:(cfg.n_mskrs-1));
        if if_include_target
            f_list = [t_freq,f_list];
        else
            f_list = [f_list(Ranint(length(f_list))),f_list];
        end
    end
end

function [f_list] = remove_freq_from_f_list(f_list,cfg,remove_index)
    %remove freq that overlapping with fMRI noise
    if ~isnan(cfg.remove_F_list)
        reject_f_index_list = [];
        for i = 1:length(cfg.remove_F_list)
            [~,center_index] = min(abs(f_list-cfg.remove_F_list(i)));
            reject_f_index_list = [reject_f_index_list,center_index];
            % for j = 1:cfg.prtctdrgn
            %     reject_f_index_list = [reject_f_index_list,center_index-j,center_index+j];
            % end
        end
        reject_f_index_list(reject_f_index_list<1) = [];
        reject_f_index_list(reject_f_index_list>length(f_list)) = [];
        if ~isnan(remove_index)
            reject_f_index_list = unique([reject_f_index_list,remove_index]);
        else
            reject_f_index_list = unique(reject_f_index_list);
        end
        f_list(reject_f_index_list) = [];
    end
end

function [s,shft_list] = build_window(f,cfg)
    shft_list = zeros(1,length(f));
    s = zeros(1, round(cfg.SOA*cfg.Fs));
    for i = 1:length(f)
        % jitter masker tone onset from 0-550 ms (target SOA - tone length)
        % jitter masker tone freq within an ERB
        if i ~= 1
            shft = (cfg.SOA - cfg.l/cfg.Fs) * rand(1); 
            erb = 24.7 * (0.00437*f(i) + 1);
            f_new = f(i) - erb + rand(1)*2*erb;
        else
            shft = 0;
            f_new = f(i);
        end
        shft_list(i) = shft;
        strt = round(shft*cfg.Fs) + 1;
        fnsh = strt + cfg.l - 1;
        tn = sin(2*pi*f_new*cfg.t);
        tn = tn .* (1/cfg.n_mskrs) .* cfg.W; % normalize and window
        s(strt:fnsh) = s(strt:fnsh) + tn;    
    end

end


function [stim,log] = write_trial(cfg,t_freq)
    stim = [];
    log = zeros(1,3);
    if_include_target_list = zeros(cfg.n_wndws,1);
    if ~isnan(cfg.istarget_window_index)
        if_include_target_list(cfg.istarget_window_index) = 1;
    else
        if_include_target_list(2:end) = 1;
    end

    for i=1:cfg.n_wndws
        f = calculate_mask_f(cfg,t_freq,if_include_target_list(i));
        [current_window,shft_list] = build_window(f,cfg);
        stim = [stim current_window];
        shft_list = shft_list + (i-1)*cfg.SOA;
        %------------------------------------------------------------------
        % Comment if only export mask tones log
        % if isnan(t_freq)||(i==1)
        %     log = [log;[ones(1,length(f))*i;f;shft_list]'];
        % else
        %     log = [log;[ones(1,length(f(2:end)))*i;f(2:end);shft_list(2:end)]'];
        % end
        %------------------------------------------------------------------
        %comment if export mask + target tones log
        log = [log;[ones(1,length(f))*i;f;shft_list]'];
        %------------------------------------------------------------------
    end
    log(1,:) = [];
    if_target_list = zeros(size(log,1),1);
    if_target_list(log(:,2)==t_freq) = 1;
    log = [log,if_target_list];
end


function s = build_targets_alone_trial(f, cfg)

    if_include_target_list = zeros(cfg.n_wndws,1);
    if ~isnan(cfg.istarget_window_index)
        if_include_target_list(cfg.istarget_window_index) = 1;
    else
        if_include_target_list(2:end) = 1;
    end

    tn = sin(2*pi*f*cfg.t);
    tn = tn .* (1/cfg.n_mskrs) .* cfg.W; % normalize and window
    tn = [tn zeros(1, round(cfg.SOA.*cfg.Fs-cfg.l))];
        
    s = [];
    for wndw = 1:cfg.n_wndws
        if if_include_target_list(wndw)
            s = [s tn];
        else
            s = [s zeros(1, round(cfg.SOA.*cfg.Fs))];
        end
    end

end

