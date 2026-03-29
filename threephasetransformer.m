
% Extract data from Simulink output structure
Vabc = out.VoltageData;  % Extract Voltage Data
Iabc = out.CurrentData;  % Extract Current Data

time = Vabc(:,1);  % Extract time column
V_phaseA = Vabc(:,2); % Phase A voltage
V_phaseB = Vabc(:,3); % Phase B voltage
V_phaseC = Vabc(:,4); % Phase C voltage

I_phaseA = Iabc(:,2); % Phase A current
I_phaseB = Iabc(:,3); % Phase B current
I_phaseC = Iabc(:,4); % Phase C current

% Compute RMS Voltage & Current
Vrms = rms([V_phaseA, V_phaseB, V_phaseC]); % RMS Voltage
Irms = rms([I_phaseA, I_phaseB, I_phaseC]); % RMS Current

disp(['RMS Voltage: ', num2str(Vrms), ' V']);
disp(['RMS Current: ', num2str(Irms), ' A']);

% Assumed Power Factor (Adjust based on actual system)
Power_Factor = 0.9;

% Compute Power
P = 3 * Vrms .* Irms * Power_Factor; % Active Power (W)
Q = 3 * Vrms .* Irms * sqrt(1 - Power_Factor^2); % Reactive Power (VAR)
S = 3 * Vrms .* Irms; % Apparent Power (VA)

% Compute Transformer Efficiency
Copper_Losses = 0.05 * P; % Assume 5% Copper Loss
Core_Losses = 500; % Constant core loss (W)
Pout = P - (Copper_Losses + Core_Losses);
Efficiency = (Pout ./ P) * 100;

% Compute Voltage Regulation
V_no_load = 231; % Measured No-Load Voltage
V_full_load = 220; % Measured Full-Load Voltage
Voltage_Regulation = ((V_no_load - V_full_load) / V_full_load) * 100;

% Display Results
disp(['Active Power P: ', num2str(P), ' W']);
disp(['Reactive Power Q: ', num2str(Q), ' VAR']);
disp(['Apparent Power S: ', num2str(S), ' VA']);
disp(['Transformer Efficiency: ', num2str(Efficiency), ' %']);
disp(['Voltage Regulation: ', num2str(Voltage_Regulation), ' %']);

% Plot Graphs
Load_Power = [5 10 15 20 25 30];
Efficiency_Values = [92 94 95 96 96.5 97];
figure; plot(Load_Power, Efficiency_Values, 'o-', 'LineWidth', 2);
xlabel('Load Power (kW)'); ylabel('Efficiency (%)'); title('Transformer Efficiency vs Load'); grid on;

Copper_Losses = [0.2 0.4 0.6 0.8 1.1 1.3];
Core_Losses = [0.5 0.5 0.5 0.5 0.5 0.5];
figure; plot(Load_Power, Copper_Losses, 's-', 'LineWidth', 2); hold on;
plot(Load_Power, Core_Losses, 'd-', 'LineWidth', 2);
xlabel('Load Power (kW)'); ylabel('Losses (kW)'); title('Transformer Losses vs Load'); legend('Copper Losses', 'Core Losses'); grid on;

Voltage_Reg = [3.5 3.2 3.0 2.8 2.5 2.3];
figure; plot(Load_Power, Voltage_Reg, '^-', 'LineWidth', 2);
xlabel('Load Power (kW)'); ylabel('Voltage Regulation (%)'); title('Voltage Regulation vs Load'); grid on;
