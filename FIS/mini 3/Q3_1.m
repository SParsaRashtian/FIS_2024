load ballbeam.dat;
U = ballbeam(:,1);
Y = ballbeam(:,2);

inputData = [Y(1:end-1), U(1:end-1)];  
outputData = Y(2:end);                 


[inputNorm, inputSettings] = mapminmax(inputData');
[outputNorm, outputSettings] = mapminmax(outputData');
inputNorm = inputNorm';
outputNorm = outputNorm';

trainRatio = 0.7;
n = size(inputNorm, 1);
nTrain = floor(trainRatio * n);
trainInput = inputNorm(1:nTrain, :);
trainOutput = outputNorm(1:nTrain, :);
valInput = inputNorm(nTrain+1:end, :);
valOutput = outputNorm(nTrain+1:end, :);

numMFs = [2 2];
mfType = 'gaussmf';
trainingData = [trainInput, trainOutput];
initialFis = genfis1(trainingData, numMFs, mfType);
epochs = 100;
trainedFis = anfis(trainingData, initialFis, epochs);


predOutput = evalfis(valInput, trainedFis);

predOutputDenorm = mapminmax('reverse', predOutput', outputSettings)';
valOutputDenorm = mapminmax('reverse', valOutput', outputSettings)';


rmse = sqrt(mean((predOutputDenorm - valOutputDenorm).^2));
disp(['RMSE: ', num2str(rmse)]);


figure;
plot(valOutputDenorm, 'b', 'LineWidth', 1.5);
hold on;
plot(predOutputDenorm, 'r--', 'LineWidth', 1);
legend('Predicted VS actual');
xlabel('time');
ylabel('ball location');
title('Comparing predicted output with the actual output');
grid on;



