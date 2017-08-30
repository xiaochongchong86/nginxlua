local utility = require("utility")

local function set_redis(uid, gid_arr)
    local res = ""
    local reqs = {}
    for _, gid in ipairs(gid_arr) do
        local addrs = utility.get_server_from_gid(gid)
        if addrs == nil then
            return nil
        end

        table.insert(reqs, {"/set_redis", {args={ip=addrs[1][1],
                                                 port=addrs[1][2],
                                                 uid=uid,
                                                 gid=gid}}
        });
    end

    for i, resp in ipairs({ngx.location.capture_multi(reqs)}) do
        if resp.status == ngx.HTTP_OK then
            res = res .. resp.body
        else
            return nil
        end
    end
    
    return res
end

ngx.req.read_body()
local post_data = ngx.req.get_body_data()
local uid, gid_arr = utility.extract_req(post_data)
if uid and gid_arr and #gid_arr > 0 then
    local res = set_redis(uid, gid_arr)
    if res then
        hlog(ngx.var["timestamp"] .. post_data .. " " .. res)
        ngx.say(res)
    else
        ngx.status = 500
        hlog(ngx.var["timestamp"] .. post_data .. " 500")
        ngx.say('internal error')
    end
else
    ngx.status = 400
    hlog(ngx.var["timestamp"] .. post_data .. " 400")
    ngx.say('invalid input')
end
