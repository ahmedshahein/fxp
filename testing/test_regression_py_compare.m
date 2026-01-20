% test_regression_py_compare_report.m
% Octave 5.2 regression harness that DOES NOT STOP on mismatches.
% It logs all PASS/FAIL results and writes a report to:
%   ./interop/report.txt
%
% IMPORTANT:
%   - This script calls: run_fxpmath_ref_v3.py
%   - Ensure run_fxpmath_ref_v3.py is in the same folder as this script.

clear; clc;

ABS_TOL = 0;
REL_TOL = 0;

PY_CMD = "python3";
outdir = fullfile(pwd, "interop");
if ~exist(outdir, "dir")
  mkdir(outdir);
end

% Clean old files
files = dir(fullfile(outdir, "*"));
for k = 1:numel(files)
  if ~files(k).isdir
    unlink(fullfile(outdir, files(k).name));
  end
end

report_path = fullfile(outdir, "report.txt");
fidr = fopen(report_path, "w");
if fidr < 0, error("Cannot open report.txt for write"); end

function ok = nearly_equal(a, b, abs_tol, rel_tol)
  d = abs(a - b);
  ok = (d <= abs_tol) | (d <= rel_tol .* max(abs(a), abs(b)));
end

function write_csv_vector(fname, v)
  fid = fopen(fname, "w");
  if fid < 0, error("Cannot open %s", fname); end
  for i = 1:numel(v)
    fprintf(fid, "%.17g\n", v(i));
  end
  fclose(fid);
end

function v = read_csv_vector(fname)
  v = dlmread(fname, ",");
  v = v(:);
end

function write_meta_header(fid)
  fprintf(fid, "tc_id,op,signed,n_word,n_frac,overflow,rounding\n");
end

function write_meta_row(fid, tc_id, op, s, wl, fl, ovf, rnd)
  fprintf(fid, "%d,%s,%d,%d,%d,%s,%s\n", tc_id, op, s, wl, fl, ovf, rnd);
end

function [vfxp, err] = octave_quantize_vec(x, s, wl, fl, ovf, rnd)
  vfxp = zeros(size(x));
  err  = zeros(size(x));
  for i = 1:numel(x)
    % IMPORTANT:
    % The fxp class used by test_regression.m applies configuration
    % (ovf_action / rnd_method) during construction via name-value pairs.
    % tc7 ('ceil') will fail if rnd_method is set after construction.
    %
    % Therefore, pass configuration using the SAME convention:
    %   fxp(data, S, WL, FL, 'ovf_action', <ovf>, 'rnd_method', <rnd>)
    %
    % We still keep a fallback path for older variants where these
    % properties might be set post-construction.
    try
      o = fxp(x(i), s, wl, fl, 'ovf_action', ovf, 'rnd_method', rnd);
    catch
      % If the constructor doesn't accept one or both name-value pairs,
      % fall back gracefully.
      try
        o = fxp(x(i), s, wl, fl, 'rnd_method', rnd);
      catch
        try
          o = fxp(x(i), s, wl, fl, 'ovf_action', ovf);
        catch
          o = fxp(x(i), s, wl, fl);
        end_try_catch
      end_try_catch

      try, o.ovf_action = ovf; catch, end_try_catch
      try, o.rnd_method = rnd; catch, end_try_catch
    end_try_catch

    try
      vfxp(i) = o.vfxp;
    catch
      try
        vfxp(i) = o.dec;
      catch
        vfxp(i) = double(o);
      end_try_catch
    end_try_catch

    % Quantization error convention: match Python reference (run_fxpmath_ref.py)
    % err = input - quantized
    err(i) = x(i) - vfxp(i);
  end
end

function [pass, msg] = compare_vectors_soft(name, a, b, abs_tol, rel_tol)
  pass = true;
  msg = "";
  if numel(a) ~= numel(b)
    pass = false;
    msg = sprintf("%s size mismatch: %d vs %d", name, numel(a), numel(b));
    return;
  end
  ok = nearly_equal(a, b, abs_tol, rel_tol);
  if ~all(ok)
    pass = false;
    idx = find(~ok, 1, "first");
    maxerr = max(abs(a - b));
    msg = sprintf("%s mismatch at idx=%d: octave=%.17g python=%.17g |maxerr|=%.17g", ...
                  name, idx, a(idx), b(idx), maxerr);
  end
end

