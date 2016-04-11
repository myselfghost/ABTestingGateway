local modulename = "abtestingDiversionIpandUid"

local _M    = {}
local mt    = { __index = _M }
_M._VERSION = "0.0.1"

local ERRORINFO	= require('abtesting.error.errcode').info

local k_ipset      = 'ipset'
local k_uidset      = 'uidset'
local k_upstream    = 'upstream'

_M.new = function(self, database, policyLib)
    if not database then
        error{ERRORINFO.PARAMETER_NONE, 'need avaliable redis db'}
    end if not policyLib then
        error{ERRORINFO.PARAMETER_NONE, 'need avaliable policy lib'}
    end

    self.database = database
    self.policyLib = policyLib
    return setmetatable(self, mt)
end
--	policy is in format as {{{ipset ={ 214214, 23421,12421}, upstream = 'us1'}}
--OR	 policy is in format as {{uidset ={ 214214, 23421,12421}, upstream = 'us2'}}
_M.check = function(self, policy)
    if not next(policy) then
        local info = ERRORINFO.POLICY_INVALID_ERROR
        local desc = 'policy is blank'
        return {false, info, desc}
    end
    for _, v in pairs(policy) do
        local ipset      = v[k_ipset]
        local uidset      = v[k_uidset]
        local upstream  = v[k_upstream]
        if not ( (ipset or uidset) and  upstream) then
            local info = ERRORINFO.POLICY_INVALID_ERROR 
            local desc = ' need '..k_ipset..' or '..k_uidset..' and '..k_upstream
            return {false, info, desc}
        end
        if type(upstream) ~= 'string' then
            local info = ERRORINFO.POLICY_INVALID_ERROR
            local desc = 'upstream invalid'
            return {false, info, desc}
        end
        if ipset then
        for _, ip in pairs(ipset) do 
            if not tonumber(ip) then
                local info = ERRORINFO.POLICY_INVALID_ERROR 
                local desc = 'ip invalid '
                return {false, info, desc}
            end
        end
        end
        if uidset then
        for _, uid in pairs(uidset) do 
            if not tonumber(uid) then
                local info = ERRORINFO.POLICY_INVALID_ERROR 
                local desc = 'uid invalid '
                return {false, info, desc}
            end
        end
        end

    end
    return {true}
end
_M.set = function(self, policy)
    local database  = self.database 
    local policyLib = self.policyLib

    database:init_pipeline()
    for _, v in pairs(policy) do
    	if v[k_ipset] then
    		for _, ip in pairs(v[k_ipset]) do
                database:hset(policyLib, 'ip'..ip, v[k_upstream])
            end
        elseif v[k_uidset] then
        	for _, uid in pairs(v[k_uidset]) do
        	    database:hset(policyLib, 'uid'..uid, v[k_upstream])
        	end
        end
    end
    local ok, err = database:commit_pipeline()
    if not ok then 
        error{ERRORINFO.REDIS_ERROR, err} 
    end

end
_M.get = function(self)
    local database  = self.database 
    local policyLib = self.policyLib

    local data, err = database:hgetall(policyLib)
    if not data then 
        error{ERRORINFO.REDIS_ERROR, err} 
    end

    return data
end
_M.getUpstream = function(self, userinfo)
    if not userinfo["uid"] and not userinfo["ip"] then
        return nil
    end
    local uid = userinfo["uid"]
    local ip = userinfo["ip"]
    local backend, err
    local database, key = self.database, self.policyLib
    if uid then
         backend, err = database:hget(key, uid)
    end
    if not backend and ip then
         backend, err = database:hget(key, ip)
    end
    if not backend then error{ERRORINFO.REDIS_ERROR, err} end
    if backend == ngx.null then backend = nil end
    return backend
end

return _M
