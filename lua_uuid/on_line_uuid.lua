
--[[
    url参数switch==new 访问新主站，cookie：switch=new 记录24小时
    cookie:switch==new 访问新主站

    guid 不存在生成一个uuid做为guid
    根据guid计算hash值，按100取模
    模小于等于控制比例的用户 访问新主站 并且将guid 记录到 warn 错误日志中
]]
package.path = "/home/s/apps/nginx/conf.d/?.lua"
-- package.path = "/home/s/apps/openresty/nginx/conf.d/?.lua" --10.16.59.212
local ffi = require 'ngx_ffi'

local v2_path   = '/home/s/apps/new_web_v2/public'
--当前项目地址
local curr_path = '/home/s/apps/new_web_v3/public'
--灰度测试项目地址
local gray_path = '/home/s/apps/new_web_gray/public'


local concat    = table.concat
local insert    = table.insert
local on_line_limit = false --是否灰度
local rate = 0 --灰度比例
local guid = ngx.var.cookie___guid
local user_ip   = ngx.var.remote_addr
local host      = ngx.var.http_host
local uri       = ngx.var.uri
local query_str = ngx.var.query_string

if not query_str then
    query_str = ""
end

--生成uuid，并将uuid存入cookie
function genGuidAndSetCookie()
    local tmp_guid  = ffi.gen_uuid()

    local expires   = 86400 * 360  -- 360 day
    ngx.header["Set-Cookie"] = "__guid="..tmp_guid.."; Path=/;domain=.yourdomain.com;Expires=" .. ngx.cookie_time(ngx.time() + expires)

    local header_ck = ngx.req.get_headers()['cookie']
    if not header_ck then
        ngx.req.set_header("Cookie", "__guid="..tmp_guid)
    else
        ngx.req.set_header("Cookie", "__guid="..tmp_guid..";"..header_ck)
    end
    return tmp_guid
end

function log(ver)
    local log_info  = {}
    insert(log_info,ver)
    insert(log_info,guid)
    insert(log_info,user_ip)
    local log_str = concat(log_info,",")
    ngx.log(ngx.WARN,log_str)
end

if(not guid) then
    guid = genGuidAndSetCookie()
end

local arg_from  = ngx.var.arg_from

--[[
--uri中from==mini参数时返回新站。
--uri中from==browser参数时返回新站。
local is_browser    = arg_from == 'browser'
local is_mini       = arg_from == 'mini'
local is_browser404 = arg_from == 'browser404'
local is_so         = arg_from == 'so'
local is_soresult   = arg_from == 'soresult'
local is_hao_guess  = arg_from == 'hao_guess'
local is_haoindex   = arg_from == 'haoindex'
local is_hao        = arg_from == 'hao'
local is_hao_keji      = arg_from == 'hao_keji'
local is_hao_junshi    = arg_from == 'hao_junshi'
local is_hao_qiche     = arg_from == 'hao_qiche'
local is_hao_fangchan  = arg_from == 'hao_fangchan'
local is_hao_shenghuo  = arg_from == 'hao_shenghuo'
local is_hao_licai     = arg_from == 'hao_licai'

if (is_browser or is_mini or is_browser404 or is_so or is_soresult or is_hao_guess or is_haoindex or is_hao or is_hao_keji or is_hao_junshi or is_hao_qiche or is_hao_fangchan or is_hao_shenghuo or is_hao_licai) then
    log('from_'..arg_from)
    return v2_path
end
]]

--uri中switch==new参数时返回新站。
local arg_switch = ngx.var.arg_switch
if (arg_switch == 'new') then
    local expires   = 86400  -- 1 day
    ngx.header["Set-Cookie"] = "switch=new; Path=/;domain=.yourdomain.com;Expires=" .. ngx.cookie_time(ngx.time() + expires)
    log('test_new')
    return gray_path
end

--uri中switch==old参数时返回老站。
if (arg_switch == 'old') then
    local expires   = 86400  -- 1 day
    ngx.header["Set-Cookie"] = "switch=old; Path=/;domain=.yourdomain.com;Expires=" .. ngx.cookie_time(ngx.time() + expires)
    log('test_old')
    return curr_path
end

--cookie中switch==new参数直接返回新站
local ck_switch = ngx.var.cookie_switch
if(ck_switch == 'new') then
    log('test_new')
    return gray_path
end

--cookie中switch==old参数直接返回老站
if (ck_switch == 'old') then
    log('test_old')
    return curr_path
end

--启用灰度上线并且guid不为nil，做取模操作
if (on_line_limit and guid )then
    local mod  = math.mod(ngx.crc32_short(guid),100)
    if(mod < rate) then
        --将guid写入warn日志
        log('new_web_gray')
        return gray_path
    end
end
log('new_web_curr')
return curr_path

