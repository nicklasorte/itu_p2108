function [L_ctt_db, rtn] = p2108_terrestrial_rev1(f_ghz, d_km, p, opts)
%P2108_TERRESTRIAL_REV1 Statistical clutter loss for terrestrial paths, ITU-R P.2108 Annex 1 sec. 3.2.
%   [L_ctt_db, rtn] = P2108_TERRESTRIAL_REV1(f_ghz, d_km, p) returns the
%   clutter loss (dB) not exceeded for p percent of locations, for a
%   terrestrial path with one terminal in man-made clutter (urban or
%   suburban). See the expansion note below.
%
%     f_ghz   frequency, GHz (0.5-67)
%     d_km    path distance, km (>= 0.25)
%     p       percentage of locations, % (0 < p < 100)
%
%   L_ctt = -5 log10(10^(-0.2 L_l) + 10^(-0.2 L_s)) - sigma_cb Q^-1(p/100)   (Eqn 3a)
%   sigma_cb^2 = (sigma_l^2 10^(-0.2 L_l) + sigma_s^2 10^(-0.2 L_s)) / (10^(-0.2 L_l) + 10^(-0.2 L_s))   (Eqn 3b)
%   L_l = -2 log10(10^(-5 log10(f) - 12.5) + 10^(-16.5)),  sigma_l = 4 dB   (Eqns 4a, 4b)
%   L_s = 32.98 + 23.9 log10(d) + 3 log10(f),  sigma_s = 6 dB               (Eqns 5a, 5b)
%   The loss is limited to its value at d = 2 km (Eqn 6).
%
%   Name-value option q_inverse: "ntia" (default) uses the rational
%   approximation of the NTIA reference code; "exact" uses
%   sqrt(2)*erfcinv(2q). The two differ by less than 0.003 dB.
%
%   Inputs follow implicit expansion: a column of one input and a row of
%   another give a grid.
%
%   Name-value option error_mode: "error" (default) raises p2108:invalidInput
%   on any invalid input; "code" returns NaN and the return code (48-50).
%
%   Port of src/TerrestrialStatisticalModel.cpp of the NTIA reference
%   implementation (github.com/NTIA/p2108, v1.1), vectorized.
arguments
    f_ghz double
    d_km double
    p double
    opts.error_mode (1,1) string {mustBeMember(opts.error_mode, ["error", "code"])} = "error"
    opts.q_inverse (1,1) string {mustBeMember(opts.q_inverse, ["ntia", "exact"])} = "ntia"
end
c = p2108_constants_rev1();
[f_ghz, d_km, p] = p2108_expand_rev1(f_ghz, d_km, p);
rtn = zeros(size(f_ghz));
rtn(p <= 0 | p >= 100) = c.ERROR32_PERCENTAGE;          % checks in reverse order so the
rtn(d_km < 0.25) = c.ERROR32_DISTANCE;                  % first failing check wins, as in
rtn(f_ghz < 0.5 | f_ghz > 67) = c.ERROR32_FREQUENCY;    % Section3p2_InputValidation
ok = rtn == c.SUCCESS;
L_ctt_db = NaN(size(f_ghz));
if any(ok, 'all')
    L_2km = helper(f_ghz(ok), 2, p(ok), opts.q_inverse);
    L_d = helper(f_ghz(ok), d_km(ok), p(ok), opts.q_inverse);
    L_ctt_db(ok) = min(L_2km, L_d);                     % Eqn 6
end
p2108_report_rev1(rtn, opts.error_mode, c);
end

function L = helper(f, d, p, q_inverse)
sigma_l = 4;
term1 = 10.^(-5 * log10(f) - 12.5);
L_l = -2 * log10(term1 + 10^(-16.5));
sigma_s = 6;
L_s = 32.98 + 23.9 * log10(d) + 3 * log10(f);
w_l = 10.^(-0.2 * L_l);
w_s = 10.^(-0.2 * L_s);
sigma_cb = sqrt((sigma_l^2 * w_l + sigma_s^2 * w_s) ./ (w_l + w_s));
L = -5 * log10(w_l + w_s) - sigma_cb .* p2108_inv_ccdf_rev1(p / 100, q_inverse);
end
