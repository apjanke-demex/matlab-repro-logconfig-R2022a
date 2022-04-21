classdef LogConfigMagicInitializer
    % Magic library initializer class.
    %
    % This class is just a trick to ensure library-level initialization happens
    % automatically.

    %#ok<*MANU>
    %#ok<*INUSL>
    %#ok<*INUSA>
    %#ok<*AGROW>

    methods

        function obj = LogConfigMagicInitializer
            initLibrary(obj);
        end

        function initLibrary(obj)
            myDir = fileparts(mfilename('fullpath'));
            jarFile = fullfile(myDir, 'untitled.jar');
            javaaddpath(jarFile);
        end


    end

end