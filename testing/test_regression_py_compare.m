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
    o = fxp(x(i), s, wl, fl);
    try, o.ovf_action = ovf; catch, end_try_catch
    try, o.rnd_method = rnd; catch, end_try_catch

    try
      vfxp(i) = o.vfxp;
    catch
      try
        vfxp(i) = o.dec;
      catch
        vfxp(i) = double(o);
      end_try_catch
    end_try_catch

    try
      err(i) = o.err;                 % expected: input - quantized
    catch
      err(i) = x(i) - vfxp(i);
    end_try_catch
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

% NOTE: These are placeholders. Replace with your exact stimuli as needed.
tc_list = [3 4 5 6 7];
x_list  = [3.14 0.97234 22/7 0.0 -0.0];
for t = 1:numel(tc_list)
  tc_id = tc_list(t);
  x = x_list(t);
  write_csv_vector(fullfile(outdir, sprintf("tc_%d_x.csv", tc_id)), x);
  write_meta_row(fidm, tc_id, "quantize", 0, 10, 7, "sat", "round");
end

x = linspace(-2.0, 2.0, 401);
write_csv_vector(fullfile(outdir, "tc_8_x.csv"), x);
write_meta_row(fidm, 8, "quantize", 1, 12, 9, "sat", "round");

n = 0:1023;
x = 0.95 * sin(2*pi*17*n/1024);
write_csv_vector(fullfile(outdir, "tc_9_x.csv"), x);
write_meta_row(fidm, 9, "quantize", 1, 12, 10, "sat", "round");

b = [0.05 0.1 0.15 0.4 0.15 0.1 0.05];
x = randn(1, 2048) * 0.25;
write_csv_vector(fullfile(outdir, "tc_10_b.csv"), b);
write_csv_vector(fullfile(outdir, "tc_10_x.csv"), x);

fmeta = fopen(fullfile(outdir, "filter_meta.csv"), "w");
if fmeta < 0, error("Cannot open filter_meta.csv"); end
fprintf(fmeta, "name,signed,n_word,n_frac,overflow,rounding\n");
fprintf(fmeta, "b,0,10,10,sat,round\n");
fprintf(fmeta, "x,1,12,9,sat,round\n");
fclose(fmeta);

write_meta_row(fidm, 10, "fir", 0, 0, 0, "sat", "round");
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

for tc_id = [3 4 5 6 7 8 9]
  total += 1;
  try
    x = read_csv_vector(fullfile(outdir, sprintf("tc_%d_x.csv", tc_id)));
    meta = fileread(meta_path);
    lines = strsplit(strtrim(meta), "\n");
    found = false;
    for i = 2:numel(lines)
      parts = strsplit(lines{i}, ",");
      if numel(parts) < 7, continue; end
      if str2double(parts{1}) == tc_id
        s  = str2double(parts{3});
        wl = str2double(parts{4});
        fl = str2double(parts{5});
        ovf = parts{6};
        rnd = parts{7};
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

% FIR tc10
total += 1;
try
  b  = read_csv_vector(fullfile(outdir, "tc_10_b.csv"));
  x  = read_csv_vector(fullfile(outdir, "tc_10_x.csv"));

  [bq, ~] = octave_quantize_vec(b, 0, 10, 10, "sat", "round");
  [xq, ~] = octave_quantize_vec(x, 1, 12, 9,  "sat", "round");

  y_oct = filter(bq(:).', 1, xq(:).');
  y_py  = read_csv_vector(fullfile(outdir, "tc_10_y_py.csv")).';

  [p, m] = compare_vectors_soft("tc10 y", y_oct(:), y_py(:), ABS_TOL, REL_TOL);
  if p
    fprintf("tc10: PASS\n");
    fprintf(fidr, "tc10: PASS\n");
  else
    fails += 1;
    fprintf("tc10: FAIL\n");
    fprintf(fidr, "tc10: FAIL\n  - %s\n", m);
  end
catch err
  fails += 1;
  fprintf("tc10: ERROR (%s)\n", err.message);
  fprintf(fidr, "tc10: ERROR (%s)\n", err.message);
end_try_catch

fprintf(fidr, "\nSummary: %d total, %d failed\n", total, fails);
fclose(fidr);

fprintf("\nReport written to: %s\n", report_path);
fprintf("Summary: %d total, %d failed\n", total, fails);
