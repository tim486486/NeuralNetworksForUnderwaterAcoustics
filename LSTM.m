% Tim Smith - ENGI9867 Final Project
% This function trains and tests the NN
%
% To Test this method:
%   1. Load the '00_Data_Sets' Matrix
%   2. Load one of the following
%       -'02_1F1L_net'
%       -'03_2F1L_net'
%       -'04_2F2L_net'
%   3. Set the num_features and num_layers parameters appropriately
%   4. Run the file
%   5. The confusion matrix will be displayed with the classification
%   accuracy and BER shown at the top
%

close all;

num_features = 1; %set this to 1 if testing 1F1L network
num_layers = 2; %set this to 2 if retraining the 2F2L network
generate_new_sets = 0; %set this to 1 to generate new data sets
trained = 1; %set this to 0 to retrain the network

v_sound = 1482.3;
distance = 100;
threshold = 0.5;
training_size_ = 2000;
test_size_ = 2000;
fc = 1000;
bit_rate = fc/10;
do_plot = 1;
seed = 1;

if generate_new_sets == 1
    [training_set,training_info,training_size,training_full,t_training] = generateData(v_sound,distance,threshold,training_size_,fc,bit_rate,0,seed);
    [test_set,test_info,test_size,test_full,t_test] = generateData(v_sound,distance,threshold,test_size_,fc,bit_rate,do_plot,seed+1);    
end

%feature extraction

training_features_numeric = [training_info(:,11).*ones(size(training_set,1),size(training_set,2)/2) ...
    training_info(:,12).*ones(size(training_set,1),size(training_set,2)/2)]; 
training_features = num2cell(training_features_numeric,2);
XTrain = num2cell(training_set,2);
XTrain2 = cellfun(@(x,y)[x;y],XTrain,training_features,'UniformOutput',false);
YTrain = categorical(training_info(:,1));

test_features_numeric = [test_info(:,11).*ones(size(test_set,1),size(test_set,2)/2) ...
    test_info(:,12).*ones(size(test_set,1),size(test_set,2)/2)]; 
test_features = num2cell(test_features_numeric,2);
XTest = num2cell(test_set,2);
XTest2 = cellfun(@(x,y)[x;y],XTest,test_features,'UniformOutput',false);
YTest = categorical(test_info(:,1));

if trained == 0

    inputSize = num_features;
    numHiddenUnits = 150;
    numClasses = 4;
    
    if num_layers == 1
        layers = [ ...
            sequenceInputLayer(inputSize)
            bilstmLayer(numHiddenUnits,'OutputMode','last')
            fullyConnectedLayer(numClasses)
            softmaxLayer
            classificationLayer];
    elseif num_layers == 2
        layers = [ ...
            sequenceInputLayer(inputSize)
            bilstmLayer(numHiddenUnits,'OutputMode','last')
            bilstmLayer(numHiddenUnits,'OutputMode','last')
            fullyConnectedLayer(numClasses)
            softmaxLayer
            classificationLayer];
    end

        maxEpochs = 25;
        miniBatchSize = 40;

        options = trainingOptions('adam', ...
            'ExecutionEnvironment','cpu', ...
            'MaxEpochs',maxEpochs, ...
            'MiniBatchSize',miniBatchSize, ...
            'GradientThreshold',1, ...
            'Verbose',false, ...
            'Plots','training-progress');

        rng(seed);
        
        if num_features == 1
            net = trainNetwork(XTrain,YTrain,layers,options);
        elseif num_features == 2
            net = trainNetwork(XTrain2,YTrain,layers,options);
        end

end

miniBatchSize = 40;

if num_features == 1
    YPred = classify(net,XTest,'MiniBatchSize',miniBatchSize);
elseif num_features == 2
    YPred = classify(net,XTest2,'MiniBatchSize',miniBatchSize);
end
acc = sum(YPred == YTest)./numel(YTest);

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

BER = calcBER(YPred,YTest);

figure
hold off;
sgtitle(strcat('Confusion Matrix, Overall Accuracy: ', num2str(100*acc),'%, BER: ',num2str(100.0*BER), '%'));
C = confusionmat(YTest,YPred);
confusionchart(C, [0 1 2 3]);

