function p2108_report_rev1(rtn, error_mode, c)
%P2108_REPORT_REV1 Raise p2108:invalidInput for the first invalid element when error_mode is "error".
%   P2108_REPORT_REV1(rtn, error_mode, c) does nothing in "code" mode or
%   when every return code is 0.
if error_mode == "error" && any(rtn ~= c.SUCCESS, 'all')
    k = find(rtn ~= c.SUCCESS, 1);
    error('p2108:invalidInput', 'Element %d: return code %d (%s).', k, rtn(k), c.messages(rtn(k)));
end
end
