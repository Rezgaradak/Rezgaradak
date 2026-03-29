%% AI Prediction in Renewable Energy Systems using LSTM
% Author: [Your Name]
% Description: This script loads, preprocesses, trains, and evaluates an LSTM model for PV electricity prediction.

clc; clear; close all;

%% Step 1: Load and Explore the Dataset
fprintf('Loading dataset...\n');
filename = 'ninja_pv_53.4795_-2.2451_corrected.csv';

% Read data, skipping metadata lines
opts = detectImportOptions(filename, 'NumHeaderLines', 3);
data = readtable(filename, opts);

% Convert time columns to datetime format
data.time = datetime(data.time, 'InputFormat', 'yyyy-MM-dd HH:mm');
data.local_time = datetime(data.local_time, 'InputFormat', 'yyyy-MM-dd HH:mm');

% Display basic information
disp('First few rows of the dataset:');
disp(data(1:10, :));
disp('Checking for missing values:');
sum(ismissing(data))

%% Step 2: Data Preprocessing
fprintf('Preprocessing data...\n');

% Select relevant columns (Ignoring 'time' and 'local_time')
features = {'irradiance_direct', 'irradiance_diffuse', 'temperature'};
target = {'electricity'};

% Normalize data (Min-Max Scaling)
for i = 1:length(features)
    data.(features{i}) = normalize(data.(features{i}), 'range');
end
data.electricity = normalize(data.electricity, 'range');

% Convert datetime to numeric (days since dataset start)
data.time_numeric = datenum(data.time) - datenum(data.time(1));

% Split dataset: 70% Train, 15% Validation, 15% Test
num_samples = size(data, 1);
train_size = round(0.7 * num_samples);
val_size = round(0.15 * num_samples);

train_data = data(1:train_size, :);
val_data = data(train_size+1:train_size+val_size, :);
test_data = data(train_size+val_size+1:end, :);

% Display dataset sizes
fprintf('Training Data: %d samples\n', size(train_data,1));
fprintf('Validation Data: %d samples\n', size(val_data,1));
fprintf('Test Data: %d samples\n', size(test_data,1));

%% Step 3: Prepare Data for LSTM Training
fprintf('Preparing data for LSTM model...\n');

% Extract Inputs (X) and Output (Y)
X_train = table2array(train_data(:, features))';
Y_train = table2array(train_data(:, target))';

X_val = table2array(val_data(:, features))';
Y_val = table2array(val_data(:, target))';

X_test = table2array(test_data(:, features))';
Y_test = table2array(test_data(:, target))';

% **Fix: Ensure input (X) and target (Y) have the same number of samples**
validIdx_train = all(~isnan(X_train),1) & ~isnan(Y_train);  
X_train = X_train(:, validIdx_train);
Y_train = Y_train(validIdx_train);  

validIdx_val = all(~isnan(X_val),1) & ~isnan(Y_val);
X_val = X_val(:, validIdx_val);
Y_val = Y_val(validIdx_val);

validIdx_test = all(~isnan(X_test),1) & ~isnan(Y_test);
X_test = X_test(:, validIdx_test);
Y_test = Y_test(validIdx_test);

% **Ensure Y_train is a column vector**
Y_train = Y_train(:);
Y_val = Y_val(:);
Y_test = Y_test(:);

% **Ensure final training data sizes match**
fprintf('Final Training Data: %d samples\n', numel(X_train));
fprintf('Final Validation Data: %d samples\n', numel(X_val));
fprintf('Final Test Data: %d samples\n', numel(X_test));
fprintf('Final size of Y_train: %d x %d\n', size(Y_train,1), size(Y_train,2));
fprintf('Final size of Y_val: %d x %d\n', size(Y_val,1), size(Y_val,2));
fprintf('Final size of Y_test: %d x %d\n', size(Y_test,1), size(Y_test,2));

% **Convert X_train to Cell Array for LSTM**
X_train = num2cell(X_train, 1);
X_val = num2cell(X_val, 1);
X_test = num2cell(X_test, 1);

%% 🔎 Debugging Print Statements (Check Before Training)
disp('X_train Example:');
disp(X_train(1:5));  % Show first 5 samples
disp('Y_train Example:');
disp(Y_train(1:5));  % Show first 5 targets

%% Step 4: Build LSTM Model
fprintf('Building LSTM model...\n');

layers = [
    sequenceInputLayer(3) % 3 input features
    lstmLayer(50, 'OutputMode', 'last') % Predict single output per sequence
    fullyConnectedLayer(1)
    regressionLayer
];

options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 64, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {X_val, Y_val}, ...
    'Plots', 'training-progress', ...
    'Verbose', 1);

%% Step 5: Train the Model
fprintf('Training the LSTM model...\n');

net = trainNetwork(X_train, Y_train, layers, options);

%% Step 6: Evaluate the Model
fprintf('Evaluating model on test data...\n');

Y_pred = predict(net, X_test);

% Convert predicted values back to normal scale
Y_pred_rescaled = rescale(Y_pred, min(data.electricity), max(data.electricity));

%% Step 7: Plot Results
figure;
plot(data.time(end-length(Y_test)+1:end), Y_test, 'b', 'LineWidth', 1.5); hold on;
plot(data.time(end-length(Y_pred_rescaled)+1:end), Y_pred_rescaled, 'r--', 'LineWidth', 1.5);
xlabel('Time'); ylabel('Electricity Output (kW)');
legend('Actual', 'Predicted');
title('LSTM Model Prediction vs. Actual Electricity Output');
grid on;

fprintf('Process completed successfully!\n');
i