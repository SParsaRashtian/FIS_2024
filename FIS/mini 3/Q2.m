% حالت‌های اولیه و نهایی
x0 = 10; phi0 = 0; % حالت اولیه
xf = 0; phif = pi/2; % حالت نهایی (x = 0, phi = 90 درجه)

% تنظیمات شبیه‌سازی
dt = 0.05; % گام زمانی
steps = 1200; % تعداد مراحل شبیه‌سازی
b = 2; % فاصله چرخ‌ها (ثابت b)

% تعریف متغیرها
x = zeros(steps, 1);
phi = zeros(steps, 1);
theta = zeros(steps, 1); % کنترل زاویه فرمان

% مقداردهی اولیه
x(1) = x0; phi(1) = phi0;

%% طراحی سیستم فازی
fis = mamfis('Name', 'ParkingController');

% ورودی 1: فاصله از هدف (Distance)
fis = addInput(fis, [-15 15], 'Name', 'Distance');
fis = addMF(fis, 'Distance', 'trapmf', [-15 -15 -5 -2], 'Name', 'FarLeft');
fis = addMF(fis, 'Distance', 'trimf', [-5 0 5], 'Name', 'Center');
fis = addMF(fis, 'Distance', 'trapmf', [2 5 15 15], 'Name', 'FarRight');

% ورودی 2: زاویه انحراف (DeltaPhi)
fis = addInput(fis, [-pi pi], 'Name', 'DeltaPhi');
fis = addMF(fis, 'DeltaPhi', 'trapmf', [-pi -pi -pi/4 0], 'Name', 'Left');
fis = addMF(fis, 'DeltaPhi', 'trimf', [-pi/8 0 pi/8], 'Name', 'Center');
fis = addMF(fis, 'DeltaPhi', 'trapmf', [0 pi/4 pi pi], 'Name', 'Right');

% خروجی: زاویه فرمان (Theta)
fis = addOutput(fis, [-pi/8 pi/8], 'Name', 'Theta');
fis = addMF(fis, 'Theta', 'trimf', [-pi/8 -pi/16 0], 'Name', 'Left');
fis = addMF(fis, 'Theta', 'trimf', [-pi/32 0 pi/32], 'Name', 'Straight');
fis = addMF(fis, 'Theta', 'trimf', [0 pi/16 pi/8], 'Name', 'Right');

% قوانین فازی
ruleList = [
    1 1 1 1 1; % فاصله FarLeft و انحراف Left -> فرمان Left
    1 2 1 1 1; % فاصله FarLeft و انحراف Center -> فرمان Left
    1 3 2 1 1; % فاصله FarLeft و انحراف Right -> فرمان Straight
    2 1 1 1 1; % فاصله Center و انحراف Left -> فرمان Left
    2 2 2 1 1; % فاصله Center و انحراف Center -> فرمان Straight
    2 3 3 1 1; % فاصله Center و انحراف Right -> فرمان Right
    3 1 2 1 1; % فاصله FarRight و انحراف Left -> فرمان Straight
    3 2 3 1 1; % فاصله FarRight و انحراف Center -> فرمان Right
    3 3 3 1 1; % فاصله FarRight و انحراف Right -> فرمان Right
];
fis = addRule(fis, ruleList);

%% شبیه‌سازی دینامیک ماشین
for k = 1:steps
    % محاسبه فاصله و زاویه انحراف
    distance = x(k) - xf; % فاصله از موقعیت هدف
    deltaPhi = phif - phi(k); % زاویه انحراف از حالت نهایی مطلوب
    
    % اعمال کنترل فازی
    theta(k) = evalfis(fis, [distance, deltaPhi]);
    
    % محدود کردن زاویه فرمان به بازه [-pi/8, pi/8]
    theta(k) = max(-pi/8, min(pi/8, theta(k)));
    
    % به‌روزرسانی دینامیک ماشین
    phi_k = theta(k) / b;
    x(k+1) = x(k) + cos(phi(k) + phi_k) * dt;
    phi(k+1) = phi(k) + (2 * sin(theta(k)) / b) * dt;
    
    % توقف در صورت رسیدن به هدف
    if abs(x(k+1) - xf) < 0.01 && abs(phi(k+1) - phif) < 0.01
        disp(['Reached goal at step ', num2str(k)]);
        x = x(1:k+1); phi = phi(1:k+1); theta = theta(1:k);
        break;
    end
end

%% رسم مسیر
figure;
plot(1:length(x), x, 'b', 'LineWidth', 1.5); hold on;
yline(0, 'r--', 'LineWidth', 1.5); % موقعیت هدف
grid on;
title('موقعیت x در طول زمان');
xlabel('گام زمانی');
ylabel('x');

figure;
plot(1:length(phi), phi * 180/pi, 'g', 'LineWidth', 1.5); hold on;
yline(90, 'r--', 'LineWidth', 1.5); % زاویه هدف
grid on;
title('زاویه φ در طول زمان');
xlabel('گام زمانی');
ylabel('φ (درجه)');