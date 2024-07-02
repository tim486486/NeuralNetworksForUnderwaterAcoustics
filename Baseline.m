% Tim Smith - ENGI9867 Final Project
% Baseline Method
% Demodulate and constrain the input to [0 1]
%
% To Test this method:
%   1. Load the '00_Data_Sets' Matrix
%   2. Load the '01_Baseline_Best_K' Matrix
%   3. Run the file
%   4. The confusion matrix will be displayed with the classification
%   accuracy and BER shown at the top
%

close all;

generate_new_sets = 0; %set this to 1 to generate a new test set
trained = 1; %set this to 0 to find a new threshold value iteratively

v_sound = 1482.3;
distance = 100;
threshold = 0.5;
test_size_ = 2000;
fc = 1000;
fs = 20*fc;
bit_rate = fc/10;
do_plot = 1;
seed = 1;

if generate_new_sets == 1
    [test_set,test_info,test_size,test_full,t_test] = generateData(v_sound,distance,threshold,test_size_,fc,bit_rate,do_plot,seed+1);    
end

YTest = categorical(test_info(:,1));
YTest = YTest';
index = 1;
max_acc = 0;

if trained == 0
    for k = 0:0.001:1 
        bits = [];
        pred = [];    
        for i = 1:size(test_set,1)
            sample = test_set(i,:);
            x = demod(test_set(i,:),fc,fs,'am');
            for j = 1:2
                if abs(mean(x(1 + 200*(j-1):j*200))) > k
                    bits(i,j) = 1;
                else 
                    bits(i,j) = 0;
                end
            end
            if bits(i,1) == 0 && bits(i,2) == 0
                pred(i) = 0;
            elseif bits(i,1) == 0 && bits(i,2) == 1
                pred(i) = 1;
            elseif bits(i,1) == 1 && bits(i,2) == 0
                pred(i) = 2;
            elseif bits(i,1) == 1 && bits(i,2) == 1
                pred(i) = 3;
            end
        end
        acc = sum(categorical(pred) == YTest)./numel(YTest);
        if acc > max_acc
            best_k = k;
            max_acc = acc;
            YPred = categorical(pred);
        end
    end
else
    bits = [];
    pred = [];    
    for i = 1:size(test_set,1)
        sample = test_set(i,:);
        x = demod(test_set(i,:),fc,fs,'am');
        for j = 1:2
            if abs(mean(x(1 + 200*(j-1):j*200))) > best_k
                bits(i,j) = 1;
            else 
                bits(i,j) = 0;
            end
        end
        if bits(i,1) == 0 && bits(i,2) == 0
            pred(i) = 0;
        elseif bits(i,1) == 0 && bits(i,2) == 1
            pred(i) = 1;
        elseif bits(i,1) == 1 && bits(i,2) == 0
            pred(i) = 2;
        elseif bits(i,1) == 1 && bits(i,2) == 1
            pred(i) = 3;
        end
    end
    max_acc = sum(categorical(pred) == YTest)./numel(YTest);
    YPred = categorical(pred);   
end

misclassified_set = [];
misclassified_info = [];
num_misclassified = 0;

for i = 1:size(test_set,1)
    if YPred(i) ~= YTest(i)
        num_misclassified = num_misclassified + 1;
        misclassified_set(num_misclassified,:) = test_set(i,:);
        misclassified_info(num_misclassified,:) = [test_info(i,:) (double(YPred(i))-1)];
    end
end

BER = calcBER(YPred',YTest');

figure
hold off;
sgtitle(strcat('Confusion Matrix, Overall Accuracy: ', num2str(100*max_acc),'%, BER: ',num2str(100.0*BER), '%'));
C = confusionmat(YTest,YPred);
confusionchart(C, [0 1 2 3]);
