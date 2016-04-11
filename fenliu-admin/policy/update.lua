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

local request_body  = ngx.var.request_body
local postData      = cjson.decode(request_body)

if not request_body then
    -- ERRORCODE.PARAMETER_NONE
    local errinfo	 = ERRORINFO.PARAMETER_NONE
    local desc		 = 'request_body or post data'
    local response	 = doresp(errinfo, desc)
    dolog(errinfo, desc)
    ngx.say(response)
    return
end

if not postData then
    -- ERRORCODE.PARAMETER_ERROR
    local errinfo	= ERRORINFO.PARAMETER_ERROR 
    local desc		= 'postData is not a json string'
    local response	= doresp(errinfo, desc)
    dolog(errinfo, desc)
    ngx.say(response)
    return
end

local policyid = postData.policyid
local divtype 
local divdata = postData.divdata

if  not divdata or not policyid then
    -- ERRORCODE.PARAMETER_NONE
    local errinfo   = ERRORINFO.PARAMETER_NONE 
    local desc      = " policy divdata or policyid"
    local response  = doresp(errinfo, desc)
    dolog(errinfo, desc)
    ngx.say(response)
    return
end

local policy   = postData

local red = redisModule:new(redisConf)
local ok, err = red:connectdb()
if not ok then
    -- ERRORCODE.REDIS_CONNECT_ERROR
    -- connect to redis error
    local errinfo   = ERRORINFO.REDIS_CONNECT_ERROR
    local response  = doresp(errinfo, err)
    dolog(errinfo, err)
    ngx.say(response)
    return
end

local policyMod

local pfunc2 = function()
    policyMod = policyModule:new(red.redis, policyLib) 
    return policyMod:checkpolicyid(policyid) 
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


if not info then
    data = ' the id of  policy is not found '
    local response = doresp(ERRORINFO.SUCCESS, data)
    ngx.say(response)
    return
end
divtype = info
policy.divtype = divtype


local pfunc = function() 
    return policyMod:check(policy)
end

local status, info = xpcall(pfunc, handler)
if not status then
    local errinfo  = info[1]
    local errstack = info[2] 
    local err, desc = errinfo[1], errinfo[2]
    local response  = doresp(err, desc)
    dolog(err, desc, nil, errstack)
    ngx.say(response)
    return
end

local chkout    = info
local valid     = chkout[1]
local err       = chkout[2]
local desc      = chkout[3]

if not valid then
    dolog(err, desc)
    local response = doresp(err, desc)
    ngx.say(response)
    return
end

local pfunc3 = function() return policyMod:update(policy) end
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

local pfunc4 = function()
    local policyIO = policyModule:new(red.redis, policyLib) 
    return policyIO:get(policyid)
end

local status, info = xpcall(pfunc4, handler)
if not status then
    local errinfo   = info[1]
    local errstack  = info[2] 
    local err, desc = errinfo[1], errinfo[2]
    local response  = doresp(err, desc)
    dolog(err, desc, nil, errstack)
    ngx.say(response)
    return
else
    local response = doresp(ERRORINFO.SUCCESS, nil, info)
    dolog(ERRORINFO.SUCCESS, nil)
    ngx.say(response)
end
