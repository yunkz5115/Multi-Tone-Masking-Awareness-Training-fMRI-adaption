function [time_event_log] = generate_time_event_log(timestamp_log,response_result)
%generate time event log from recorded timestampe log
time_event_log = struct(...
    'System_Time',cell(1,1),...
    'Event_Type',cell(1,1),...
    'Event_Discription',cell(1,1),...
    'if_Target',cell(1,1),...
    'if_Detected',cell(1,1),...
    'Trial_num',cell(1,1),...
    'Block_num',cell(1,1));
total_event_count = 0;
total_trial_count = 0;
for i = 1:length(timestamp_log)
    if ~isempty(timestamp_log(i).TR)
        total_event_count = total_event_count + 1;
        time_event_log(total_event_count).System_Time = timestamp_log(i).System_Time;
        time_event_log(total_event_count).Event_Type = 'TR';
        time_event_log(total_event_count).Event_Discription = timestamp_log(i).TR;
        time_event_log(total_event_count).Block_num = timestamp_log(i).Block_num;
    elseif ~isempty(timestamp_log(i).tone_time_freq)
        total_trial_count = total_trial_count + 1;
        %time_event_log(i).System_Time = timestamp_log(i).System_Time;
        %time_event_log(i).Event_Type = 'Sound Play';
        %time_event_log(i).Event_Discription = timestamp_log(i).tone_time_freq;
        for j = 1:length(timestamp_log(i).tone_time_freq)
            total_event_count = total_event_count + 1;
            time_event_log(total_event_count).System_Time = timestamp_log(i).System_Time + timestamp_log(i).tone_time_freq(j,3);
            time_event_log(total_event_count).Event_Type = 'Tone';
            time_event_log(total_event_count).Event_Discription = timestamp_log(i).tone_time_freq(j,2);
            time_event_log(total_event_count).if_Target = timestamp_log(i).tone_time_freq(j,4);
            if timestamp_log(i).tone_time_freq(j,4)
                if ~isempty(response_result(total_trial_count).reaction)
                    time_event_log(total_event_count).if_Detected = response_result(total_trial_count).reaction;
                else
                    time_event_log(total_event_count).if_Detected = nan;
                end
            else
                time_event_log(total_event_count).if_Detected = nan;
            end
            time_event_log(total_event_count).Trial_num = total_trial_count;
            time_event_log(total_event_count).Block_num = timestamp_log(i).Block_num;
        end
    elseif ~isempty(timestamp_log(i).green_flip)
        total_event_count = total_event_count + 1;
        time_event_log(total_event_count).System_Time = timestamp_log(i).System_Time;
        time_event_log(total_event_count).Event_Type = 'Green flip';
        time_event_log(total_event_count).Event_Discription = timestamp_log(i).green_flip;
        time_event_log(total_event_count).Block_num = timestamp_log(i).Block_num;
    elseif ~isempty(timestamp_log(i).red_flip)
        total_event_count = total_event_count + 1;
        time_event_log(total_event_count).System_Time = timestamp_log(i).System_Time;
        time_event_log(total_event_count).Event_Type = 'Red flip';
        time_event_log(total_event_count).Event_Discription = timestamp_log(i).red_flip;
        time_event_log(total_event_count).Block_num = timestamp_log(i).Block_num;
    elseif ~isempty(timestamp_log(i).Response)
        total_event_count = total_event_count + 1;
        time_event_log(total_event_count).System_Time = timestamp_log(i).System_Time;
        time_event_log(total_event_count).Event_Type = 'Response';
        time_event_log(total_event_count).Event_Discription = timestamp_log(i).Response;
        time_event_log(total_event_count).Block_num = timestamp_log(i).Block_num;
    elseif ~isempty(timestamp_log(i).esc_attempt)
        total_event_count = total_event_count + 1;
        time_event_log(total_event_count).System_Time = timestamp_log(i).System_Time;
        time_event_log(total_event_count).Event_Type = 'esc_attempt';
        time_event_log(total_event_count).Event_Discription = timestamp_log(i).esc_attempt;
        time_event_log(total_event_count).Block_num = timestamp_log(i).Block_num;
    end
end
T = struct2table(time_event_log);
time_event_log = sortrows(T, 'System_Time', 'ascend');
end

