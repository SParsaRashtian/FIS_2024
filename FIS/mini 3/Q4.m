%% Step 1: Generate System Data
N = 3000; % Total number of samples
u = rand(N, 1); % Random input signal u_k in [0, 1]
y = zeros(N, 1); % Initialize system output

% Nonlinear function g[u]
g = @(u) 0.6*sin(pi*u) + 0.3*sin(3*pi*u) + 0.1*sin(5*pi*u);

% Simulate the system dynamics
for k = 3:N
    y(k) = 0.3*y(k-1) + 0.6*y(k-2) + g(u(k-1));
end

% Prepare input-output data for ANFIS
data = [y(2:end-1), y(1:end-2), u(2:end-1), y(3:end)];
inputData = data(:, 1:3); % Inputs: [y_k, y_k-1, u_k]
outputData = data(:, 4); % Output: y_k+1

%% Step 2: Split Data into Training and Testing Sets
trainRatio = 0.8;
trainSize = round(trainRatio * size(inputData, 1));
trainInput = inputData(1:trainSize, :);
trainOutput = outputData(1:trainSize, :);
testInput = inputData(trainSize+1:end, :);
testOutput = outputData(trainSize+1:end, :);

%% Step 3: Initialize and Train ANFIS
opt = genfisOptions('GridPartition'); % Use grid partitioning for initialization
opt.NumMembershipFunctions = 3; % Number of MFs per input
opt.InputMembershipFunctionType = 'gaussmf'; % Use Gaussian MFs
fis = genfis(trainInput, trainOutput, opt); % Generate initial FIS

% Train the FIS using ANFIS
anfisOpt = anfisOptions('InitialFIS', fis, 'EpochNumber', 100);
anfisOpt.DisplayErrorValues = true;
anfisOpt.ValidationData = [testInput, testOutput];
trainedFIS = anfis([trainInput trainOutput], anfisOpt);

%% Step 4: Evaluate the Model
% Predict output using the trained FIS
predictedOutput = evalfis(testInput, trainedFIS);

% Plot actual vs predicted outputs
figure;
subplot(2, 1, 1);
plot(testOutput, 'b', 'LineWidth', 1.5, 'DisplayName', 'Actual Output');
hold on;
plot(predictedOutput, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Predicted Output');
legend;
title('ANFIS Model Output vs Actual Output');
xlabel('Sample');
ylabel('y_{k+1}');
grid on;

% Calculate and display Mean Squared Error (MSE)
mse = mean((testOutput - predictedOutput).^2);
disp(['Mean Squared Error (MSE): ', num2str(mse)]);

% Calculate and display R-squared (R²)
ss_res = sum((testOutput - predictedOutput).^2); % Residual sum of squares
ss_tot = sum((testOutput - mean(testOutput)).^2); % Total sum of squares
R2 = 1 - (ss_res / ss_tot);
disp(['R-squared (R²): ', num2str(R2)]);

%% Step 5: Visualize Membership Functions and Rules
% Plot membership functions for inputs
figure;
for i = 1:3
    subplot(3, 1, i);
    plotmf(trainedFIS, 'input', i);
    title(['Input ', num2str(i), ' Membership Functions']);
end

% View rules of the trained FIS
figure;
ruleview(trainedFIS);

%% Step 6: Extract and Display FIS Parameters
% Display parameters of the trained FIS
disp('Trained FIS Parameters:');
getfis(trainedFIS)