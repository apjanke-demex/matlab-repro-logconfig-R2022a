classdef LogWithApacheCommonsLogging < LogConfiguratorBase
    % Interface for Apache Commons Logging logging.

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>
    %#ok<*AGROW>

    properties
        ValidLevelNames string = {'FATAL', 'ERROR' 'WARN' 'INFO' 'DEBUG' 'TRACE'};
        SafeLevelNames string = {'ERROR' 'WARN' 'INFO' 'DEBUG' 'TRACE'};
    end

    methods

        function log(obj, logName, level, msg)
            % Emit a log message through Commons Logging.
            arguments
                obj LogWithApacheCommonsLogging
                logName (1,1) string
                level (1,1) string
                msg string
            end
            import org.apache.commons.logging.*

            logger = LogFactory.getLog(logName);
            switch level
                case "ERROR"
                    logger.error(msg);
                case "WARN"
                    logger.warn(msg);
                case "INFO"
                    logger.info(msg);
                case "DEBUG"
                    logger.debug(msg);
                case "TRACE"
                    logger.trace(msg);
                otherwise
                    error("Invalid level for Apache Commons Logging logging: %s", level)
            end

        end

        function spewHello(obj)
            emit("Here's hello using Apache Commons Logging:\n\n");
            for levelName = obj.SafeLevelNames
                msg = sprintf('Hello! (level %s)', levelName);
                obj.log('blah', levelName, msg);
            end
            emit("\n");
        end

    end

end
