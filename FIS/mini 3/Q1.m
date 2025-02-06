%% تعریف سیستم اولیه
num = [1 0];  % صورت: s
den = [1 1];  % مخرج: s + 1
system = tf(num, den);  % تابع تبدیل سیستم

%% تنظیم پارامترهای زیگلر-نیکلز
Kp_crit = 1.5;  % بهره بحرانی (تقریبی یا از نمودار)
T_crit = 3;   % دوره تناوب نوسان بحرانی (تقریبی)

% ضرایب PID با روش زیگلر-نیکلز
Kp = 0.6 * Kp_crit;
Ki = 1.2 * Kp_crit / T_crit;
Kd = 0.075 * Kp_crit * T_crit;

% تعریف کنترل‌کننده PID
pid_controller = tf([Kd Kp Ki], [1 0]);

%% سیستم حلقه بسته (بدون تأخیر)
closed_loop = feedback(pid_controller * system, 1);  % حلقه بسته با PID

% شبیه‌سازی پاسخ پله
[response, time] = step(closed_loop);

% اضافه کردن نویز به پاسخ
noise = 0.05 * randn(size(response));  % نویز گاوسی
response_with_noise = response + noise;

% اضافه کردن اغتشاش
disturbance = 0.2 * (time >= 5);  % اغتشاش در زمان t = 5
response_with_disturbance = response_with_noise + disturbance;

%% اضافه کردن تأخیر به سیستم
L = 0.5;  % مقدار تأخیر زمانی
[num_delay, den_delay] = pade(L, 10);  % تقریب تأخیر با پاده
delay_system = tf(num_delay, den_delay);
system_with_delay = series(delay_system, system);

% سیستم حلقه بسته با تأخیر
closed_loop_with_delay = feedback(pid_controller * system_with_delay, 1);

% شبیه‌سازی پاسخ سیستم با تأخیر
[response_delay, time_delay] = step(closed_loop_with_delay);

%% رسم نمودارها

% پاسخ سیستم بدون تأخیر (با نویز و اغتشاش)
figure;
subplot(2, 1, 1);
plot(time, response, 'b-', 'LineWidth', 1.5, 'DisplayName', 'PID Control (Real Response)');
hold on;
plot(time, response_with_noise, 'r--', 'LineWidth', 1, 'DisplayName', 'With Noise');
plot(time, response_with_disturbance, 'g:', 'LineWidth', 1, 'DisplayName', 'With Disturbance');
grid on;
xlabel('Time (s)');
ylabel('Response');
title('PID Control with Noise and Disturbance');
legend;

% پاسخ سیستم بدون تأخیر و با تأخیر
subplot(2, 1, 2);
plot(time, response, 'b-', 'LineWidth', 1.5, 'DisplayName', 'PID Control (No Delay)');
hold on;
plot(time_delay, response_delay, 'm--', 'LineWidth', 1.5, 'DisplayName', 'PID Control (With Delay)');
grid on;
xlabel('Time (s)');
ylabel('Response');
title('PID Control: With and Without Delay');
legend;


num = [1 0];  % صورت: s
den = [1 1];  % مخرج: s + 1
system = tf(num, den);  % سیستم اولیه

%% تنظیم کنترل‌کننده PID با MATLAB
% طراحی کنترل‌کننده PID با تنظیم خودکار MATLAB
pid_classic = pidtune(system, 'PID');

% نمایش ضرایب بهینه
disp('Classic PID Coefficients:');
disp(pid_classic);

% سیستم حلقه بسته با کنترل‌کننده PID کلاسیک
closed_loop_classic = feedback(pid_classic * system, 1);

%% تعریف متغیرهای فازی
fis = mamfis('Name', 'Fuzzy PID Controller');

% ورودی 1: خطا (Error)
fis = addInput(fis, [-1 1], 'Name', 'Error');
fis = addMF(fis, 'Error', 'trimf', [-1 -1 0], 'Name', 'Negative');
fis = addMF(fis, 'Error', 'trimf', [-1 0 1], 'Name', 'Zero');
fis = addMF(fis, 'Error', 'trimf', [0 1 1], 'Name', 'Positive');

% ورودی 2: تغییرات خطا (Error_Dot)
fis = addInput(fis, [-1 1], 'Name', 'Error_Dot');
fis = addMF(fis, 'Error_Dot', 'trimf', [-1 -1 0], 'Name', 'Negative');
fis = addMF(fis, 'Error_Dot', 'trimf', [-1 0 1], 'Name', 'Zero');
fis = addMF(fis, 'Error_Dot', 'trimf', [0 1 1], 'Name', 'Positive');

