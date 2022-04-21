classdef LogConfigReproForR22A
    % Repro code to demo problems apjanke is having with Matlab R2022a logging
    %
    % Author: Andrew Janke <andrew@apjanke.net>
    %
    % This is an MSCRE (Minimal Self-Contained Running Example) to
    % demonstrate the issues that Andrew is having getting Java logging
    % working properly under Matlab R2022a. The problem seems to be that
    % the log configuration set up using the log4j2 configuration API isn't
    % respected.
    %
    % Example:
    %
    % blah = LogConfigReproForR22A
    % blah.doRepro

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>
    %#ok<*AGROW>

    methods


        function doRepro(obj)
            % Do the whole main repro
            cfgLog4j2 = LogConfiguratorLog4j2;
            cfgLog4j2.configureBasicConsoleLogging;
            cfgLog4j2.spewHello;
        end

    end

end