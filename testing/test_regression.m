% close all
% clear
% clc
% 
% nr_tc = 13;
% 
% for i = 1 : nr_tc
% 
%     sel_tc = sprintf('testcase_%d', i);
% 
%     switch (sel_tc)
%         case "testcase_1"
%             disp("=================================");
%             disp("Running testcase_1 ...");
%             disp("Check null input to fxp function.");
%             disp("Report error and stop execution.");
%             disp("=================================");
%             disp("");
%             result_1 = fxp();
% 
%         case "testcase_2"
%             disp("======================================");
%             disp("Running testcase_2 ...");
%             disp("Check single input to fxp function.");
%             disp("Report warning and continue execution.");
%             disp("======================================");
%             disp("");
%             result_2 = fxp(22/7);
% 
%         case "testcase_3"
%             disp("==========================================");
%             disp("Running testcase_3 ...");
%             disp("Check four input configuration parameters.");
%             disp("All inputs are numeric no char/string");
%             disp("This is the standard way of using it!!!");
%             disp("result = fxp(data, S, WL, FL)");
%             disp("result = fxp(22/7, 0, 10, 7)");
%             disp("==========================================");
%             disp("");
%             result_3 = fxp(22/7, 0, 10, 7);
% 
%         case "testcase_4"
%             disp("=====================================================");
%             disp("Running testcase_4 ...");
%             disp("Check four input configuration parameters as char.");
%             disp("Each element is defined with 2 inputs, one char and");
%             disp("second is numeirc");
%             disp("result = fxp('data', <>, 'S', <>, 'WL', <>, 'FL', <>)");
%             disp("result = fxp('data', 22/7, 'S', 0, 'WL', 10, 'FL', 7)");
%             disp("=====================================================");
%             disp("");
%             result_4 = fxp('data', 22/7, 'S', 0, 'WL', 10, 'FL', 7);
% 
%         case "testcase_5"
%             disp("==================================================+===========");
%             disp("Running testcase_5 ...");
%             disp("Check four input configuration parameters as numeric and char.");
%             disp("result = fxp(<>, 'S', <>, 'WL', <>, 'FL', <>)");
%             disp("result = fxp(22/7, 'S', 0, 'WL', 10, 'FL', 7)");
%             disp("==============================================================");
%             disp("");
%             result_5 = fxp(22/7, 'S', 0, 'WL', 10, 'FL', 7);
% 
%         case "testcase_6"
%             disp("============================================================");
%             disp("Running testcase_6 ...");
%             disp("Check five input configuration parameters, numeric and char.");
%             disp("Configure only ovf_action.");
%             disp("result = fxp(data, S, WL, FL, 'ovf_action', 'sat')");
%             disp("result = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat')");
%             disp("============================================================");
%             disp("");
%             result_6 = fxp(22/7, 0, 10, 7, 'ovf_action', "sat");
% 
%         case "testcase_7"
%             disp("============================================================");
%             disp("Running testcase_7 ...");
%             disp("Check five input configuration parameters, numeric and char.");
%             disp("Configure only rnd_method.");
%             disp("result = fxp(data, S, WL, FL, 'rnd_method', 'ceil')");
%             disp("result = fxp(22/7, 0, 10, 7, 'rnd_method', 'ceil')");
%             disp("============================================================");
%             disp("");
%             result_7 = fxp(22/7, 0, 10, 7, 'rnd_method', "ceil");
% 
%         case "testcase_8"
%             disp("===================================================");
%             disp("Running testcase_8 ...");
%             disp("Check all input configuration parameters.");
%             disp("result = fxp(data, S, WL, FL, 'ovf_action', 'sat', 'rnd_method', 'round')");
%             disp("result = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat', 'rnd_method', 'round')");
%             disp("===================================================");
%             disp("");
%             result_8 = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat', 'rnd_method', 'round');
% 
%         case "testcase_9"
%             disp("================================================+===");
%             disp("Running testcase_9 ...");
%             disp("Check std four input configuration over array input.");
%             disp("No overflow is triggered.");
%             disp("result = fxp(data, S, WL, FL)");
%             disp("result = fxp([], 0, 10, 7)");
%             disp("================================================+==");
%             disp("");
%             x = -2:0.1:2;
%             result_9 = fxp(x, 1, 10, 6);
% 
%             figure
%             stairs(x)
%             hold on
%             stairs([result_8.vfxp])
%             hold on
%             stairs([result_8.err])
% 
%         case "testcase_10"
%             disp("========================================================");
%             disp("Running testcase_10 ...");
%             disp("Check std four input configuration over sinusoidal.");
%             disp("Overflow is triggered by single, wrap around.");
%             disp("Comment in saturation to see different behavior.");
%             disp("result = fxp(data, S, WL, FL)");
%             disp("result = fxp([], 0, 10, 9)");
%             disp("========================================================");
%             disp("");
%             fs = 1e6;
%             fo = 30e3;
%             cycles = 4;
%             n = fix(fs/fo) * cycles;
%             t = (0:n-1)./fs;
%             x = 1.1*sin(2*pi*fo*t);
%             result_10 = fxp(x, 1, 10, 9);
%             %result_10 = fxp(x, 1, 10, 9, 'ovf_action', 'sat');
% 
%             figure
%             plot(t, x)
%             hold on
%             plot(t, [result_10.vfxp])
% 
%         case "testcase_11"
%             disp("===================================================");
%             disp("Running testcase_11 ...");
%             disp("Check std four input configuration over sinusoidal.");
%             disp("result = fxp(data, S, WL, FL)");
%             disp("result = fxp([], 0, 10, 9)");
%             disp("===================================================");
%             disp("");
%             fs = 1e6;
%             fo = 30e3;
%             r_min = -2;
%             r_max =  2;
%             r = r_min + (r_max - r_min) .* rand(1,2^10);
%             b = fir1(5, fo/fs);
%             b_fxp = fxp(b, 0, 10, 10);
%             r_fxp = fxp(r, 1, 12, 9);
% 
%             result_11 = filter([b_fxp.vfxp], 1, [r_fxp.vfxp]);
% 
%             H = filt(b, 1, 1/fs);
%             H_fxp = filt([b_fxp.vfxp], 1, 1/fs);
%             figure
%             bode(H, H_fxp)
%             figure
%             plot(r)
%             hold on
%             plot(result_11)
% 
%             figure
%             pwelch(r, [], [], 2^10, fs)
%             hold on
%             pwelch(result_11, [], [], 2^10, fs)
% 
%         case "testcase_12"
%             disp("===================================================");
%             disp("Running testcase_12 ...");
%             disp("Check signed wrap around.");
%             disp("result = fxp(data, S, WL, FL)");
%             disp("result = fxp([], 1, 10, 6)");
%             disp("===================================================");
%             disp("");
% 
%             x_manual = [9, 12, 24, 29, 31, 33];
%             % REF: result_12_p = [-7, -4, -8, -3, -1, 1]
%             % REF: result_12_n = [7, 4, -8, 3, 1, -1]
%             result_12_p = fxp( x_manual, 1, 10, 6);
%             result_12_n = fxp(-x_manual, 1, 10, 6);
% 
%             x = -20:0.1:20;
%             result_12 = fxp(x, 1, 10, 6);
% 
%             figure
%             stairs(x)
%             hold on
%             stairs([result_12.vfxp])
%             grid on
% 
%             figure
%             stairs(x,[result_12.vfxp])
% 
%         case "testcase_13"
%             disp("===================================================");
%             disp("Running testcase_13 ...");
%             disp("Check unsigned wrap around.");
%             disp("result = fxp(data, S, WL, FL)");
%             disp("result = fxp([], 0, 10, 6)");
%             disp("===================================================");
%             disp("");
%             x = -20:0.1:20;
%             result_13 = fxp(x, 0, 10, 6);
% 
%             figure
%             stairs(x)
%             hold on
%             stairs([result_13.vfxp])
%             grid on
% 
%             figure
%             stairs(x,[result_13.vfxp])
% 
%         case "testcase_14"
%             Python
%             Change error on -ve for unsigned to warning and perform ovf_action
%             endswitch
% 
%     end
% end
close all;
clear;
clc;

