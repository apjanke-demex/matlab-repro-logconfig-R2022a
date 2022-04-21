function emit(fmt, varargin)
% Output formatted text to standard out (alias for fprintf)
%
% emit(fmt, varargin)
%
% Emit() is just an alias for Matlab's fprintf() function, but with a distinct
% name.
%
% Most library output should be done with <whatever>.log calls, not plain Matlab fprintf()
% calls. Calling emit() is a way of calling Matlab's fprintf() function, but
% indicating that you really meant to do that, instead of calling an <whatever>.log
% function. It is mainly for use inside custom disp() methods in objects, or
% when you're outputing "1...2...3...4..." progress indicators that are all
% supposed to go on one line in the Matlab Command Window, and don't have
% meaningful information that should be captured by our logging.
%
% The name "emit" is different enough from "fprintf" that it won't show up when
% grepping this code base for "fprintf", looking for things that should be
% changed to rma.log files.
%
% If you don't like the name "emit", we can change it to something else, as long
% as it doesn't contain the substring "fprintf". -apjanke
%
% You can also use this for writing to filehandles that point to opened files,
% but that's not its intended use.

fprintf(fmt, varargin{:});

end