% ----------------------------
% Generate meta.csv + stimuli
% ----------------------------
meta_path = fullfile(outdir, "meta.csv");
fidm = fopen(meta_path, "w");
if fidm < 0, error("Cannot open meta.csv for write"); end
write_meta_header(fidm);

% -----------------------------------------------------------------
% Stimuli aligned to test_regression.m (tc3..tc13). The goal here is
% to compare NUMERICAL FIXED-POINT results (vfxp + err) against a
% Python (fxpmath) golden reference.
%
% Notes:
%  - tc1/tc2 focus on input validation behavior, not numerical output.
%  - tc3..tc8 are scalar quantize checks with different API variants.
%  - tc9..tc10 are vector quantize checks.
%  - tc11 is an FIR/filtering check using Octave-generated b (fir1)
%    and deterministic random stimulus.
%  - tc12/tc13 exercise wrap-around for signed/unsigned.
% -----------------------------------------------------------------

% tc3..tc8: scalar quantize (22/7)
x = 22/7;
for tc_id = 3:6
  write_csv_vector(fullfile(outdir, sprintf("tc_%d_x.csv", tc_id)), x);
  % Default configuration used in test_regression.m for these cases
  write_meta_row(fidm, tc_id, "quantize", 0, 10, 7, "sat", "round");
end

% tc7: ceil rounding
write_csv_vector(fullfile(outdir, "tc_7_x.csv"), x);
write_meta_row(fidm, 7, "quantize", 0, 10, 7, "sat", "ceil");

% tc8: sat + round
write_csv_vector(fullfile(outdir, "tc_8_x.csv"), x);
write_meta_row(fidm, 8, "quantize", 0, 10, 7, "sat", "round");

% tc9: array quantize, no overflow
x = -2:0.1:2;
write_csv_vector(fullfile(outdir, "tc_9_x.csv"), x);
write_meta_row(fidm, 9, "quantize", 1, 10, 6, "sat", "round");

% tc10: sinusoidal quantize, overflow expected (default wrap in fxp)
fs = 1e6;
fo = 30e3;
cycles = 4;
n = fix(fs/fo) * cycles;
t = (0:n-1)./fs;
x = 1.1*sin(2*pi*fo*t);
write_csv_vector(fullfile(outdir, "tc_10_x.csv"), x);
write_meta_row(fidm, 10, "quantize", 1, 10, 9, "wrap", "round");

% tc11: FIR/filtering check
%   b = fir1(5, fo/fs);
%   b_fxp = fxp(b, 0, 10, 10);
%   r_fxp = fxp(r, 1, 12, 9);
%   y = filter(b_fxp.vfxp, 1, r_fxp.vfxp);

% Deterministic random stimulus (avoid run-to-run diffs)
rand("seed", 0);
randn("seed", 0);
r_min = -2;
r_max =  2;
r = r_min + (r_max - r_min) .* rand(1, 2^10);
b = fir1(5, fo/fs);
write_csv_vector(fullfile(outdir, "tc_11_b.csv"), b);
write_csv_vector(fullfile(outdir, "tc_11_x.csv"), r);

% filter_meta.csv supports multi-testcase FIR configs
fmeta = fopen(fullfile(outdir, "filter_meta.csv"), "w");
if fmeta < 0, error("Cannot open filter_meta.csv"); end
fprintf(fmeta, "tc_id,name,signed,n_word,n_frac,overflow,rounding\n");
fprintf(fmeta, "11,b,0,10,10,sat,round\n");
fprintf(fmeta, "11,x,1,12,9,sat,round\n");
fclose(fmeta);

write_meta_row(fidm, 11, "fir", 0, 0, 0, "sat", "round");

% tc12: signed wrap-around
x = -20:0.1:20;
write_csv_vector(fullfile(outdir, "tc_12_x.csv"), x);
write_meta_row(fidm, 12, "quantize", 1, 10, 6, "wrap", "round");

% tc13: unsigned wrap-around
x = -20:0.1:20;
write_csv_vector(fullfile(outdir, "tc_13_x.csv"), x);
write_meta_row(fidm, 13, "quantize", 0, 10, 6, "wrap", "round");
fclose(fidm);

% ----------------------------
% Call Python (v3)
% ----------------------------
py_script = fullfile(pwd, "run_fxpmath_ref.py");
cmd = sprintf('%s "%s" "%s"', PY_CMD, py_script, outdir);
[status, out] = system(cmd);
fprintf(fidr, "Python cmd: %s\n", cmd);
fprintf(fidr, "Python status: %d\n", status);
fprintf(fidr, "Python output:\n%s\n", out);
if status ~= 0
  fprintf(fidr, "ERROR: Python call failed.\n");
  fclose(fidr);
  error("Python call failed: %s", cmd);
