function [L_ces_db, rtn] = p2108_aeronautical_rev1(f_ghz, theta_deg, p, opts)
%P2108_AERONAUTICAL_REV1 Earth-space and aeronautical statistical clutter loss, ITU-R P.2108 Annex 1 sec. 3.3.
%   [L_ces_db, rtn] = P2108_AERONAUTICAL_REV1(f_ghz, theta_deg, p) returns
%   the clutter loss (dB) not exceeded for p percent of locations, for a
%   ground terminal in urban or suburban clutter and an airborne or space
%   terminal at elevation theta_deg. See the expansion note below.
%
%     f_ghz      frequency, GHz (10-100)
%     theta_deg  elevation angle, degrees (0-90)
%     p          percentage of locations, % (0 < p < 100)
%
%   L_ces = (-K_1 ln(1 - p/100) cot(A_1 (1 - theta/90) + pi theta/180))^(0.5 (90 - theta)/90) - 1 - 0.6 Q^-1(p/100)
%   with K_1 = 93 f^0.175 and A_1 = 0.05 (Eqn 7).
%
%   Name-value option q_inverse: "ntia" (default) uses the rational
%   approximation of the NTIA reference code; "exact" uses
%   sqrt(2)*erfcinv(2q). The two differ by less than 0.003 dB.
%
%   Inputs follow implicit expansion: a column of one input and a row of
%   another give a grid.
%
%   Name-value option error_mode: "error" (default) or "code" (NaN and 64-66).
%
%   Port of src/AeronauticalStatisticalModel.cpp of the NTIA reference
%   implementation (github.com/NTIA/p2108, v1.1), vectorized.
arguments
    f_ghz double
    theta_deg double
    p double
    opts.error_mode (1,1) string {mustBeMember(opts.error_mode, ["error", "code"])} = "error"
    opts.q_inverse (1,1) string {mustBeMember(opts.q_inverse, ["ntia", "exact"])} = "ntia"
end
c = p2108_constants_rev1();
[f_ghz, theta_deg, p] = p2108_expand_rev1(f_ghz, theta_deg, p);
rtn = zeros(size(f_ghz));
rtn(p <= 0 | p >= 100) = c.ERROR33_PERCENTAGE;
rtn(theta_deg < 0 | theta_deg > 90) = c.ERROR33_THETA;
rtn(f_ghz < 10 | f_ghz > 100) = c.ERROR33_FREQUENCY;
ok = rtn == c.SUCCESS;
L_ces_db = NaN(size(f_ghz));
if any(ok, 'all')
    f = f_ghz(ok); th = theta_deg(ok); pp = p(ok);
    A_1 = 0.05;
    K_1 = 93 * f.^0.175;
    part1 = log(1 - pp / 100.0);
    part2 = A_1 * (1 - th / 90.0) + pi * th / 180.0;
    part3 = 0.5 * (90.0 - th) / 90.0;
    part4 = 0.6 * p2108_inv_ccdf_rev1(pp / 100, opts.q_inverse);
    L_ces_db(ok) = (-K_1 .* part1 .* (1 ./ tan(part2))).^part3 - 1 - part4;
end
p2108_report_rev1(rtn, opts.error_mode, c);
end
