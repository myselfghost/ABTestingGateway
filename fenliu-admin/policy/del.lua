local runtimeModule = require('abtesting.adapter.runtime')
local policyModule  = require('abtesting.adapter.policy')
local redisModule   = require('abtesting.utils.redis')
local systemConf    = require('abtesting.utils.init')
local handler       = require('abtesting.error.handler').handler
local utils         = require('abtesting.utils.utils')
local ERRORINFO     = require('abtesting.error.errcode').info

local cjson         = require('cjson')
local doresp        = utils.doresp
local dolog         = utils.dolog

local redisConf     = systemConf.redisConf
local divtypes      = systemConf.divtypes
local prefixConf    = systemConf.prefixConf
local policyLib     = prefixConf.policyLibPrefix
local runtimeLib    = prefixConf.runtimeInfoPrefix
--local domain_name   = prefixConf.domainname

local policyID      = ngx.var.arg_policyid

if not policyID then
    local request_body  = ngx.var.request_body
    local postData      = cjson.decode(request_body)
    
    if not request_body then
        -- ERRORCODE.PARAMETER_NONE
        local info = ERRORINFO.PARAMETER_NONE 
        local desc = 'request_body or post data to get policyID'
        local response = doresp(info, desc)
        dolog(info, desc)
        ngx.say(response)
        return
    end
    
    if not postData then
        -- ERRORCODE.PARAMETER_ERROR
        local info = ERRORINFO.PARAMETER_ERROR 
        local desc = 'postData is not a json string'
        local response = doresp(info, desc)
        dolog(info, desc)
        ngx.say(response)
        return
    end
    
    policyID = postData.policyid
    
    if not policyID then
        local info = ERRORINFO.PARAMETER_ERROR 
        local desc = "policyID is needed"
        local response = doresp(info, desc)
        dolog(info, desc)
        ngx.say(response)
        return
    end
    
    policyID = tonumber(postData.policyid)
    
    if not policyID or policyID < 0 then
        local info = ERRORINFO.PARAMETER_TYPE_ERROR 
        local desc = "policyID should be a positive Integer"
        local response = doresp(info, desc)
        dolog(info, desc)
        ngx.say(response)
        return
    end
end

local red = redisModule:new(redisConf)
local ok, err = red:connectdb()
if not ok then
    local info = ERRORINFO.REDIS_CONNECT_ERROR
    local response = doresp(info, err)
    dolog(info, desc)
    ngx.say(response)
    return
end

local pfunc2 = function()
    local runtimeMod = runtimeModule:new(red.redis, runtimeLib) 
    return runtimeMod:getallsitepolicyid()
end

local status, info = xpcall(pfunc2, handler)
if not status then
    local errinfo   = info[1]
    local errstack  = info[2] 
    local err, desc = errinfo[1], errinfo[2]
    local response  = doresp(err, desc)
    dolog(err, desc, nil, errstack)
    ngx.say(response)
    return
end

local runtimeInfo = info
local pfunc3 = function()
    local policyMod = policyModule:new(red.redis, policyLib) 
    return policyMod:ispolicyid(policyID,runtimeInfo)
end

local status, info = xpcall(pfunc3, handler)
if not status then
    local errinfo   = info[1]
    local errstack  = info[2] 
    local err, desc = errinfo[1], errinfo[2]
    local response  = doresp(err, desc)
    dolog(err, desc, nil, errstack)
    ngx.say(response)
    return
end
local isuseing = info

if isuseing then
    local errinfo   = ERRORINFO.UNKNOWN_ERROR
    local desc      = "there is site using the policyid".."--"..isuseing
    local response  = doresp(errinfo, desc)
    dolog(errinfo, desc)
    ngx.say(response)
    return
end

local pfunc = function()
    local policyMod = policyModule:new(red.redis, policyLib) 
    return policyMod:del(policyID)
end

local status, info = xpcall(pfunc, handler)
if not status then
    local errinfo   = info[1]
    local errstack  = info[2] 
    local err, desc = errinfo[1], errinfo[2]
    local response  = doresp(err, desc)
    dolog(err, desc, nil, errstack)
    ngx.say(response)
    return
end

local response = doresp(ERRORINFO.SUCCESS)
ngx.say(response)