% خروجی‌ها: Kp، Ki، و Kd
fis = addOutput(fis, [0 10], 'Name', 'Kp');
fis = addMF(fis, 'Kp', 'trimf', [0 0 5], 'Name', 'Low');
fis = addMF(fis, 'Kp', 'trimf', [0 5 10], 'Name', 'Medium');
fis = addMF(fis, 'Kp', 'trimf', [5 10 10], 'Name', 'High');

fis = addOutput(fis, [0 10], 'Name', 'Ki');
fis = addMF(fis, 'Ki', 'trimf', [0 0 5], 'Name', 'Low');
fis = addMF(fis, 'Ki', 'trimf', [0 5 10], 'Name', 'Medium');
fis = addMF(fis, 'Ki', 'trimf', [5 10 10], 'Name', 'High');

fis = addOutput(fis, [0 10], 'Name', 'Kd');
fis = addMF(fis, 'Kd', 'trimf', [0 0 5], 'Name', 'Low');
fis = addMF(fis, 'Kd', 'trimf', [0 5 10], 'Name', 'Medium');
fis = addMF(fis, 'Kd', 'trimf', [5 10 10], 'Name', 'High');

%% تعریف قوانین فازی
ruleList = [
    1 1 1 1 1 1 1;  % اگر Error=Negative و Error_Dot=Negative، آنگاه Kp=Low, Ki=Low, Kd=Low
    2 2 2 2 2 1 1;  % اگر Error=Zero و Error_Dot=Zero، آنگاه Kp=Medium, Ki=Medium, Kd=Medium
    3 3 3 3 3 1 1;  % اگر Error=Positive و Error_Dot=Positive، آنگاه Kp=High, Ki=High, Kd=High
];

% اضافه کردن قوانین به سیستم فازی
fis = addRule(fis, ruleList);

%% نمایش قوانین
ruleview(fis);  % مشاهده قوانین فازی


%% مشاهده عملکرد سیستم فازی

% تعریف ورودی‌های آزمایشی
error_values = -1:0.1:1;       % مقادیر مختلف برای خطا
error_dot_values = -1:0.1:1;   % مقادیر مختلف برای تغییرات خطا

% مقداردهی ماتریس‌های خروجی
Kp_values = zeros(length(error_values), length(error_dot_values));
Ki_values = zeros(length(error_values), length(error_dot_values));
Kd_values = zeros(length(error_values), length(error_dot_values));

% محاسبه خروجی‌های سیستم فازی برای ورودی‌های مختلف
for i = 1:length(error_values)
    for j = 1:length(error_dot_values)
        % اجرای سیستم فازی
        outputs = evalfis(fis, [error_values(i), error_dot_values(j)]);
        % ذخیره خروجی‌ها
        Kp_values(i, j) = outputs(1);
        Ki_values(i, j) = outputs(2);
        Kd_values(i, j) = outputs(3);
    end
end

%% رسم نمودارهای خروجی‌ها

% نمودار Kp
figure;
surf(error_dot_values, error_values, Kp_values);
xlabel('Error Dot');
ylabel('Error');
zlabel('Kp');
title('Surface Plot of Kp');
grid on;

% نمودار Ki
figure;
surf(error_dot_values, error_values, Ki_values);
xlabel('Error Dot');
ylabel('Error');
zlabel('Ki');
title('Surface Plot of Ki');
grid on;

% نمودار Kd
figure;
surf(error_dot_values, error_values, Kd_values);
xlabel('Error Dot');
ylabel('Error');
zlabel('Kd');
title('Surface Plot of Kd');
grid on;



time = 0:0.01:10;
response_fuzzy = zeros(size(time));
Kp_fuzzy = zeros(size(time));
Ki_fuzzy = zeros(size(time));
Kd_fuzzy = zeros(size(time));

for t = 1:length(time)
    % خطا و تغییرات خطا
    if t == 1
        error = 0;
        error_dot = 0;
    else
        error = 1 - response_fuzzy(t-1);  % خطا
        error_dot = error - (1 - response_fuzzy(max(t-2, 1)));  % تغییرات خطا
    end

    % اجرای سیستم فازی
    outputs = evalfis(fis, [error, error_dot]);
    Kp_fuzzy(t) = outputs(1);
    Ki_fuzzy(t) = outputs(2);
    Kd_fuzzy(t) = outputs(3);

    % شبیه‌سازی پاسخ سیستم فازی
    response_fuzzy(t) = Kp_fuzzy(t) * error + Ki_fuzzy(t) * sum(error) * 0.01 + Kd_fuzzy(t) * error_dot;
end

%% شبیه‌سازی PID کلاسیک
[response_classic, time_classic] = step(closed_loop_classic, time);

%% رسم مقایسه پاسخ‌ها
figure;
plot(time, response_classic, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Classic PID');
hold on;
plot(time, response_fuzzy, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Fuzzy PID');
grid on;
xlabel('Time (s)');
ylabel('Response');
title('Comparison of Classic PID and Fuzzy PID');
legend;
