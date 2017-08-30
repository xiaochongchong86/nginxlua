local redis = require("resty.redis")

local function check_redis()
    local ip = ngx.var.arg_ip
    local port = ngx.var.arg_port
    local uid = ngx.var.arg_uid
    local gid = ngx.var.arg_gid

    local red = redis:new()
    red:set_timeout(2000) -- 2 sec

    local ok, err = red:connect(ip, port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect " .. ip .. port .. ", error: " .. err)
        ngx.status = 500
        ngx.print("-1")
        return
    end

    local res, err = red:bcheck(gid, uid)
    if not res then
        ngx.log(ngx.ERR, "failed to send " .. ip .. port .. ", error: " .. err)
        ngx.status = 500
        ngx.print("-2")
        return
    end

    ngx.print(res)
    red:set_keepalive(60000, 64)
end

check_redis()