end

% ----------------------------
% Compare and CONTINUE on failures
% ----------------------------
total = 0;
fails = 0;

fprintf(fidr, "\n==== Comparison Results ====\n");

for tc_id = [3 4 5 6 7 8 9 10 12 13]
  total += 1;
  % Pre-initialize per-test variables to avoid "undefined" errors when
  % an earlier step throws before assignment.
  v_oct = []; e_oct = []; py_v = []; py_e = [];
  try
    x = read_csv_vector(fullfile(outdir, sprintf("tc_%d_x.csv", tc_id)));
    meta = fileread(meta_path);
    lines = strsplit(strtrim(meta), "\n");
    found = false;
    for i = 2:numel(lines)
      parts = strsplit(lines{i}, ",");
      if numel(parts) < 7, continue; end
      if str2double(parts{1}) == tc_id
        % NOTE:
        % meta.csv is written using '\n' line endings, but depending on
        % platform/tooling it may be read back with '\r\n'. That leaves a
        % trailing '\r' on the last CSV field (rounding), which causes
        % rnd_method assignment to silently fail for cases like tc7 ("ceil").
        s  = str2double(strtrim(parts{3}));
        wl = str2double(strtrim(parts{4}));
        fl = str2double(strtrim(parts{5}));
        ovf = strtrim(parts{6});
        rnd = strtrim(parts{7});
        found = true;
        break;
      end
    end
    if ~found
      fails += 1;
      fprintf(fidr, "tc%d: FAIL (no meta row)\n", tc_id);
      continue;
    end
    [v_oct, e_oct] = octave_quantize_vec(x, s, wl, fl, ovf, rnd);
    py_v = read_csv_vector(fullfile(outdir, sprintf("tc_%d_py_vfxp.csv", tc_id)));
    py_e = read_csv_vector(fullfile(outdir, sprintf("tc_%d_py_err.csv", tc_id)));

    [p1, m1] = compare_vectors_soft(sprintf("tc%d vfxp", tc_id), v_oct(:), py_v(:), ABS_TOL, REL_TOL);
    [p2, m2] = compare_vectors_soft(sprintf("tc%d err",  tc_id), e_oct(:), py_e(:), ABS_TOL, REL_TOL);

    if p1 && p2
      fprintf("tc%d: PASS\n", tc_id);
      fprintf(fidr, "tc%d: PASS\n", tc_id);
    else
      fails += 1;
      fprintf("tc%d: FAIL\n", tc_id);
      fprintf(fidr, "tc%d: FAIL\n", tc_id);
      if ~p1, fprintf(fidr, "  - %s\n", m1); end
      if ~p2, fprintf(fidr, "  - %s\n", m2); end
    end
  catch err
    fails += 1;
    fprintf("tc%d: ERROR (%s)\n", tc_id, err.message);
    fprintf(fidr, "tc%d: ERROR (%s)\n", tc_id, err.message);
  end_try_catch
end

% FIR tc11
total += 1;
try
  b  = read_csv_vector(fullfile(outdir, "tc_11_b.csv"));
  x  = read_csv_vector(fullfile(outdir, "tc_11_x.csv"));

  [bq, ~] = octave_quantize_vec(b, 0, 10, 10, "sat", "round");
  [xq, ~] = octave_quantize_vec(x, 1, 12, 9,  "sat", "round");

  y_oct = filter(bq(:).', 1, xq(:).');
  y_py  = read_csv_vector(fullfile(outdir, "tc_11_y_py.csv")).';

  [p, m] = compare_vectors_soft("tc11 y", y_oct(:), y_py(:), ABS_TOL, REL_TOL);
  if p
    fprintf("tc11: PASS\n");
    fprintf(fidr, "tc11: PASS\n");
  else
    fails += 1;
    fprintf("tc11: FAIL\n");
    fprintf(fidr, "tc11: FAIL\n  - %s\n", m);
  end
catch err
  fails += 1;
  fprintf("tc11: ERROR (%s)\n", err.message);
  fprintf(fidr, "tc11: ERROR (%s)\n", err.message);
end_try_catch

fprintf(fidr, "\nSummary: %d total, %d failed\n", total, fails);
fclose(fidr);

fprintf("\nReport written to: %s\n", report_path);
fprintf("Summary: %d total, %d failed\n", total, fails);
