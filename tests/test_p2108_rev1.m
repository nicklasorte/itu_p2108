function tests = test_p2108_rev1
%TEST_P2108_REV1 Tests for the MATLAB port of ITU-R P.2108.
%   Run from the repository root:  results = runtests("tests");
%
%   Evidence used:
%     - NTIA official test vectors (github.com/NTIA/p2108-test-data), 0.1 dB tolerance as in NTIA's own tests.
%     - 1,270 cases from the NTIA C++ reference v1.1 (commit eadb58f), compiled with
%       tools/p2108_reference_driver.cpp, compared at 1e-10 dB.
%     - NTIA unit-test values for Equation 2a.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
tc.TestData.dir = here;
addpath(fullfile(here, '..', 'src'));
end

%% NTIA official test vectors (0.1 dB, as in NTIA's GoogleTest suite)

function test_ntia_vectors_aeronautical(tc)
t = readtable(fullfile(tc.TestData.dir, 'AeronauticalStatisticalModelTestData.csv'));
[L, rtn] = p2108_aeronautical_rev1(t.f__ghz, t.theta_deg, t.p, error_mode="code");
verifyEqual(tc, rtn, t.rtn);
ok = t.rtn == 0;
verifyEqual(tc, L(ok), t.L_ces__db(ok), 'AbsTol', 0.1);
end

function test_ntia_vectors_terrestrial(tc)
t = readtable(fullfile(tc.TestData.dir, 'TerrestrialStatisticalModelTestData.csv'));
[L, rtn] = p2108_terrestrial_rev1(t.f__ghz, t.d__km, t.p, error_mode="code");
verifyEqual(tc, rtn, t.rtn);
ok = t.rtn == 0;
verifyEqual(tc, L(ok), t.L_ctt__db(ok), 'AbsTol', 0.1);
end

function test_ntia_vectors_height_gain(tc)
t = readtable(fullfile(tc.TestData.dir, 'HeightGainTerminalCorrectionModelTestData.csv'));
[A, rtn] = p2108_height_gain_rev1(t.f__ghz, t.h__meter, t.w_s__meter, t.R__meter, ...
    t.clutter_type, error_mode="code");
verifyEqual(tc, rtn, t.rtn);
ok = t.rtn == 0;
verifyEqual(tc, A(ok), t.A_h__db(ok), 'AbsTol', 0.1);
end

%% Bit-level agreement with the compiled NTIA C++ reference

function test_cpp_reference_aeronautical(tc)
t = readtable(fullfile(tc.TestData.dir, 'reference_asm_cpp.csv'));
[L, rtn] = p2108_aeronautical_rev1(t.f__ghz, t.theta__deg, t.p, error_mode="code");
verifyEqual(tc, rtn, t.rtn);
ok = t.rtn == 0;
verifyEqual(tc, L(ok), t.L_ces__db(ok), 'AbsTol', 1e-10);
verifyTrue(tc, all(isnan(L(~ok))));
end

function test_cpp_reference_terrestrial(tc)
t = readtable(fullfile(tc.TestData.dir, 'reference_tsm_cpp.csv'));
[L, rtn] = p2108_terrestrial_rev1(t.f__ghz, t.d__km, t.p, error_mode="code");
verifyEqual(tc, rtn, t.rtn);
ok = t.rtn == 0;
verifyEqual(tc, L(ok), t.L_ctt__db(ok), 'AbsTol', 1e-10);
verifyTrue(tc, all(isnan(L(~ok))));
end

function test_cpp_reference_height_gain(tc)
t = readtable(fullfile(tc.TestData.dir, 'reference_hgt_cpp.csv'));
[A, rtn] = p2108_height_gain_rev1(t.f__ghz, t.h__meter, t.w_s__meter, t.R__meter, ...
    t.clutter_type, error_mode="code");
verifyEqual(tc, rtn, t.rtn);
ok = t.rtn == 0;
verifyEqual(tc, A(ok), t.A_h__db(ok), 'AbsTol', 1e-10);
verifyTrue(tc, all(isnan(A(~ok))));
end

%% Unit values from the NTIA test suite

function test_equation_2a_values(tc)
verifyEqual(tc, p2108_equation_2a_rev1([-0.77 0 1.5]), ...
    [-5.96059383728336638563 0.00285220856360571492 10.75438646420360661479], 'AbsTol', 1e-13);
verifyEqual(tc, p2108_equation_2a_rev1(-0.78), -6.03, 'AbsTol', 1e-15);
end

function test_inv_ccdf(tc)
q = [0.001 0.01 0.1 0.3 0.5 0.7 0.9 0.99 0.999];
exact = sqrt(2) * erfcinv(2 * q);
verifyEqual(tc, p2108_inv_ccdf_rev1(q), exact, 'AbsTol', 4.5e-4);   % A&S 26.2.23 error bound
verifyEqual(tc, p2108_inv_ccdf_rev1(q, "exact"), exact, 'AbsTol', 1e-15);
qs = q(q ~= 0.5);   % at q = 0.5 the approximation returns +/-1.0e-7 depending on the branch
verifyEqual(tc, p2108_inv_ccdf_rev1(1 - qs), -p2108_inv_ccdf_rev1(qs), 'AbsTol', 1e-12);
verifyError(tc, @() p2108_inv_ccdf_rev1(0), 'p2108:outOfRange');
verifyError(tc, @() p2108_inv_ccdf_rev1(1), 'p2108:outOfRange');
end

%% Error handling

function test_error_mode_raises(tc)
verifyError(tc, @() p2108_terrestrial_rev1(0.4, 1, 50), 'p2108:invalidInput');
verifyError(tc, @() p2108_terrestrial_rev1(8, 0.2, 50), 'p2108:invalidInput');
verifyError(tc, @() p2108_aeronautical_rev1(8, 30, 50), 'p2108:invalidInput');
verifyError(tc, @() p2108_aeronautical_rev1(30, 91, 50), 'p2108:invalidInput');
verifyError(tc, @() p2108_height_gain_rev1(1, 5, 27, 15, 7), 'p2108:invalidInput');
verifyError(tc, @() p2108_terrestrial_rev1([1 2], [1 2 3], 50), 'p2108:sizeMismatch');
end

function test_first_failing_check_wins(tc)
% Several invalid inputs at once: the code reflects the first check in NTIA order.
[~, r] = p2108_terrestrial_rev1(0.1, 0.1, 0, error_mode="code");
verifyEqual(tc, r, 48);
[~, r] = p2108_aeronautical_rev1(5, -1, 100, error_mode="code");
verifyEqual(tc, r, 64);
[~, r] = p2108_height_gain_rev1(5, -1, 0, 0, 9, error_mode="code");
verifyEqual(tc, r, 32);
end

function test_height_gain_type_checked_only_below_clutter(tc)
% The reference returns 0 dB and success for an invalid type when h >= R.
[A, r] = p2108_height_gain_rev1(1, 20, 27, 15, 9, error_mode="code");
verifyEqual(tc, [A r], [0 0]);
[A, r] = p2108_height_gain_rev1(1, 5, 27, 15, 9, error_mode="code");
verifyTrue(tc, isnan(A));
verifyEqual(tc, r, 36);
end

%% Vectorization and properties

function test_grid_expansion(tc)
d = (0.25:0.25:5).';
p = [1 10 50 90 99];
L = p2108_terrestrial_rev1(8, d, p);
verifySize(tc, L, [numel(d) numel(p)]);
for k = 1:numel(p)
    verifyEqual(tc, L(:, k), p2108_terrestrial_rev1(8, d, p(k)), 'AbsTol', 1e-12);
end
% N-D input
L3 = p2108_aeronautical_rev1(reshape(10:2:56, 2, 3, 4), 30, 50);
verifySize(tc, L3, [2 3 4]);
end

function test_vectorized_matches_scalar_loop(tc)
s = RandStream('mt19937ar', 'Seed', 2108);
n = 200;
f = 0.5 + 66.5 * rand(s, n, 1); d = 0.25 + 20 * rand(s, n, 1); p = 1 + 98 * rand(s, n, 1);
Lv = p2108_terrestrial_rev1(f, d, p);
Ls = arrayfun(@(a, b, c) p2108_terrestrial_rev1(a, b, c), f, d, p);
verifyEqual(tc, Lv, Ls, 'AbsTol', 0);
end

function test_terrestrial_properties(tc)
d = logspace(log10(0.25), 2, 200).';
p = [1 5 25 50 75 95 99];
L = p2108_terrestrial_rev1(7.9872, d, p);
% L(d) is not monotonic in d at high percentages, so no monotonic-distance check.
verifyGreaterThanOrEqual(tc, diff(L, 1, 2), 0);               % increasing in location percentage
L2 = p2108_terrestrial_rev1(7.9872, 2, p);
verifyLessThanOrEqual(tc, L, repmat(L2, numel(d), 1) + 1e-12);   % Eqn 6: never above the 2 km value
verifyEqual(tc, L(:, 4), sort(L(:, 4)));                           % p = 50: non-decreasing in distance
end

function test_exact_option_small_difference(tc)
d = (0.25:0.25:10).';
p = 1:99;
dL = p2108_terrestrial_rev1(8, d, p, q_inverse="exact") - p2108_terrestrial_rev1(8, d, p);
verifyLessThan(tc, max(abs(dL), [], 'all'), 0.003);
dA = p2108_aeronautical_rev1(30, (0:90).', p, q_inverse="exact") - p2108_aeronautical_rev1(30, (0:90).', p);
verifyLessThan(tc, max(abs(dA), [], 'all'), 0.0003);
end
