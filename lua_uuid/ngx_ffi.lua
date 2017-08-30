
--[[
    封装ffi 为一个lua模块。
    gen_uuid 生成一个uuid
]]
local _M = { _VERSION = '0.0.1' }
local ffi = require 'ffi'
local ffi_new = ffi.new

ffi.cdef[[
    typedef unsigned char uuid_t[16];
    void uuid_generate(uuid_t out);
    void uuid_unparse(const uuid_t uu, char *out);
    ]]

local uuid_t   = ffi_new("uuid_t")
local uuid_out = ffi_new("char[64]")
local uuid     = ffi.load('libuuid')

function _M.gen_uuid(self)
    if(uuid) then
        uuid.uuid_generate(uuid_t)
        uuid.uuid_unparse(uuid_t, uuid_out)
        return ffi.string(uuid_out)
    end
        return nil
end

return _M
