classdef LogConfiguratorLog4j1 < LogConfiguratorBase
    % Configurator for Log4j 1.x

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>

    % Note: use \n instead of '%n' because the Matlab console wants Unix-style line
    % endings, even on Windows.
    properties (Constant)
        ValidLevelNames string = {'OFF' 'FATAL' 'ERROR' 'WARN' 'INFO' 'DEBUG' 'TRACE' 'ALL'};
        % The default "long" appender pattern.
        DefaultLongPattern string = ['log4j: %d{HH:mm:ss.SSS} %-5p %c{1} %x - %m' LF];
        % The default "short" appender pattern.
        DefaultShortPattern string = ['%m' LF];
    end

    methods

        function configureBasicConsoleLogging(obj)
            % Configure log4j for basic console logging.

            % Check if we're already configured, otherwise we'll end up
            % double-printing log messages.
            rootLogger = org.apache.log4j.Logger.getRootLogger();
            rootAppenders = rootLogger.getAllAppenders();
            isConfiguredAlready = rootAppenders.hasMoreElements;
            if ~isConfiguredAlready
                org.apache.log4j.BasicConfigurator.configure();
                rootLogger.setLevel(org.apache.log4j.Level.INFO);

                % Set default pattern.
                % This is something of a hack that relies on
                % some assumptions about the logger tree state.
                pattern = obj.DefaultLongPattern;
                myLayout = org.apache.log4j.PatternLayout(pattern);
                rootAppenders = rootLogger.getAllAppenders();
                while rootAppenders.hasMoreElements()
                    aRootAppender = rootAppenders.nextElement();
                    aRootAppender.setLayout(myLayout);
                end
            end
        end

        function log(obj, logName, level, msg)
            % Emit a log message directly with Log4j 1.
            arguments
                obj LogConfiguratorLog4j1
                logName (1,1) string
                level (1,1) string
                msg string
            end
            import org.apache.log4j.*

            logger = LogManager.getLogger(logName);
            levelJ = obj.getLevel(level);
            logger.log(levelJ, msg);
        end

        function spewHello(obj)
            emit("Here's hello using Log4j 1.x directly:\n\n");
            for levelName = obj.ValidLevelNames
                msg = sprintf('Hello! (level %s)', levelName);
                obj.log('blah', levelName, msg);
            end
            emit("\n");
        end

        function out = getLevel(obj, levelName)
            % Gets the log4j Level enum object for a named level.
            %
            % out = getLog4jLevel(obj, levelName)
            %
            % Returns an org.apache.logging.log4j.Level object.
            arguments
                obj
                levelName (1,1) string
            end
            import org.apache.log4j.*
            levelName = upper(levelName);
            if ~ismember(levelName, obj.ValidLevelNames)
                error('Invalid levelName: ''%s''', levelName);
            end
            out = Level.(levelName);
        end

        function setRootConsoleAppenderPattern(obj, pattern)
            % Set the root logger's console appender's pattern.
            rootAppender = obj.getRootConsoleAppender();
            myLayout = org.apache.log4j.PatternLayout(pattern);
            rootAppender.setLayout(myLayout);
        end

        function setLevels(obj, levels)
            % Set the logging levels for multiple loggers.
            %
            % Levels input argument is an n-by-2 cellstr or string
            % array with logger names in column 1 and level names in column
            % 2.
            for i = 1:size(levels, 1)
                [logName,levelName] = levels{i,:};
                logger = org.apache.log4j.LogManager.getLogger(logName);
                levelObject = obj.getLog4jLevel(levelName);
                logger.setLevel(levelObject);
            end
        end

        function out = getLog4jLevel(obj, levelName)
            % Gets the log4j Level enum object for a named level.
            %
            % out = getLog4jLevel(obj, levelName)
            %
            % Returns an org.apache.log4j.Level object.
            validLevels = {'OFF' 'FATAL' 'ERROR' 'WARN' 'INFO' 'DEBUG' 'TRACE' 'ALL'};
            levelName = upper(levelName);
            if ~ismember(levelName, validLevels)
                error('Invalid levelName: ''%s''', levelName);
            end
            out = org.apache.log4j.Level.(levelName);
        end


        function prettyPrintLogConfiguration(obj, verbose)
            % Displays the current log configuration to the console.
            %
            % prettyPrintLogConfiguration(obj, verbose)
            arguments
                obj
                verbose (1,1) logical = false
            end

            function out = getLevelName(lgr)
                level = lgr.getLevel();
                if isempty(level)
                    out = '';
                else
                    out = char(level.toString());
                end
            end

            % Get all names first so we can display in sorted order
            loggers = org.apache.log4j.LogManager.getCurrentLoggers();
            loggerNames = {};
            while loggers.hasMoreElements()
                logger = loggers.nextElement();
                loggerNames{end+1} = char(logger.getName()); %#ok<AGROW>
            end
            loggerNames = sort(loggerNames);

            % Display the hierarchy
            rootLogger = org.apache.log4j.LogManager.getRootLogger();
            emit('Root (%s): %s\n', char(rootLogger.getName()), getLevelName(rootLogger));
            for i = 1:numel(loggerNames)
                logger = org.apache.log4j.LogManager.getLogger(loggerNames{i});
                appenders = logger.getAllAppenders();
                appenderStrs = {};
                while appenders.hasMoreElements
                    appender = appenders.nextElement();
                    if isa(appender, 'org.apache.log4j.varia.NullAppender')
                        appenderStr = 'NullAppender';
                    else
                        appenderStr = sprintf('%s (%s)', char(appender.toString()), ...
                            char(appender.getName()));
                    end
                    appenderStrs{end+1} = ['appender: ' appenderStr]; %#ok<AGROW>
                end
                appenderList = strjoin(appenderStrs, ' ');
                if ~verbose
                    if isempty(logger.getLevel()) && isempty(appenderList) ...
                            && logger.getAdditivity()
                        continue
                    end
                end
                items = {};
                if ~isempty(getLevelName(logger))
                    items{end+1} = getLevelName(logger); %#ok<AGROW>
                end
                if ~isempty(appenderStr)
                    items{end+1} = appenderList; %#ok<AGROW>
                end
                if ~logger.getAdditivity()
                    items{end+1} = sprintf('additivity=%d', logger.getAdditivity()); %#ok<AGROW>
                end
                str = strjoin(items, ' ');
                emit('%s: %s\n',...
                    loggerNames{i}, str);
            end
        end    end

    methods (Access=private)

        function out = getRootConsoleAppender(obj)
            % Get the console appender on the root logger.
            %
            % If there are multiple console appenders on the root logger, issues
            % a warning (because that's probably a misconfiguration) and returns
            % one of them arbitrarily.
            %
            % Returns a Log4J Java Appender object.
            rootLogger = org.apache.log4j.Logger.getRootLogger();
            appenderList = rootLogger.getAllAppenders();
            found = [];
            foundMultiple = false;
            while appenderList.hasMoreElements
                appender = appenderList.nextElement;
                if isa(appender, 'org.apache.log4j.ConsoleAppender')
                    if isempty(found)
                        found = appender;
                    else
                        foundMultiple = true;
                    end
                end
            end
            if foundMultiple
                warning(['%s: Found multiple ConsoleAppenders on root logger. This '...
                    'is probably a configuration problem.'], mfilename);
            end
            if isempty(found)
                error('No ConsoleAppender found on root logger.');
            end
            out = found;
        end

    end
end