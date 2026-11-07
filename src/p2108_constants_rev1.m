function c = p2108_constants_rev1()
%P2108_CONSTANTS_REV1 Clutter types, representative heights, and return codes of ITU-R P.2108.
%   c = P2108_CONSTANTS_REV1() returns the enumerations from include/P2108.h
%   of the NTIA reference implementation (github.com/NTIA/p2108, v1.1).
%
%   Clutter types (Table 3 of P.2108):
%     1 water/sea, 2 open/rural, 3 suburban, 4 urban, 5 trees/forest, 6 dense urban
%   Representative clutter heights R (m), default values from Table 3:
%     10, 10, 10, 15, 15, 20
%   Return codes:
%     0 success; 32-36 section 3.1 errors; 48-50 section 3.2 errors; 64-66 section 3.3 errors
persistent cc
if isempty(cc)
    cc.WATER_SEA = 1; cc.OPEN_RURAL = 2; cc.SUBURBAN = 3;
    cc.URBAN = 4; cc.TREES_FOREST = 5; cc.DENSE_URBAN = 6;
    cc.clutter_names = ["water/sea", "open/rural", "suburban", "urban", "trees/forest", "dense urban"];
    cc.R_default_m = [10, 10, 10, 15, 15, 20];

    cc.SUCCESS = 0;
    cc.ERROR31_FREQUENCY = 32;
    cc.ERROR31_ANTENNA_HEIGHT = 33;
    cc.ERROR31_STREET_WIDTH = 34;
    cc.ERROR31_CLUTTER_HEIGHT = 35;
    cc.ERROR31_CLUTTER_TYPE = 36;
    cc.ERROR32_FREQUENCY = 48;
    cc.ERROR32_DISTANCE = 49;
    cc.ERROR32_PERCENTAGE = 50;
    cc.ERROR33_FREQUENCY = 64;
    cc.ERROR33_THETA = 65;
    cc.ERROR33_PERCENTAGE = 66;
    cc.messages = dictionary( ...
        [0 32 33 34 35 36 48 49 50 64 65 66], ...
        ["Successful execution", ...
         "Frequency must be between 0.03 and 3 GHz", ...
         "Antenna height must be > 0 meters", ...
         "Street width must be > 0 meters", ...
         "Representative clutter height must be > 0 meters", ...
         "Invalid value for clutter type", ...
         "Frequency must be between 0.5 and 67 GHz", ...
         "Path distance must be >= 0.25 km", ...
         "Percentage must be between 0 and 100", ...
         "Frequency must be between 10 and 100 GHz", ...
         "Elevation angle must be between 0 and 90 degrees", ...
         "Percentage must be between 0 and 100"]);
end
c = cc;
end
