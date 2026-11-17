function todo(id, what)
% TODO Marks a piece of code that you have to write.
%
%   todo('2.1', 'voiced frames, median F0 and its spread in semitones')
%
% Stops execution with a clear message instead of leaving an empty variable
% that fails later with a confusing error. Replace every todo(...) call with
% the code described in the comments above it.
error('Project2:TODO', 'TODO %s not implemented: %s. Read the comments around the call.', ...
    id, what);
end
