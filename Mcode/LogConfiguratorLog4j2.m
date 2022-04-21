classdef LogConfiguratorLog4j2 < LogConfiguratorBase
    % Configurator for Log4j 2.x

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>
    %#ok<*AGROW>

    % Note: use \n instead of '%n' because the Matlab console wants Unix-style line
    % endings, even on Windows.
    properties (Constant)
        ValidLevelNames string = {'OFF' 'FATAL' 'ERROR' 'WARN' 'INFO' 'DEBUG' 'TRACE' 'ALL'};
        % The default "long" appender pattern.
        DefaultLongPattern string = ['%d{HH:mm:ss.SSS} %-5p %c{1} %x - %m' LF];
        % The default "short" appender pattern.
        DefaultShortPattern string = ['%m' LF];
    end

    methods

        function configureBasicConsoleLogging(obj)
            % Configure log4j for basic console logging.
            %
            % This will reset some of the configuration (level and format
            % on the root logger) if you call it again after logging is
            % already configured.

            % Matlab R2022a switched to Log4j 2.x. It comes with the
            % log4j-1.2 bridge, but that doesn't work for everything,
            % including configuration. So configure it using the Log4j
            % 2 API.

            logCtx = org.apache.logging.log4j.core.LoggerContext.getContext();

            newCfg = obj.buildNewLogConfiguration;
            emit('My hand-built LogConfiguration:\n');
            obj.prettyPrintLogConfigurationFromLogConfig(newCfg);
            emit('\n');

            % This doesn't work.
            %newLogCtx = org.apache.logging.log4j.core.config.Configurator.initialize(newCfg);
            % Maybe this'll work?
            org.apache.logging.log4j.core.config.Configurator.reconfigure(newCfg);
            obj.updateLoggers;

            emit('Log configuration after reconfigure():\n');
            obj.prettyPrintLogConfiguration;
            emit('\n');
        end

        function spewHello(obj)
            emit("Here's hello using Log4j 2.x directly:\n");
            for levelName = obj.ValidLevelNames
                msg = sprintf('Hello! (level %s)', levelName);
                obj.log('blah', levelName, msg);
            end
            emit("\n");
        end

        function log(obj, logName, level, msg)
            % Emit a log message directly with Log4j 2.
            arguments
                obj LogConfiguratorLog4j2
                logName (1,1) string
                level (1,1) string
                msg string
            end
            import org.apache.logging.log4j.*

            logger = LogManager.getLogger(logName);
            levelJ = obj.getLevel(level);
            logger.log(levelJ, msg);
        end

        function out = buildNewLogConfiguration(obj)
            import org.apache.logging.log4j.*
            import org.apache.logging.log4j.core.appender.ConsoleAppender
            cfgBld = org.apache.logging.log4j.core.config.builder.api.ConfigurationBuilderFactory.newConfigurationBuilder();
            cfgBld.setConfigurationName('repro-log4j-config');
            cfgBld.setStatusLevel(Level.INFO);
            appenderBld = cfgBld.newAppender('stdout', 'CONSOLE');
            appenderBld.addAttribute('target', obj.getConsoleTargetEnum('SYSTEM_OUT'));
            myPattern = obj.DefaultShortPattern;
            appenderBld.add(cfgBld.newLayout('PatternLayout').addAttribute('pattern', myPattern));
            cfgBld.add(appenderBld);
            rootLoggerBld = cfgBld.newRootLogger(Level.INFO);
            rootLoggerBld.add(cfgBld.newAppenderRef('stdout'));
            cfgBld.add(rootLoggerBld);
            out = cfgBld.build();
        end

        function out = getConsoleTargetEnum(obj, name)
            % Get a named Java ConsoleAppender.Target enum value.
            klassName = 'org.apache.logging.log4j.core.appender.ConsoleAppender';
            klass = obj.javaGetNestedClassClass(klassName, 'Target');
            out = obj.javaGetEnumConstantByName(klass, name);
        end

        function setRootConsoleAppenderPattern(obj, pattern)
            % Set the root logger's console appenders' pattern.
            %
            % This is a HACK that replaces the ConsoleAppenders on the root
            % loggers with new ones that use layouts with the given
            % pattern.
            layoutBuilder = org.apache.logging.log4j.core.layout.PatternLayout.newBuilder();
            layoutBuilder.withPattern(pattern);
            myLayout = layoutBuilder.build();
            rootLogger = org.apache.logging.log4j.LogManager.getRootLogger();
            rootAppenders = rootLogger.getAppenders().values();
            rootAppsIt = rootAppenders.iterator();
            while rootAppsIt.hasNext()
                rootAppender = rootAppsIt.next();
                rootLogger.removeAppender(rootAppender);
            end
            appenderBuilder = org.apache.logging.log4j.core.appender.ConsoleAppender.newBuilder();
            appenderBuilder = appenderBuilder.withLayout(myLayout).withName('DefaultConsole-42');
            newRootAppender = appenderBuilder.build;
            rootLogger.addAppender(newRootAppender);
            obj.updateLoggers;
        end


        function setLevels(obj, levels)
            % Set the logging levels for multiple loggers.
            %
            % setLevels(obj, levels)
            %
            % Levels input argument is an n-by-2 cellstr or string
            % array with logger names in column 1 and level names in column
            % 2.
            arguments
                obj
                levels (:,2) string
            end
            import org.apache.logging.log4j.*
            import org.apache.logging.log4j.core.config.LoggerConfig

            logCtx = org.apache.logging.log4j.core.LoggerContext.getContext();
            logCfg = logCtx.getConfiguration();

            rootLoggerNames = ["", "/"];
            for i = 1:size(levels, 1)
                logName = levels(i, 1);
                levelName = levels(i, 2);
                levelJObject = obj.getLevel(levelName);
                if ismember(logName, rootLoggerNames)
                    loggerCfg = logCfg.getRootLogger();
                else
                    loggerCfg = logCfg.getLoggerConfig(logName);
                    gotLogName = string(loggerCfg.getName());
                    if gotLogName ~= logName
                        % We got a parent logger cfg instead. Vivify a cfg
                        % at exactly the requested level.
                        parentLoggerCfg = loggerCfg; %#ok<NASGU>
                        % cfgBld = org.apache.logging.log4j.core.config.builder.api.ConfigurationBuilderFactory.newConfigurationBuilder();
                        % loggerBld = cfgBld.newLogger(logName);
                        % loggerCfgComponent = loggerBld.build();
                        emptyAppJArray = javaArray('org.apache.logging.log4j.core.config.AppenderRef', 0);
                        loggerCfg = LoggerConfig.createLogger(false, levelJObject, ...
                            logName, "com", emptyAppJArray, ...
                            org.apache.logging.log4j.core.config.Property.EMPTY_ARRAY, ...
                            logCfg, []);
                        logCfg.addLogger(logName, loggerCfg);
                    end
                end
                loggerCfg.setLevel(levelJObject);
            end
            % Needed?
            % org.apache.logging.log4j.core.config.Configurator.reconfigure(logCfg);
            obj.updateLoggers;
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
            levelName = upper(levelName);
            if ~ismember(levelName, obj.ValidLevelNames)
                error('Invalid levelName: ''%s''', levelName);
            end
            out = org.apache.logging.log4j.Level.(levelName);
        end

        function prettyPrintLogConfiguration(obj, verbose)
            % Displays the current log configuration to the console.
            %
            % prettyPrintLogConfiguration(obj, verbose)
            arguments
                obj
                verbose (1,1) logical = false
            end

            emit('\n');
            obj.prettyPrintLogConfigurationFromCurrentLogConfig;
            emit('\n');
            obj.prettyPrintLogConfigurationFromLoggers;
            emit('\n');
        end

        function prettyPrintLogConfigurationFromLoggers(obj, verbose)
            arguments
                obj
                verbose (1,1) logical = false
            end
            emit('Logger state:\n');

            function out = getLevelName(aLogger)
                level = aLogger.getLevel();
                if isempty(level)
                    out = '';
                else
                    out = char(level.toString());
                end
            end

            % Get all names first so we can display in sorted order
            logCtx = org.apache.logging.log4j.core.LoggerContext.getContext;
            loggers = logCtx.getLoggers;
            loggerNames = {};
            it = loggers.iterator;
            while it.hasNext
                logger = it.next;
                loggerNames{end+1} = char(logger.getName());
            end
            loggerNames = sort(loggerNames);

            % Display the hierarchy
            rootLogger = org.apache.logging.log4j.LogManager.getRootLogger();
            emit('Root (%s): %s\n', char(rootLogger.getName()), getLevelName(rootLogger));
            for i = 1:numel(loggerNames)
                loggerName = loggerNames{i};
                if strcmp(loggerName, '')
                    continue
                end
                logger = org.apache.logging.log4j.LogManager.getLogger(loggerName);
                appenders = logger.getAppenders().values();
                appenderStrs = {};
                itAppenders = appenders.iterator();
                while itAppenders.hasNext
                    appender = itAppenders.next();
                    if isa(appender, 'org.apache.logging.log4j.varia.NullAppender')
                        appenderStr = 'NullAppender';
                    else
                        appenderStr = sprintf('%s (%s)', char(appender.toString()), ...
                            char(appender.getName()));
                    end
                    appenderStrs{end+1} = ['appender: ' appenderStr];
                end
                appenderList = strjoin(appenderStrs, ' ');
                if ~verbose
                    if isempty(logger.getLevel()) && isempty(appenderList) ...
                            && logger.getAdditivity()
                        continue
                    end
                end
                items = {};
                levelName = getLevelName(logger);
                if ~isempty(levelName)
                    items{end+1} = levelName;
                end
                if ~isempty(appenderStr)
                    items{end+1} = appenderList;
                end
                loggerDescrStr = strjoin(items, ' ');
                emit('%s: %s\n', loggerName, loggerDescrStr);
            end
        end

        function prettyPrintLogConfigurationFromLogConfig(obj, logCfg, verbose)
            arguments
                obj
                logCfg
                verbose (1,1) logical = false
            end
            emit('%s: %s, configurationSource=%s\n', ...
                logCfg.getClass.getSimpleName, logCfg.getClass.getName, ...
                logCfg.getConfigurationSource.toString);
            loggerCfgMap = logCfg.getLoggers();
            loggerNames = string(obj.javaCollection2MatlabCellArray(loggerCfgMap.keySet()));
            loggerNames = sort(loggerNames);
            % emit('All logger names: %s\n', strjoin(loggerNames, ', '));
            emit('Loggers:\n');
            if isempty(loggerNames)
                emit('  <No loggers found.>\n');
            end
            for i = 1:numel(loggerNames)
                loggerName = loggerNames(i);
                if loggerName == ""
                    loggerDispName = "<root>";
                else
                    loggerDispName = loggerName;
                end
                loggerCfg = logCfg.getLoggerConfig(loggerName);
                levelJ = loggerCfg.getLevel();
                emit('  %s: level=%s additive=%d\n', ...
                    loggerDispName, levelJ.toString(), loggerCfg.isAdditive());
                appRefs = obj.javaCollection2MatlabCellArray(loggerCfg.getAppenderRefs());
                if ~isempty(appRefs)
                    appRefNames = cellfun(@(x) string(x.toString()), appRefs);
                    emit('      AppenderRefs: %s\n', strjoin(appRefNames, ', '));
                end
            end
            emit('Appenders:\n');
            appenderMap = logCfg.getAppenders();
            appenderNames = string(obj.javaCollection2MatlabCellArray(appenderMap.keySet()));
            if isempty(appenderNames)
                emit('  <No appenders found.>\n');
            end
            for appenderName = appenderNames
                appenderCfg = logCfg.getAppender(appenderName);
                emit('  %s: %s\n', appenderName, appenderCfg.toString());
            end

            emit('(Not fully implemented yet.)\n');
        end

        function prettyPrintLogConfigurationFromCurrentLogConfig(obj, verbose)
            arguments
                obj
                verbose (1,1) logical = false
            end
            emit('Logger config state:\n');
            logCtx = org.apache.logging.log4j.core.LoggerContext.getContext();
            logCfg = logCtx.getConfiguration();
            obj.prettyPrintLogConfigurationFromLogConfig(logCfg, verbose);
        end


        function updateLoggers(obj)
            logCtx = org.apache.logging.log4j.core.LoggerContext.getContext();
            logCtx.updateLoggers();
        end


        function out = javaGetNestedClassClass(obj, mainClassName, nestedClassName)
            % Get the Java Class definition for a nested class.
            fqNestedClassName = [mainClassName '$' nestedClassName];
            out = org.example.matlablogrepro.Reflection.classForName(fqNestedClassName);
        end

        function out = javaGetNestedClassInstance(obj, mainClassName, nestedClassName)
            % Create a new instance of a Java nested class.
            nestedClass = obj.javaGetNestedClassClass(mainClassName, nestedClassName);
            out = nestedClass.newInstance();
        end

        function out = javaGetEnumConstantByName(obj, javaClass, enumName)
            arguments
                obj
                javaClass
                enumName (1,1) string
            end
            enums = javaClass.getEnumConstants();
            for i = 1:numel(enums)
                en = enums(i);
                if string(en.name) == enumName
                    out = en;
                    return
                end
            end
            error('No enum named %s found on class %s', ...
                enumName, javaClass.getCanonicalName);
        end


        function out = javaCollection2MatlabCellArray(obj, jcoll)
            out = cell([1, jcoll.size()]);
            i = 1;
            it = jcoll.iterator();
            while it.hasNext()
                jval = it.next();
                if isa(jval, 'java.lang.String')
                    val = char(jval);
                else
                    val = jval;
                end
                out{i} = val;
                i = i + 1;
            end
        end

    end

end


