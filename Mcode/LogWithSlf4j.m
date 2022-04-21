classdef LogWithSlf4j < LogConfiguratorBase
    % Interface for SLF4J

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>
    %#ok<*AGROW>

    properties
        ValidLevelNames string = {'ERROR' 'WARN' 'INFO' 'DEBUG' 'TRACE'};
    end

    methods

        function log(obj, logName, level, msg)
            % Emit a log message directly with Log4j 1.
            arguments
                obj LogWithSlf4j
                logName (1,1) string
                level (1,1) string
                msg string
            end
            import org.slf4j.*
            level = upper(level);

            logger = LoggerFactory.getLogger(logName);
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
                    error("Invalid level for SLF4J logging: %s", level)
            end
        end

        function spewHello(obj)
            emit("Here's hello using SLF4J:\n\n");
            for levelName = obj.ValidLevelNames
                msg = sprintf('Hello! (level %s)', levelName);
                obj.log('blah', levelName, msg);
            end
            emit("\n");
        end



    end

end