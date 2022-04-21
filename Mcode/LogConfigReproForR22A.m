classdef LogConfigReproForR22A
    % Repro code to demo problems apjanke is having with Matlab R2022a logging.
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
    % repro = LogConfigReproForR22A
    % repro.doRepro

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>
    %#ok<*AGROW>

    methods


        function doRepro(obj)
            % Do the whole main repro

            ver -support
            emit('\n\n');
            
            cfgLog4j2 = LogConfiguratorLog4j2;
            cfgLog4j2.configureBasicConsoleLogging;
            cfgLog4j2.spewHello;

            cfgLog4j1 = LogConfiguratorLog4j1;
            cfgLog4j1.spewHello;

            slf = LogWithSlf4j;
            slf.spewHello;

            acl = LogWithApacheCommonsLogging;
            acl.spewHello;
        end

    end

end