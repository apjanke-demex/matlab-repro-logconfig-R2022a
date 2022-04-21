function out = LF
%LF A linefeed ('\n')
%
% This function exists for conciseness, and so that you can use it without
% getting an M-Lint inspection like you do for `sprintf('\n')`.
%
% This always returns an LF ('\n'), not the OS's native line-ending format,
% regardless of what platform it's running on.
%
% Returns a linefeed character as char.
%
% See also:
% NEWLINE

persistent val
if isempty(val)
    val = sprintf('\n'); %#ok<SPRINTFN>
end
out = val;
end