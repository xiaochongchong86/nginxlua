local sub = string.sub
local byte = string.byte
local tcp = ngx.socket.tcp
local null = ngx.null
local type = type
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local rawget = rawget

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 54)

local mt = { __index = _M }

function _M.new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end

    return setmetatable({_sock = sock}, mt)
end

function _M.set_timeout(self, timeout)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end

function _M.connect(self, ...)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:connect(...)
end

function _M.init_pipeline(self, n)
    self._reqs = new_tab(n or 4, 0)
end

function _M.cancel_pipeline(self)
    self._reqs = nil
end

function _M.commit_pipeline(self)
    local reqs = rawget(self, "_reqs")
    if not reqs then
        return nil, "no pipeline"
    end

    self._reqs = nil

    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    local bytes, err = sock:send(reqs)
    if not bytes then
        return nil, err
    end

    local nvals = 0
    local nreqs = #reqs
    local vals = new_tab(nreqs, 0)
        for i = 1, nreqs do
            local res, err = _read_reply(self, sock)
            if res then
                nvals = nvals + 1
                vals[nvals] = res

            elseif res == nil then
                if err == "timeout" then
                    close(self)
                end
                return nil, err

            else
                -- be a valid redis error value
                nvals = nvals + 1
                vals[nvals] = {false, err}
            end
        end

        return vals
end

function _M.set_keepalive(self, ...)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    if rawget(self, "_subscribed") then
        return nil, "subscribed state"
    end

    return sock:setkeepalive(...)
end

function _M.get_reused_times(self)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end

local function close(self)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:close()
end
_M.close = close


local function _read_reply(self, sock)
    local line, err = sock:receive()
    if not line then
        if err == "timeout" and not rawget(self, "_subscribed") then
            sock:close()
        end
        return nil, err
    end

    return line
end

local function _do_cmd(self, ...)
    local args = {...}

    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    local req = table.concat(args, " ") .. "\n"
    local reqs = rawget(self, "_reqs")
    if reqs then
        reqs[#reqs + 1] = req
        return
    end

    --ngx.say("request:", req)
    local bytes, err = sock:send(req)
    if not bytes then
        return nil, err
    end

    return _read_reply(self, sock)
end

function _M.create(self, filtername)
    local data, err =  _do_cmd(self, "create", filtername)
    if data == nil then
        return nil
    end
    
    if data == "Done" then
        return "1"
    elseif data == "Exists" then
        return "0"
    else
        return nil
    end
end

function _M.set(self, key, field)
    local data, err =  _do_cmd(self, "s", key, field)
    if data == nil then
        return nil, err
    end
    
    if data == "Yes" then
        return "1"
    elseif data == "No" then
        return "0"
    else
        return nil, data
    end
end

function _M.check(self, key, field)
  local data, err =  _do_cmd(self, "c", key, field)
    if data == nil then
        return nil, err
    end

    if data == "Yes" then
        return "1"
    else
        return "0"
    end
end

function _M.drop(self, key)
    local data, err =  _do_cmd(self, "drop", key)
    if data == nil then
        return nil
    end

    if data == "Done" then
        return "1"
    else
        return "0"
    end
end

function _M.bulk(self, ...)
    local data, err =  _do_cmd(self, "b", ...)
    if data == nil then
        return nil
    end

    local res = ""
    for word in string.gmatch(data, "%a+") do 
        if word == "Yes" then
            res = res .. "1"
        else
            res = res .. "0"
        end
    end

    return res
end

function _M.multi(self, ...)
    local data, err =  _do_cmd(self, "m", ...)
    if data == nil then
        return nil
    end

    local res = ""
    for word in string.gmatch(data, "%a+") do 
        if word == "Yes" then
            res = res .. "1"
        else
            res = res .. "0"
        end
    end

    return res
end


setmetatable(_M, {__index = function(self, cmd)
                      local method =
                          function (self, ...)
                              return _do_cmd(self, cmd, ...)
                          end

                      -- cache the lazily generated method in our
                      -- module table
                      _M[cmd] = method
                      return method
end})

return _M
