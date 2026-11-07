function varargout = p2108_expand_rev1(varargin)
%P2108_EXPAND_REV1 Expand inputs to one common size with MATLAB implicit expansion rules.
%   [a, b, ...] = P2108_EXPAND_REV1(a, b, ...) returns the inputs expanded
%   to their common size. Sizes must be compatible: in each dimension the
%   inputs have the same length or length 1. A column of distances and a
%   row of percentiles therefore give a distance-by-percentile grid.
%   Errors with p2108:sizeMismatch when sizes are incompatible.
%
%   Built-in used: implicit expansion of the logical OR operator builds the
%   common size without evaluating any arithmetic on the data, so Inf and
%   NaN inputs pass through unchanged.
try
    common = false(size(varargin{1}));
    for k = 2:nargin
        common = common | false(size(varargin{k}));
    end
catch me
    error('p2108:sizeMismatch', 'Input sizes are not compatible for implicit expansion (%s).', me.message);
end
sz = size(common);
varargout = cell(1, nargin);
for k = 1:nargin
    x = varargin{k};
    if isequal(size(x), sz)
        varargout{k} = x;
    else
        reps = sz ./ [size(x), ones(1, numel(sz) - ndims(x))];
        varargout{k} = repmat(x, reps);
    end
end
end
