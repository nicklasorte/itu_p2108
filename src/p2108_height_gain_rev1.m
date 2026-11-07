function [A_h_db, rtn] = p2108_height_gain_rev1(f_ghz, h_m, w_s_m, R_m, clutter_type, opts)
%P2108_HEIGHT_GAIN_REV1 Height-gain terminal correction model, ITU-R P.2108 Annex 1 sec. 3.1.
%   [A_h_db, rtn] = P2108_HEIGHT_GAIN_REV1(f_ghz, h_m, w_s_m, R_m, clutter_type)
%   returns the additional loss (dB) for a terminal of height h_m inside
%   clutter of representative height R_m. Inputs expand implicitly.
%
%     f_ghz         frequency, GHz (0.03-3)
%     h_m           antenna height, m (> 0)
%     w_s_m         street width, m (> 0); Recommendation default 27 m
%     R_m           representative clutter height, m (> 0); see p2108_constants_rev1 R_default_m
%     clutter_type  1 water/sea, 2 open/rural, 3 suburban, 4 urban, 5 trees/forest, 6 dense urban
%
%   h >= R:                 A_h = 0
%   water/sea, open/rural:  A_h = -K_h2 log10(h/R),  K_h2 = 21.8 + 6.2 log10(f)          (Eqns 2b, 2f)
%   other types:            A_h = J(nu) - 6.03,  nu = K_nu sqrt(h_dif theta_clut),        (Eqns 2a, 2c)
%                           K_nu = 0.342 sqrt(f), h_dif = R - h, theta_clut = atand(h_dif/w_s)
%                           J(nu) = 6.9 + 20 log10(sqrt((nu - 0.1)^2 + 1) + nu - 0.1), J = 0 for nu <= -0.78
%
%   Name-value option error_mode: "error" (default) or "code" (NaN and 32-36).
%
%   Port of src/HeightGainTerminalCorrectionModel.cpp of the NTIA reference
%   implementation (github.com/NTIA/p2108, v1.1), vectorized.
arguments
    f_ghz double
    h_m double
    w_s_m double
    R_m double
    clutter_type double
    opts.error_mode (1,1) string {mustBeMember(opts.error_mode, ["error", "code"])} = "error"
end
c = p2108_constants_rev1();
[f_ghz, h_m, w_s_m, R_m, clutter_type] = p2108_expand_rev1(f_ghz, h_m, w_s_m, R_m, clutter_type);
rtn = zeros(size(f_ghz));
rtn(R_m <= 0) = c.ERROR31_CLUTTER_HEIGHT;               % reverse order: first failing check wins
rtn(w_s_m <= 0) = c.ERROR31_STREET_WIDTH;
rtn(h_m <= 0) = c.ERROR31_ANTENNA_HEIGHT;
rtn(f_ghz < 0.03 | f_ghz > 3) = c.ERROR31_FREQUENCY;
A_h_db = NaN(size(f_ghz));

valid = rtn == c.SUCCESS;
above = valid & h_m >= R_m;
A_h_db(above) = 0;                                      % terminal above the clutter

open_type = valid & ~above & (clutter_type == c.WATER_SEA | clutter_type == c.OPEN_RURAL);
diff_type = valid & ~above & ismember(clutter_type, [c.SUBURBAN c.URBAN c.TREES_FOREST c.DENSE_URBAN]);
bad_type = valid & ~above & ~open_type & ~diff_type;
rtn(bad_type) = c.ERROR31_CLUTTER_TYPE;                 % the reference checks type only below R

K_h2 = 21.8 + 6.2 * log10(f_ghz);                       % Eqn 2f
A_h_db(open_type) = -K_h2(open_type) .* log10(h_m(open_type) ./ R_m(open_type));   % Eqn 2b

h_dif = R_m - h_m;                                      % Eqn 2d
theta_clut = atan(h_dif ./ w_s_m) * 180.0 / pi;         % Eqn 2e
K_nu = 0.342 * sqrt(f_ghz);                             % Eqn 2g
nu = K_nu .* sqrt(h_dif .* theta_clut);                 % Eqn 2c
A_h_db(diff_type) = p2108_equation_2a_rev1(nu(diff_type));
A_h_db(bad_type) = NaN;
p2108_report_rev1(rtn, opts.error_mode, c);
end
