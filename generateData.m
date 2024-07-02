% Tim Smith - ENGI9867 Final Project
% This function generates data samples 

function [samples,sample_info,successful_attempts,full_sample,t_out] = generateData(v_sound_,distance,threshold,attempts,fc,bit_rate,do_plot,seed)
    
    successful_attempts = 0;
    t_travel = distance/v_sound_;
    Tc = 1/fc;
    Td = 1/bit_rate;
    Ts = 1/(20*fc);
    samples_per_bit = Td/Ts;
    samples_per_carrier = Tc/Ts;
    t = 0:Ts:2.5*t_travel + 5*Td;
    plot_num = 1 + 4*(randi([1 (attempts)/4]) - 1); %choose a random plot to show
    o = sin(2*pi*fc*t(1:samples_per_bit));
    z = zeros(1,samples_per_bit);
    ideal(1,:) = [o z z z z z];
    ideal(2,:) = [o z z z o z];
    ideal(3,:) = [o z z o z z];
    ideal(4,:) = [o z z o o z];
    
    rng(seed);

    for k = 1:4:attempts
        for i = 1:4
            %randomly generated interference values
            v_sound = randBetween(0.95, 1.05)*v_sound_;
            preceding_data = randi([1 4]);
            fade_in = randBetween(0.1,0.3);
            fade_out = randBetween(0.2,0.4); 
            attenu = randBetween(0.3,0.7);
            num_paths = randi([1 3]);         
            num_reflections = randi([1 3]);       
            snr = randBetween(1.5,5.0);            
            v_t = randBetween(-25.0,25.0);
            v_r = randBetween(-25.0,25.0);
                        
            %calculations based on random values
            t_travel = distance/v_sound;
            doppler_ratio = (v_sound + v_r)/(v_sound + v_t);   
            fc_dop = doppler_ratio*fc;
            Td_dop = 10/(doppler_ratio*fc_dop);
            samples_per_bit_dop = round(Td_dop/Ts);
            fade_in_time = round(samples_per_bit_dop*fade_in);
            fade_out_time = round(samples_per_bit_dop*fade_out);
            
            %create the real signals with cross fading and the doppler
            %shift
            real = [];
            o = sin(2*pi*fc_dop*t(1:samples_per_bit_dop));
            z = zeros(1,samples_per_bit_dop);
            o_z = [o(1:fade_out_time).*((-1/(fade_out*Td_dop))*t(1:fade_out_time) + 1)...
                zeros(1, samples_per_bit_dop - fade_out_time)];
            z_o = o.*[(1/(fade_in*Td_dop)).*t(1:fade_in_time)...
                ones(1, samples_per_bit_dop - fade_in_time)];
            real(1,:) = [z_o o_z z z z z];
            real(2,:) = [z_o o_z z z z_o o_z];
            real(3,:) = [z_o o_z z z_o o_z z];
            real(4,:) = [z_o o_z z z_o o o_z];
            
            %build the ideal and real signals
            r_ideal = ideal(i,:);
            r = real(i,:);            
            
            %channel simulation
            
            %time shift
            t_travel = round(t_travel/Ts);
            r_ideal = [zeros(1,t_travel) r_ideal];
            r_ideal = [r_ideal zeros(1,numel(t) - numel(r_ideal))];
            if (numel(r_ideal) > numel(t))
                r_ideal = r_ideal(1:numel(t));
            end
            %add a preceding packet to the real signal
            r = [zeros(1,t_travel - numel(r)) real(preceding_data,:) r];
            r = [r zeros(1,numel(t) - numel(r))];
            if (numel(r) > numel(t))
                r = r(1:numel(t));
            end
                        
            %add attenuation
            r = attenu*r;  

            %add multipath progation error
            mp = zeros(1,numel(t));    
            for j = 1: num_paths
                t_mp = round(samples_per_carrier * randBetween(-1.0,1.0));
                mp_buf = randBetween(0.9,1.1)*r;
                if t_mp >= 0 %right-shift
                    mp_buf = [zeros(1,t_mp) mp_buf];
                    mp_buf = mp_buf(1:numel(t));
                else         %left-shift
                    mp_buf = mp_buf(-t_mp + 1:numel(t));
                    mp_buf = [mp_buf zeros(1,-t_mp)];
                end
                mp = mp + mp_buf;
            end
            r = r + mp;

            %add reflections
            ref = zeros(1,numel(t));
            for j = 1:num_reflections
                t_ref = round(samples_per_bit*(j + randBetween(0.0,3.0)));
                attenu_ref = max(0.0,-j*0.2 + randBetween(0.6,0.8));                
                ref_buf = [zeros(1,t_ref) attenu_ref*r]; 
                ref_buf = ref_buf(1:numel(t));
                ref = ref + ref_buf;
            end    
            r = r + ref;

            %add noise
            r = awgn(r,snr,'measured');
            
            %data pre-processing
            
            %normalize
            r_ideal = r_ideal/max(abs(r_ideal));
            r = r/max(abs(r));

            %detect start bit and clip sample      
            start_index = t_travel; 
            detected = 0;
            for j = t_travel:numel(r) - (5*samples_per_bit) - 1
                start_index = j + 3*samples_per_bit;
                if abs(r(j)) > threshold
                    detected = 1;
                    break;
                end     
            end
            
            %sample collection
            end_index = start_index + 2*samples_per_bit - 1;        
            sample_start = [t(start_index), t(start_index)];
            sample_end = [t(end_index), t(end_index)];
            sample_start_ideal = [t_travel*Ts + 3*Td,t_travel*Ts + 3*Td];
            sample_end_ideal = [t_travel*Ts + 5*Td,t_travel*Ts + 5*Td];
            sample_ = r(start_index:end_index);
            
            if detected == 1
                successful_attempts = successful_attempts + 1;
                samples(successful_attempts,:) = sample_;
                sample_info(successful_attempts, 1) = i - 1; %class
                sample_info(successful_attempts, 2) = v_sound; 
                sample_info(successful_attempts, 3) = preceding_data - 1;
                sample_info(successful_attempts, 4) = fade_in;
                sample_info(successful_attempts, 5) = fade_out; 
                sample_info(successful_attempts, 6) = attenu;
                sample_info(successful_attempts, 7) = num_paths;
                sample_info(successful_attempts, 8) = num_reflections;
                sample_info(successful_attempts, 9) = snr; 
                sample_info(successful_attempts, 10) = doppler_ratio;
                sample_info(successful_attempts, 11) = sum(sample_(1:samples_per_bit).^2/snr);
                sample_info(successful_attempts, 12) = sum(sample_(samples_per_bit+1:2*samples_per_bit).^2/snr);
                full_sample(successful_attempts,:) = r;
                t_out(successful_attempts,:) = t;
            end 
            
            %visualization
            
            if do_plot == 1 && k == plot_num
                %Set up the plot window
                fig = figure(i);
                fig.InvertHardcopy = 'off';
                dcm_obj1 = datacursormode(fig);
                set(dcm_obj1,'DisplayStyle','datatip','SnapToDataVertex','off','Enable','on','UpdateFcn',@myupdatefcn);    
                sgtitle(strcat('Plot: ', num2str(plot_num), ', Data: ', num2str(i-1), ', Carrier: ', num2str(fc), ' Hz, Bandwidth: ', num2str(bit_rate), ' Hz, Distance: ', num2str(distance), ' m, v: ', num2str(v_sound), ' m/s'));
                
                x = [-inf,inf];
                y = [-1.1,1.1];
                subplot(311);
                plot(t,r_ideal);
                axis([x y]);
                grid on;
                hold on;
                plot(t,r_ideal);
                plot(sample_start_ideal, y, 'LineWidth', 1, 'Color', 'g');
                plot(sample_end_ideal, y, 'LineWidth', 1, 'Color', 'r');
                legend('Transmitted','Received', 'Sample Start', 'Sample End');
                xlabel('t(s)');
                ylabel('Amplitude');
                title('Ideal');    

                subplot(312);
                plot(t,mp);
                axis([x [min(min(mp,ref)) - 0.1, max(max(mp,ref)) + 0.1]]);
                grid on;
                hold on;
                plot(t,ref);    
                plot(t,r_ideal);
                legend('Multipaths','Reflections','Ideal');
                xlabel('t(s)');
                ylabel('Amplitude');
                title(strcat('Interference, Crossfade: ', num2str(fade_out), ...
                    '%, Preceding Data: ', num2str(preceding_data-1),', Number of Paths: ', num2str(num_paths), ...
                    ', Number of Reflections: ', num2str(num_reflections), ', Doppler Ratio: ', num2str(doppler_ratio)));  
                subplot(313);
                plot(t,r);
                axis([x y]);
                grid on;
                hold on;
                plot(sample_start, y, 'LineWidth', 1, 'Color', 'g');
                plot(sample_end, y, 'LineWidth', 1, 'Color', 'r');
                legend('Received', 'Sample Start', 'Sample End');
                xlabel('t(s)');
                ylabel('Amplitude');
                title(strcat('Actual, SNR: ',num2str(snr), ', Attenuation: ', num2str(attenu)));  
                
            end
        end
    end
end

function r = randBetween(min,max)
    r = (max-min)*rand + min;
end


function txt = myupdatefcn(~,event_obj)
% Customizes text of data tips

    pos = get(event_obj,'Position');
    txt = {['x: ',num2str(pos(1))],['y: ',num2str(pos(2))]};
end