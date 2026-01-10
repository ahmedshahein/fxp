close all
clear
clc

nr_tc = 10;

for i = 1 : nr_tc
  
sel_tc = ["testcase_",num2str(i)];

%sel_tc = "testcase_8";

switch (sel_tc)
  case "testcase_1"
    disp("=================================");
    disp("Running testcase_1 ...");
    disp("Check null input to fxp function.");
    disp("=================================");
    disp("");
    result_1 = fxp();
    
  case "testcase_2"
    disp("===================================");
    disp("Running testcase_2 ...");
    disp("Check single input to fxp function.");
    disp("===================================");
    disp("");
    result_2 = fxp(22/7);    
    
  case "testcase_3"
    disp("==========================================");
    disp("Running testcase_3 ...");
    disp("Check four input configuration parameters.");
    disp("result = fxp(data, S, WL, FL)");
    disp("result = fxp(22/7, 0, 10, 7)");
    disp("==========================================");
    disp("");
    result_3 = fxp(22/7, 0, 10, 7);    
    
  case "testcase_4"
    disp("=====================================================");
    disp("Running testcase_4 ...");
    disp("Check four input configuration parameters as char.");
    disp("result = fxp('data', <>, 'S', <>, 'WL', <>, 'FL', <>)");
    disp("result = fxp('data', 22/7, 'S', 0, 'WL', 10, 'FL', 7)");
    disp("=====================================================");
    disp("");
    result_4 = fxp('data', 22/7, 'S', 0, 'WL', 10, 'FL', 7);
    
  case "testcase_5"
    disp("==================================================+===========");
    disp("Running testcase_5 ...");
    disp("Check four input configuration parameters as numeric and char.");
    disp("result = fxp(<>, 'S', <>, 'WL', <>, 'FL', <>)");
    disp("result = fxp(22/7, 'S', 0, 'WL', 10, 'FL', 7)");
    disp("==============================================================");
    disp("");
    result_5 = fxp(22/7, 'S', 0, 'WL', 10, 'FL', 7);
    
  case "testcase_6"
    disp("============================================================");
    disp("Running testcase_6 ...");
    disp("Check five input configuration parameters, numeric and char.");
    disp("result = fxp(data, S, WL, FL, 'ovf_action', 'sat')");
    disp("result = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat')");
    disp("============================================================");
    disp("");
    result_6 = fxp(22/7, 0, 10, 7, 'ovf_action', "sat");
    
  case "testcase_7"
    disp("===================================================");
    disp("Running testcase_7 ...");
    disp("Check all input configuration parameters.");
    disp("result = fxp(data, S, WL, FL, 'ovf_action', 'sat', 'rnd_method', 'round')");
    disp("result = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat', 'rnd_method', 'round')");
    disp("===================================================");
    disp("");
    result_7 = fxp(22/7, 0, 10, 7, 'ovf_action', 'sat', 'rnd_method', 'round');
    
  case "testcase_8"  
    disp("================================================+===");
    disp("Running testcase_8 ...");
    disp("Check std four input configuration over array input.");
    disp("result = fxp(data, S, WL, FL)");
    disp("result = fxp([], 0, 10, 7)");
    disp("================================================+==");
    disp("");
    x = -2:0.1:2;
    for i = 1 : length(x)
      result_8(i) = fxp(x(i), 1, 10, 6);
    end
    figure
    stairs(x)
    hold on
    stairs([result_8.vfxp])
    hold on
    stairs([result_8.err])
    
  case "testcase_9"
    disp("===================================================");
    disp("Running testcase_9 ...");
    disp("Check std four input configuration over sinusoidal.");
    disp("result = fxp(data, S, WL, FL)");
    disp("result = fxp([], 0, 10, 9)");
    disp("==================================================="); 
    fs = 1e6;
    fo = 30e3;
    cycles = 4;
    n = fix(fs/fo) * cycles;
    t = (0:n-1)./fs;
    x = sin(2*pi*fo*t);
    for i = 1 : length(x)
      result_9(i) = fxp(x(i), 1, 10, 9);
    end    
    figure
    plot(t, x)
    hold on
    plot(t, [result_9.vfxp])
    
  case "testcase_10"
    disp("===================================================");
    disp("Running testcase_10 ...");
    disp("Check std four input configuration over sinusoidal.");
    disp("result = fxp(data, S, WL, FL)");
    disp("result = fxp([], 0, 10, 9)");
    disp("===================================================");  
    fs = 1e6;
    fo = 30e3;    
    r_min = -2;
    r_max =  2;
    r = r_min + (r_max - r_min) .* rand(1,2^10);
    b = fir1(5, fo/fs);
    for i = 1 : length(b)
      b_fxp(i) = fxp(b(i), 0, 10, 10);
    end
    for j = 1 : length(r);
      r_fxp(j) = fxp(r(j), 1, 12, 9);
    end
    y_fxp = filter([b_fxp.vfxp], 1, [r_fxp.vfxp]);
    
    figure
    plot(r)
    hold on
    plot(y_fxp)
    
    figure
    pwelch(r, [], [], 2^10, fs)
    hold on
    pwelch(y_fxp, [], [], 2^10, fs)
  case "testcase_11"
    python versus octave
  case "testcase_12"  
endswitch

end