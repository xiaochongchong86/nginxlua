require("logger")
local os = require("os")

local function determine_idc()
    local hostname = os.getenv("HOSTNAME")
    return string.match(hostname, "%w+.%w+.(%w+).*")
end

local function split_addr(addr)
    local pos = string.find(addr, ":")
    return { string.sub(addr, 1, pos-1), string.sub(addr, pos+1) }
end

local function build_server(server_addr)
    local server = {}
    for i, v in pairs(server_addr) do
        local one_server = {}

        for _, addr in ipairs(v) do
            table.insert(one_server, split_addr(addr))
        end

        server[i] = one_server
    end

    return server
end

gid_server = build_server(require("bloomd_server_" .. determine_idc() .. "_gid"))
dupid_server = build_server(require("bloomd_server_" .. determine_idc() .. "_dupid"))
