clc;
%%
MRI_exp_settings_main
%%
ListenChar(0)
ListenChar(2)
event_code_cache = zeros(3,length(fieldnames(key)));
event_time_cache = [0,0,0];
TR_count = 0;
escape_press_count = 0;
while 1
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
    %fprintf('Cache filled successfully.\n')

    event_time_cache(3) = event_time_cache(2);
    event_time_cache(2) = event_time_cache(1);
    event_time_cache(1) = keyTime;

    fprintf(['Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),'\n']);

    % if keyIsDown
    %     fprintf('event cache: ');
    %         fprintf([num2str(event_code_cache(1,1)),' ']);
    %         fprintf([num2str(event_code_cache(1,2)),' ']);
    %         fprintf([num2str(event_code_cache(1,3)),' --- ']);
    %     fprintf(',\n');
    %     keyIsDown = 0;
    % end
    if keyCode(key.escapeKey)
        KbReleaseWait;
        escape_press_count = escape_press_count + 1;
        fprintf('\nPress ESC again to exit the experiment.\n');
        if escape_press_count>1
            break
        end
    elseif (keyCode(key.MRI_trigger))||(keyCode(key.i1))||(keyCode(key.i2))
        escape_press_count = 0;
    end
    if (sum(event_code_cache(1,:)==key.MRI_trigger)>0)&&(sum(event_code_cache(2,:)==key.MRI_trigger)==0)&&(sum(event_code_cache(3,:)==key.MRI_trigger)==0)
        TR_count = TR_count + 1;
        fprintf(['TR trigger ',num2str(TR_count),' ---  Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),'\n']);
        clear keyIsDown keyTime keyCode;
    else
        if (sum(event_code_cache(1,:)==key.i1)>0)&&(sum(event_code_cache(2,:)==key.i1)==0)&&(sum(event_code_cache(3,:)==key.i1)==0)
            fprintf(['Event 1 ---  Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),'\n']);
            clear keyIsDown keyTime keyCode;
        elseif (sum(event_code_cache(1,:)==key.i2)>0)&&(sum(event_code_cache(2,:)==key.i2)==0)&&(sum(event_code_cache(3,:)==key.i2)==0)
            fprintf(['Event 2 ---  Time: ',num2str(keyTime),' | keyCode: ',num2str(find(keyCode)),'\n']);
            clear keyIsDown keyTime keyCode;
        end
    end
end
ListenChar(0)

for i = 1:10
    start_time = GetSecs(0);
    [sig_mask,~,~,~,~] = prepare_stim_for_layer_fMRI(cfg,1000,0,1,0);
    end_time = GetSecs(0);
    fprintf([num2str(end_time-start_time),'\n']);
end