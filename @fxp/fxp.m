%% -------------------------------------------------------------------
%% Copyright (C) 2025 Ahmed Shahein
%% -------------------------------------------------------------------
%% GNU Octave Fixed-Point (fxp) Library
%% This library introduces and fixed-point (fxp) data-type.
%% Moreover, it provides a full support for standard arithemtic
%% operands to handle the new fxp data-type.
%% -------------------------------------------------------------------
%% Author: Ahmed Shahein
%% Email: ahmed.shahein@vlsi-design.org
%% Date: 2025
%% -------------------------------------------------------------------
classdef fxp
  % Define fxp object configuration, numeric values, and metadata
  properties
    % Configuration (scalar)
    S          = 0;       % Signedness
    WL         = 0;       % Word-length
    IL         = 0;       % Integer-length
    FL         = 0;       % Fraction-length
    ovf_action = 'wrap';  % Overflow action: 'sat' or 'wrap'
    rnd_method = 'round'; % Rounding method: 'round', 'fix', 'floor', 'ceil'
    % Derived Constants (scalar)
    max        = 0;       % Upper bound of fxp range
    min        = 0;       % Lower bound of fxp range
    res        = 0;       % Resolution of fxp configuration
    DR_dB      = 0;       % Dynamic Range in dB of fxp configuration
    % Data (scalar or array)
    int        = [];      % Integer part of the fxp value
    frac       = [];      % Fractional part of the fxp value
    dec        = [];      % Integer representation of the fxp value
    vfxp       = [];      % Quantized fxp Value based on fxp configuration
    float      = [];      % Float/Double input value to be converted
    bin        = [];      % Binary representation of fxp (array)
    bin_str    = [];      % Binary representation of fxp with decimal point (string)
    err        = [];      % Quantization error
    ovf        = [];      % Flag indicates over-flow, 1==OVF
  end %%properties

  % Define functions that accepts fxp
  methods
    %% -----------
    %% Constructor
    %% -----------
    function obj = fxp(varargin)
    % FXP Fixed-Point Data Type Class
      if (nargin == 0)
        disp("### ERR: The function shall have at least one input");
        return
      end

      if (nargin == 1)
        if (isnumeric(varargin{1}))
          disp("### INFO: Using default values for fixed-point configuration.");
          data       = varargin{1};
          obj.S      = 1;
          obj.WL     = 16;
          obj.FL     = 8;
          obj.IL     = obj.WL - obj.FL - obj.S;
        end
      elseif (nargin == 4)
        for i = 1 : numel(varargin)
          if ~isnumeric(varargin{i})
            disp("### ERR: Fixed-point configuration parameters shall be integer.");
            return
          end
        end

        data       = varargin{1};
        obj.S      = varargin{2};
        obj.WL     = varargin{3};
        obj.FL     = varargin{4};
        obj.IL     = obj.WL - obj.FL - obj.S;
      elseif (nargin > 4)
        incr_idx = 0;
        for i = 1 : numel(varargin)
          if ischar(varargin{i}) && (incr_idx == 0)
              variable = varargin{i};
              switch (variable)
                case {'data'}
                  data = varargin{i+1};
                case {'S'}
                  obj.S = varargin{i+1};
                case {'WL'}
                  obj.WL = varargin{i+1};
                case {'FL'}
                  obj.FL = varargin{i+1};
                case {'ovf_action'}
                  obj.ovf_action = varargin{i+1};
                case {'rnd_method'}
                  obj.rnd_method = varargin{i+1};
                otherwise
                  disp("ERR: Unrecongnized fxp configuration parameter.");
                  return
              endswitch
              incr_idx = 1;
          else
            if incr_idx == 1
              incr_idx = 0;
              continue
            else
              if     i == 1
                data = varargin{i};
              elseif i == 2
                obj.S = varargin{i};
              elseif i == 3
                obj.WL = varargin{i};
              elseif i == 4
                obj.FL = varargin{i};
              else
                incr_idx = 0;
              end %%
            end %%if
          end %%ischar
        end %%for
        obj.IL     = obj.WL - obj.FL - obj.S;
      end %%if

      % Validate signedness for negative numbers
      % In case of unsigned numbers, report error
      % if any of the input values are negative.
      if (obj.S == 0) && (any(data(:) < 0))
        disp('ERR: Cannot represent negative number in unsigned format');
        return
      end

      % Common obj values for single or array input
      % Store configuration
      % Calculate fixed-point parameters
      obj.res        =  2^(-obj.FL);
      obj.max        =  2^obj.IL - 2^(-obj.FL);
      obj.min        = -2^obj.IL * obj.S;
      obj.DR_dB      =  6.02 * (obj.WL - obj.FL);

      % Quantize the input value
      obj = fxp_quantize(obj, data);

    end %%fxp

    % Core Quantization Function
    % Quantize Single Value
    function obj = fxp_quantize(obj, x)
      % Check for over-flow
      if ( (x > obj.max) || (x < obj.min) )
        fxp_ovf = 1;
      else
        fxp_ovf = 0;
      end

      obj.float = x;

      if (fxp_ovf == 1)
        if strcmp(obj.ovf_action, 'sat')
          if (x >= 0)
            x = obj.max;
          elseif (x < 0)
            x = obj.min;
          end
        elseif strcmp(obj.ovf_action, 'wrap')
          if (x >= 0)
            x = obj.max - x;
          elseif (x < 0)
            x = obj.min - x;
          end
        end
      else
        x = x;
      end

      obj.ovf = fxp_ovf;

      % Apply rounding
      obj.dec     = round(x * 2^obj.FL);
      obj.vfxp    = obj.dec / 2^obj.FL;
      obj.int     = sign(obj.float) * fix(abs(obj.vfxp));
      obj.frac    = abs(obj.vfxp) - abs(obj.int);

      % Generate binary representation (2's complement)
      obj.bin     = de2bi(obj.S*2^obj.WL - (-sign(obj.dec) .* abs(obj.dec)), obj.WL, 'left-msb');
      obj.bin_str = print_fxp_str(obj.bin, obj.S, obj.WL, obj.FL);

      % Calculate quantization error
      obj.err     = abs(x - obj.vfxp);
    end %%fxp_quantize

    %% ---------------------
    %% Arithmetic Operations
    %% ---------------------
    % Addition
    function result = plus(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        res_S    = max(obj1.S, obj2.S);
        res_WL   = max(obj1.WL, obj2.WL) + 1;
        res_FL   = max(obj1.FL, obj2.FL);
        res_vfxp = obj1.vfxp + obj2.vfxp;
        result   = fxp(res_vfxp, res_S, res_WL, res_FL, 'ovf_action', obj1.ovf_action, 'rnd_method', obj1.rnd_method);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%plus

    % Subtraction
    function result = minus(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
        error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        res_S    = max(obj1.S, obj2.S);
        res_WL   = max(obj1.WL, obj2.WL) + 1;
        res_FL   = max(obj1.FL, obj2.FL);
        res_vfxp = obj1.vfxp - obj2.vfxp;
        result   = fxp(res_vfxp, res_S, res_WL, res_FL, 'ovf_action', obj1.ovf_action, 'rnd_method', obj1.rnd_method);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%minus

    % Multiplication
    function result = mtimes(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        res_S    = max(obj1.S, obj2.S);
        res_WL   = obj1.WL + obj2.WL;
        res_FL   = obj1.FL + obj2.FL;
        res_vfxp = obj1.vfxp * obj2.vfxp;
        result   = fxp(res_vfxp, res_S, res_WL, res_FL, 'ovf_action', obj1.ovf_action, 'rnd_method', obj1.rnd_method);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%mtimes

    % Division
    function result = mrdivide(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        res_S    = max(obj1.S, obj2.S);
        res_IL   = obj1.IL + obj2.FL + max(obj1.S, obj2.S);
        res_FL   = obj2.IL + obj1.FL;
        res_WL   = res_IL + res_FL;
        res_vfxp = obj1.vfxp / obj2.vfxp;
        result   = fxp(res_vfxp, res_S, res_WL, res_FL, 'ovf_action', obj1.ovf_action, 'rnd_method', obj1.rnd_method);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%rdivide

    % Modulo
    function result = mod(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        res_S    = max(obj1.S, obj2.S);
        res_IL   = obj1.IL + obj2.FL + max(obj1.S, obj2.S);
        res_FL   = obj2.IL + obj1.FL;
        res_WL   = res_IL + res_FL;
        res_vfxp = mod(obj1.vfxp, obj2.vfxp);
        result   = fxp(res_vfxp, res_S, res_WL, res_FL, 'ovf_action', obj1.ovf_action, 'rnd_method', obj1.rnd_method);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%mod

    %% ---------------------
    %% Comparison Operations
    %% ---------------------
    % Equivalence
    function result = eq(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        result = (obj1.vfxp == obj2.vfxp);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%eq

    % Non-Equivalence
    function result = ne(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        result = ~eq(obj1, obj2);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%ne

    % Less Than
    function result = lt(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        result = (obj1.vfxp < obj2.vfxp);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%ne

    % Less Than or Equal
    function result = le(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        result = (obj1.vfxp <= obj2.vfxp);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%eq

    % Greater Than
    function result = gt(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        result = (obj1.vfxp > obj2.vfxp);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%gt

    % Greater Than or Equal
    function result = ge(obj1, obj2)
      if ( (isa(obj1, 'fxp')) && (isa(obj2, 'fxp')) )
        if ~strcmp(obj1.ovf_action, obj2.ovf_action)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        if ~strcmp(obj1.rnd_method, obj2.rnd_method)
          error("ERR: Oveflow action of both operands is not identical.");
        end
        result = (obj1.vfxp >= obj2.vfxp);
      else
        error("ERR: Both addition arguments shall be fxp.");
      end
    end %%ge

    %% ------------------
    %% Logical Operations
    %% ------------------
    % Negation
    function result = uminus(obj)
      result = fxp(-obj.vfxp, obj.S, obj.WL, obj.FL, 'overflow', obj.ovf_action, 'rounding', obj.rnd_method);
    end %%uminus

    %% --------------------
    %% Conversion Functions
    %% --------------------
    % fxp2double
    function val = double(obj)
      val = obj.vfxp;
    end %%fxp2double

    % fxp2uint32
    function val = uint32(obj)
      val = uint32(abs(obj.dec));
    end %%fxp2uint32

    % fxp2int32
    function val = int32(obj)
      val = int32(obj.dec);
    end %%fxp2int32

    % bin2float
    function val = bin2dec(obj)
      p   = obj.IL-(~obj.S) : -1 : -obj.FL;
      val = -2^(obj.IL)*obj.bin(1)*obj.S + sum(2.^p(1+obj.S:end) .* obj.bin(1+obj.S:end));
    end

    % fxp2struct
    function s = struct(obj)
      % Convert fxp object to struct with all fields
      % Usage:
      %   f = fxp(3.14, 1, 16, 8);
      %   s = struct(f);

      s = struct();
      s.vfxp       = obj.vfxp;
      s.S          = obj.S;
      s.WL         = obj.WL;
      s.IL         = obj.IL;
      s.FL         = obj.FL;
      s.max        = obj.max;
      s.min        = obj.min;
      s.res        = obj.res;
      s.DR_dB      = obj.DR_dB;
      s.int        = obj.int;
      s.frac       = obj.frac;
      s.dec        = obj.dec;
      s.bin        = obj.bin;
      s.bin_str    = obj.bin_str;
      s.err        = obj.err;
      s.ovf        = obj.ovf;
      s.ovf_action = obj.ovf_action;
      s.rnd_method = obj.rnd_method;
    end

    %% -----------------------
    %% Display/Print Functions
    %% -----------------------
    function disp(obj)
      % Display fixed-point object
      fprintf('\n Fixed-Point (fxp) Object:\n');
      fprintf(' %-18s: %d-bit, Sign=%d, Int=%d, Frac=%d\n', ...
          'Config', obj.WL, obj.S, obj.IL, obj.FL);
      fprintf(' %-18s: [%g, %g]\n', 'Range', obj.min, obj.max);
      fprintf(' %-18s: %g\n', 'Resolution', obj.res);
      fprintf(' %-18s: %.2f dB\n', 'Dynamic Range:', obj.DR_dB);
      fprintf(' %-18s: %g\n', 'Value');
      disp(obj.vfxp);
      fprintf(' %-15s: %g\n', 'Quantization Error:');
      disp(obj.err);
      fprintf(' %-18s: %s\n', 'Binary', obj.bin_str);
      fprintf(' %-18s: %d\n', 'Overflow', obj.ovf);
      fprintf('\n');
    end

    function s = char(obj)
      % Convert to string representation
      s = sprintf('fxp(%g, %d, %d, %d)', obj.vfxp, obj.S, obj.WL, obj.FL);
    end
  end %%methods
end %%classdef


%% ============================================================================
%% Helper Functions (Static Methods Alternative)
%% ============================================================================
% Wrapper for rounding schemes support for fxp Class.
% round == round away from 0
% fix   == round towards 0
% floor == round towards -inf
% ceil  == round towards +inf
function rounded = round_fxp(val, method)
  % Apply rounding method to fixed-point value
  switch method
    case 'round'
      rounded = round(val);
    case 'floor'
      rounded = floor(val);
    case 'ceil'
      rounded = ceil(val);
    case 'trunc'
      rounded = fix(val);
    otherwise
      rounded = round(val);
  end
end

% Print binary vector as string indicating decimal point.
% It supports +ve and -ve fraction length, automatic padding.
% It supports 2's complement.
function bin_str = print_fxp_str(fxp_bin, s, wl, fl)
  il = wl - fl - s;
  if ( (il+fl+s) != wl )
    return
    disp("### ERR: Word-length do not match the summation of integer and fractional length");
  end

  % No fractional part
  % il shall be larger than wl
  if fl < 0
    lsb_pad = zeros(1,abs(fl));
  % No integer part
  % fl shall be larger than wl
  elseif il < 0
    if s == 0
      msb_pad = zeros(1,abs(il));
    else
      msb = fxp_bin(1);
      msb_pad = msb * ones(1,abs(il+1));
    end
    int_bin = [];
    frc_bin = [msb_pad fxp_bin(1:end)];
  else
    int_bin = fxp_bin(1:il+s);
    frc_bin = fxp_bin(il+s+1:end);
  endif

  bin_str = strrep(strcat(num2str(int_bin),'.',num2str(frc_bin)),' ' ,'');

end
% EOF
