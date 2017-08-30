local bloom = require("bloomd_client")

local function set_bloom()
    local ip = ngx.var.arg_ip
    local port = ngx.var.arg_port
    local uid = ngx.var.arg_uid
    local gid = ngx.var.arg_gid

    local blm = bloom:new()
    blm:set_timeout(2000) -- 2 sec

    local ok, err = blm:connect(ip, port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect " .. ip .. port .. ", error: " .. err)
        ngx.status = 500
        ngx.print("-1")
        return
    end

    local res, err = blm:set(gid, uid)
    if not res then
        ngx.log(ngx.ERR, "set error: " .. gid .. uid .. err);
        ngx.status = 500
        ngx.print("-2")
        return
    end
    
    ngx.print(res)
    blm:set_keepalive(60000, 64)
end

set_bloom()
