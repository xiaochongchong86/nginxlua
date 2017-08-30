local bit = require "bit"
local ffi = require "ffi"
local os = require "os"

ffi.cdef[[
int write(int fd,const char *buf,int nbyte);
int open(const char* path,int access,int mode);
int close(int fd);
]]

local O_RDWR = 0x0002
local O_CREAT = 0x0040
local O_APPEND = 0x0400
local O_SYNC = 0x101000
local S_IRWXU = 0x01C0
local S_IRGRP = 0x0020
local S_IROTH = 0x0004

local function get_log_file_name()
	return "./logs/browse_history.log." .. os.date("%Y%m%d", os.time())
end

g_curr_day = -1
g_log_count = 0
g_log_fd = ffi.C.open(get_log_file_name(), bit.bor(O_RDWR,O_CREAT,O_APPEND), bit.bor(S_IRWXU,S_IRGRP,S_IROTH))

local function check_rolling()
    if g_log_count == 100000 then
        local curr_day = tonumber(os.date("%d"))
        if curr_day ~= g_curr_day then
            ffi.C.close(g_log_fd)
            g_log_fd = ffi.C.open(get_log_file_name(), bit.bor(O_RDWR,O_CREAT,O_APPEND), bit.bor(S_IRWXU,S_IRGRP,S_IROTH))
            g_curr_day = curr_day
        end
        g_log_count = 0
    else
        g_log_count = g_log_count + 1
    end
end

function hlog(content)
    check_rolling()
    content = content .. '\n'
    ffi.C.write(g_log_fd, content, #content)
end
