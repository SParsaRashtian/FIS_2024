%% Step 1: Load and Normalize Data
data = load('steamgen.dat');

% ورودی‌ها و خروجی‌ها
U = data(:, 1:4); % ورودی‌ها
Y = data(:, 5:8); % خروجی‌ها

% نرمال‌سازی داده‌ها
U_min = min(U); U_max = max(U);
Y_min = min(Y); Y_max = max(Y);
U_norm = (U - U_min) ./ (U_max - U_min);
Y_norm = (Y - Y_min) ./ (Y_max - Y_min);

%% Step 2: Define Gaussian Membership Function
gaussian = @(x, mean, sigma) exp(-0.5 * ((x - mean) ./ sigma).^2);

%% Step 3: Initialize ANFIS Parameters
n_rules = 30; % تعداد قوانین بیشتر برای پوشش بهتر
n_inputs = size(U, 2); % تعداد ورودی‌ها
n_outputs = size(Y, 2); % تعداد خروجی‌ها

% مقداردهی اولیه برای توابع عضویت
means = zeros(n_rules, n_inputs);
sigmas = zeros(n_rules, n_inputs);
for i = 1:n_inputs
    means(:, i) = linspace(min(U_norm(:, i)), max(U_norm(:, i)), n_rules);
    sigmas(:, i) = (max(U_norm(:, i)) - min(U_norm(:, i))) / (2 * n_rules);
end

% مقداردهی اولیه وزن‌ها و بایاس
weights = rand(n_rules, n_outputs);
bias = rand(1, n_outputs);

%% Step 4: Train ANFIS Model
epochs = 1000; % تعداد epoch‌ها
learning_rate = 0.005; % نرخ یادگیری کمتر برای همگرایی بهتر

for epoch = 1:epochs
    % 1. محاسبه عضویت‌ها
    membership = zeros(size(U_norm, 1), n_rules);
    for i = 1:n_rules
        membership(:, i) = prod(gaussian(U_norm, means(i, :), sigmas(i, :)), 2);
    end

    % 2. پیش‌بینی خروجی
    rule_outputs = membership * weights + bias;

    % 3. محاسبه خطا
    error = Y_norm - rule_outputs;

    % 4. گرادیان برای وزن‌ها و بایاس
    grad_weights = -2 * (membership' * error) / size(U_norm, 1);
    grad_bias = -2 * mean(error, 1);

    % 5. به‌روزرسانی وزن‌ها و بایاس
    weights = weights - learning_rate * grad_weights;
    bias = bias - learning_rate * grad_bias;

    % نمایش خطا هر 50 epoch
    mse = mean(error.^2, 'all');
    if mod(epoch, 50) == 0
        fprintf('Epoch %d/%d, MSE: %.6f\n', epoch, epochs, mse);
    end
end

%% Step 5: Evaluate the Model
% محاسبه عضویت‌ها روی داده‌های تست
membership_test = zeros(size(U_norm, 1), n_rules);
for i = 1:n_rules
    membership_test(:, i) = prod(gaussian(U_norm, means(i, :), sigmas(i, :)), 2);
end

% پیش‌بینی خروجی
y_pred_norm = membership_test * weights + bias;
y_pred_real = y_pred_norm .* (Y_max - Y_min) + Y_min; % بازگرداندن به مقیاس واقعی

%% Step 6: Calculate RMSE for Each Output
rmse_values = zeros(1, n_outputs);
for i = 1:n_outputs
    rmse_values(i) = sqrt(mean((Y(:, i) - y_pred_real(:, i)).^2));
    fprintf('RMSE for Output %d: %.4f\n', i, rmse_values(i));
end

%% Step 7: Plot Results
figure;
titles = ["Drum Pressure (PSI)", "Excess Oxygen (%)", "Water Level", "Steam Flow (Kg/s)"];
for i = 1:n_outputs
    subplot(n_outputs, 1, i);
    plot(Y(:, i), 'b', 'LineWidth', 1.5); hold on;
    plot(y_pred_real(:, i), 'r--', 'LineWidth', 1.5);
    title(titles(i));
    xlabel('Sample Index');
    ylabel(titles(i));
    legend('Real Output', 'Predicted Output');
    grid on;
end