%% Step 1: Load and Preprocess Data
opts = detectImportOptions('AirQualityUCI.csv', 'Delimiter', ';', 'VariableNamingRule', 'preserve');
data = readtable('AirQualityUCI.csv', opts);

% حذف ستون‌های غیرعددی (Date, Time)
data(:, {'Date', 'Time'}) = [];

% تبدیل مقادیر غیرعددی به عددی
varTypes = varfun(@class, data, 'OutputFormat', 'cell');
for i = 1:numel(varTypes)
    if strcmp(varTypes{i}, 'cell')
        data.(data.Properties.VariableNames{i}) = str2double(data.(data.Properties.VariableNames{i}));
    end
end

% حذف مقادیر گمشده و جایگزینی NaN با مقدار میانگین هر ستون
data = fillmissing(data, 'movmean', 5);

% تبدیل جدول به آرایه عددی
data = table2array(data);

% تقسیم داده‌ها به ویژگی‌ها (X) و خروجی (y)
X = data(:, 1:end-1);
y = data(:, end);

% نرمال‌سازی داده‌ها بین [0, 1]
X = normalize(X);
y = normalize(y);

%% Step 2: Split Data into Train, Validation, and Test Sets
rng(42); % برای تکرارپذیری
[trainInd, valInd, testInd] = dividerand(size(X, 1), 0.6, 0.2, 0.2);

X_train = X(trainInd, :);
y_train = y(trainInd);

X_val = X(valInd, :);
y_val = y(valInd);

X_test = X(testInd, :);
y_test = y(testInd);

%% Step 3: Define ANFIS Parameters
num_features = size(X_train, 2); % تعداد ویژگی‌ها
num_mfs = 2; % تعداد توابع عضویت برای هر ویژگی
num_rules = num_mfs ^ num_features; % تعداد قوانین فازی

% مقداردهی اولیه برای توابع عضویت گوسی
means = zeros(num_features, num_mfs);
sigmas = zeros(num_features, num_mfs);
for i = 1:num_features
    means(i, :) = linspace(min(X_train(:, i)), max(X_train(:, i)), num_mfs);
    sigmas(i, :) = (max(X_train(:, i)) - min(X_train(:, i))) / (2 * num_mfs);
end

% مقداردهی اولیه وزن‌های قوانین
rule_weights = rand(num_rules, 1);

%% Step 4: Train ANFIS Model using Gradient Descent
epochs = 10000; % تعداد Epochs
learning_rate = 0.01; % نرخ یادگیری

for epoch = 1:epochs
    % محاسبه مقدار عضویت و خروجی قوانین برای داده‌های آموزش
    membership_train = compute_membership(X_train, means, sigmas);
    rules_output_train = compute_rules_output(membership_train);

    % محاسبه خروجی پیش‌بینی شده
    y_pred_train = rules_output_train * rule_weights;
    
    % خطا
    error = y_train - y_pred_train;
    
    % محاسبه گرادیان و بروزرسانی وزن‌ها
    gradient = -2 * (rules_output_train' * error) / size(X_train, 1);
    rule_weights = rule_weights - learning_rate * gradient;
    
    % محاسبه MSE
    mse = mean(error .^ 2);
    if mod(epoch, 10) == 0
        fprintf('Epoch %d/%d, MSE: %.6f\n', epoch, epochs, mse);
    end
end

%% Step 5: Evaluate the Model on Test Data
membership_test = compute_membership(X_test, means, sigmas);
rules_output_test = compute_rules_output(membership_test);
y_pred_test = rules_output_test * rule_weights;

% محاسبه MSE روی داده‌های تست
test_error = y_test - y_pred_test;
test_mse = mean(test_error .^ 2);
fprintf('Test MSE: %.6f\n', test_mse);

%% Step 6: Plot Results
figure;
plot(y_test, 'b', 'LineWidth', 1.5); hold on;
plot(y_pred_test, 'r--', 'LineWidth', 1.5);
legend('Actual Output', 'Predicted Output');
title('ANFIS-based Fuzzy System Performance');
xlabel('Sample Index');
ylabel('Normalized CO(GT)');
grid on;

%% ================= Local Functions ================= %%
function membership = compute_membership(X, means, sigmas)
    % محاسبه مقدار عضویت گوسی برای هر ویژگی
    [num_samples, num_features] = size(X);
    num_mfs = size(means, 2);
    membership = zeros(num_samples, num_features, num_mfs);
    for i = 1:num_features
        for j = 1:num_mfs
            membership(:, i, j) = exp(-((X(:, i) - means(i, j)).^2) ./ (2 * sigmas(i, j).^2));
        end
    end
end

function rules_output = compute_rules_output(membership)
    % محاسبه خروجی قوانین فازی
    [num_samples, num_features, num_mfs] = size(membership);
    num_rules = num_mfs ^ num_features;
    rules_output = ones(num_samples, num_rules);
    
    for rule_idx = 1:num_rules
        rule_input = dec2base(rule_idx-1, num_mfs, num_features) - '0' + 1;
        for feature_idx = 1:num_features
            rules_output(:, rule_idx) = rules_output(:, rule_idx) .* membership(:, feature_idx, rule_input(feature_idx));
        end
    end
end