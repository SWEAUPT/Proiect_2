function res = p2_bridge_json(out)
% P2_BRIDGE_JSON The answer of kitten_bridge.py, decoded from its stdout.
%
% stdout may also carry library log lines; the bridge's answer is the last
% line that is a JSON object. Returns [] if there is none.
res = [];
lines = strsplit(strtrim(out), newline);
for k = numel(lines):-1:1
    s = strtrim(lines{k});
    if startsWith(s, '{') && endsWith(s, '}')
        try
            res = jsondecode(s);
            return;
        catch
        end
    end
end
end
