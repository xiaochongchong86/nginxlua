local utility = require("utility")

local function check_bloom(uid, gid_arr)
    local res = ""
    local reqs = {}
    for _, gid in ipairs(gid_arr) do
        local addrs = utility.get_server_from_gid(gid)
        if addrs == nil then
            return nil
        end

        table.insert(reqs, {"/check_bloom", {args={ip=addrs[1][1],
                                                   port=addrs[1][2],
                                                   uid=uid,
                                                   gid=gid}}
        });
    end

    for _,resp in ipairs({ngx.location.capture_multi(reqs)}) do
        if resp.status == ngx.HTTP_OK then
            res = res .. resp.body
        else
            res = res .. "1"
        end
    end
    
    return res
end

ngx.req.read_body()
local post_data = ngx.req.get_body_data()
local uid, gid_arr = utility.extract_req(post_data)
if uid and gid_arr and #gid_arr > 0 then
    local res = check_bloom(uid, gid_arr)
    if res then
        ngx.say(res)
    else
        ngx.status = 500
        ngx.say('internal error')
    end
else
    ngx.status = 400
    ngx.say('invalid input')
end
