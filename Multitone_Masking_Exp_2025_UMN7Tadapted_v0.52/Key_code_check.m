clc;
%%
key.escapeKey = 27;
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
end
ListenChar(0)