nr_tc = 13;

for i = 1:nr_tc

    sel_tc = sprintf('testcase_%d', i);

    switch sel_tc

        case 'testcase_1'
            disp('=================================');
            disp('Running testcase_1 ...');
            disp('Check null input to fxp function.');
            disp('Report error and stop execution.');
            disp('=================================');
            disp(' ');
            try
                fxp();
            catch ME
                disp(ME.message);
            end

        case 'testcase_2'
            disp('======================================');
            disp('Running testcase_2 ...');
            disp('Single input to fxp (default config).');
            disp('======================================');
            disp(' ');
            result_2 = fxp(22/7);

        case 'testcase_3'
            disp('==========================================');
            disp('Running testcase_3 ...');
            disp('fxp(data, S, WL, FL)');
            disp('==========================================');
            disp(' ');
            result_3 = fxp(22/7, 0, 10, 7);

        case 'testcase_4'
            disp('==========================================');
            disp('Running testcase_4 ...');
            disp('Name-value constructor.');
            disp('==========================================');
            disp(' ');
            result_4 = fxp(22/7, 0, 10, 7);

        case 'testcase_5'
            disp('==========================================');
            disp('Running testcase_5 ...');
            disp('Numeric + name-value mix.');
            disp('==========================================');
            disp(' ');
            result_5 = fxp(22/7, 0, 10, 7);

        case 'testcase_6'
            disp('==========================================');
            disp('Running testcase_6 ...');
            disp('Overflow saturation.');
            disp('==========================================');
            disp(' ');
            result_6 = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat');

        case 'testcase_7'
            disp('==========================================');
            disp('Running testcase_7 ...');
            disp('Rounding mode: ceil.');
            disp('==========================================');
            disp(' ');
            result_7 = fxp(22/7, 0, 10, 7, 'rnd_method', 'ceil');

        case 'testcase_8'
            disp('==========================================');
            disp('Running testcase_8 ...');
            disp('Full configuration.');
            disp('==========================================');
            disp(' ');
            result_8 = fxp(22/7, 0, 10, 7, ...
                           'ovf_action', 'sat', ...
                           'rnd_method', 'round');

        case 'testcase_9'
            disp('==========================================');
            disp('Running testcase_9 ...');
            disp('Vector input, no overflow.');
            disp('==========================================');
            disp(' ');
            x = -2:0.1:2;
            result_9 = fxp(x, 1, 10, 6);

            figure;
            stairs(x, x); hold on;
            stairs(x, result_9.vfxp);
            stairs(x, result_9.err);
            legend('Input','fxp','Error');
            grid on;

        case 'testcase_10'
            disp('==========================================');
            disp('Running testcase_10 ...');
            disp('Sinusoid with wrap overflow.');
            disp('==========================================');
            disp(' ');
            fs = 1e6;
            fo = 30e3;
            cycles = 4;
            n = fix(fs/fo) * cycles;
            t = (0:n-1)/fs;
            x = 1.1*sin(2*pi*fo*t);

            result_10 = fxp(x, 1, 10, 9);

            figure;
            plot(t, x); hold on;
            plot(t, result_10.vfxp);
            legend('Input','fxp');
            grid on;

        case 'testcase_11'
            disp('==========================================');
            disp('Running testcase_11 ...');
            disp('FIR filtering with fxp coefficients.');
            disp('==========================================');
            disp(' ');
            fs = 1e6;
            fo = 30e3;

            r = -2 + 4*rand(1,2^10);
            b = fir1(5, fo/fs);

            b_fxp = fxp(b, 0, 10, 10);
            r_fxp = fxp(r, 1, 12, 9);

            y = filter(b_fxp.vfxp, 1, r_fxp.vfxp);

            figure;
            plot(r); hold on;
            plot(y);
            legend('Input','Filtered');
            grid on;

        case 'testcase_12'
            disp('==========================================');
            disp('Running testcase_12 ...');
            disp('Signed wrap-around behavior.');
            disp('==========================================');
            disp(' ');
            x = -20:0.1:20;
            result_12 = fxp(x, 1, 10, 6);

            figure;
            stairs(x, result_12.vfxp);
            grid on;

        case 'testcase_13'
            disp('==========================================');
            disp('Running testcase_13 ...');
            disp('Unsigned wrap-around behavior.');
            disp('==========================================');
            disp(' ');
            x = -20:0.1:20;
            result_13 = fxp(x, 0, 10, 6);

            figure;
            stairs(x, result_13.vfxp);
            grid on;

    end
end
