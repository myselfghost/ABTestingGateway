local _M = {
    _VERSION = '0.01'
}

local ffi = require("ffi")

ffi.cdef[[
struct in_addr {
    uint32_t s_addr;
};

int inet_aton(const char *cp, struct in_addr *inp);
uint32_t ntohl(uint32_t netlong);

char *inet_ntoa(struct in_addr in);
uint32_t htonl(uint32_t hostlong);
]]

local C = ffi.C

local ip2long = function(ip)
    local inp = ffi.new("struct in_addr[1]")
    if C.inet_aton(ip, inp) ~= 0 then
        return tonumber(C.ntohl(inp[0].s_addr))
    end
    return nil
end
local long2ip = function(long)
    if type(long) ~= "number" then
        return nil
    end
    local addr = ffi.new("struct in_addr")
    addr.s_addr = C.htonl(long)
    return ffi.string(C.inet_ntoa(addr))
end

_M.get = function()
    local userinfo = {}
    local IP = ngx.req.get_headers()["X-Forwarded-For"]
	if IP then
	    r,_ = ngx.re.match(IP,"(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9][0-9]?)(.(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])){3}")
		IP = r[0]
	end
    if IP == nil then
            IP  = ngx.req.get_headers()["X-Real-IP"] 
     end
	if IP == nil then
            IP  = ngx.var.remote_addr 
    end
    if IP then 
        IP = ip2long(IP)
        userinfo["ip"] = 'ip'..IP
    end

    local uid = ngx.var.cookie_userid
    if uid then
    	--uid = tonumber(uid)
    	userinfo["uid"] = 'uid'..uid
    end
    
    return userinfo
end

return _M
