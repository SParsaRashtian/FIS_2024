%% Step 1: Load and Preprocess Data
opts = detectImportOptions('AirQualityUCI.csv', 'Delimiter', ';', 'VariableNamingRule', 'preserve');
data = readtable('AirQualityUCI.csv', opts);

varTypes = varfun(@class, data, 'OutputFormat', 'cell');
disp('Column Types Before Conversion:');
disp(varTypes);


for i = 1:numel(varTypes)
    if strcmp(varTypes{i}, 'cell')
        data.(data.Properties.VariableNames{i}) = str2double(data.(data.Properties.VariableNames{i}));
    end
end


if any(strcmp(data.Properties.VariableNames, 'Date'))
    data.Date = [];
end
if any(strcmp(data.Properties.VariableNames, 'Time'))
    data.Time = [];
end


data = fillmissing(data, 'movmean', 5);


data = table2array(data);


X = data(:, 1:end-1);
y = data(:, end);


X = normalize(X);
y = normalize(y);

%% Step 2: Split Data into Train, Validation, and Test Sets
rng(42); 
N = size(X, 1);
idx = randperm(N); 

train_size = round(0.8 * N);
val_size = round(0.1 * N);
test_size = N - train_size - val_size;

% تقسیم داده‌ها
X_train = X(idx(1:train_size), :);
y_train = y(idx(1:train_size));

X_val = X(idx(train_size+1:train_size+val_size), :);
y_val = y(idx(train_size+1:train_size+val_size));

X_test = X(idx(train_size+val_size+1:end), :);
y_test = y(idx(train_size+val_size+1:end));

%% Step 3: Define RBF Network
num_centers = 300; 


[cluster_idx, centers] = kmeans(X_train, num_centers, 'Replicates', 10);


d_max = max(pdist(centers, 'euclidean')); 
sigma = d_max / sqrt(2 * num_centers); 


gaussmf = @(x, c, s) exp(-((pdist2(x, c) .^ 2) / (2 * s^2)));


Phi_train = gaussmf(X_train, centers, sigma);


weights = pinv(Phi_train) * y_train; 

%% Step 4: Evaluate Model on Test Data
Phi_test = gaussmf(X_test, centers, sigma); 
y_pred_rbf = Phi_test * weights; 


rbf_mse = mean((y_test - y_pred_rbf).^2);
fprintf('RBF Test MSE: %.6f\n', rbf_mse);

%% Step 5: Plot Results
figure;
plot(y_test, 'b', 'LineWidth', 1.5); hold on;
plot(y_pred_rbf, 'r--', 'LineWidth', 1.5);
legend('Actual Output', 'Predicted Output');
title('RBF Network Performance');
xlabel('Sample Index');
ylabel('Normalized Output');
grid on;


