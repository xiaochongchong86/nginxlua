module("utility", package.seeall)
local cjson = require("cjson")

function extract_req(post_data)
    if post_data then
        local status, json = pcall(cjson.decode, post_data)        
        if status and type(json["gid"]) == "table" and type(json["uid"]) == "string" then
            return json["uid"], json["gid"]
        else
            return nil, nil
        end
    else
        return nil, nil
    end
end

function get_server_from_gid(gid)
    if #gid == 27 then
        return gid_server[gid:sub(27, 27)]
    else
        return dupid_server[gid:sub(-1, -1)]
    end
end
