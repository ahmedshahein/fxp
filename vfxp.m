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
function vobj = vfxp(data, varargin)
  % FXP_ARRAY Create array of fixed-point objects
  % 
  % Usage:
  %   vobj = fxp_array([2.5, 22/7], 1, 16, 8);
  %   vobj = fxp_array([2.5, 22/7], 1, 16, 8, 'ovf_action', 'sat');
  %
  % Returns:
  %   Cell array of fxp objects, one for each input value
  
  if ~isnumeric(data)
    error("ERR: First argument must be numeric array");
  end
  
  if numel(data) == 1
    warning("INFO: Use fxp() constructor for single values");
    vobj = fxp(data, varargin{:});
    return
  end
  
  % Create cell array to hold fxp objects
  vobj = {};
  
  % Create fxp object for each data element
  for i = 1 : numel(data)
    vobj{i} = fxp(data(i), varargin{:});
  end
  
end %%fxp_array
