基于动态策略的灰度发布系统
========================
ABTestingGateway 是一个可以动态设置分流策略的灰度发布系统，工作在7层，基于[nginx](http://nginx.org/)和[ngx-lua](https://github.com/openresty/lua-nginx-module)开发，使用 redis 作为分流策略数据库，可以实现动态调度功能。

nginx是目前使用较多的7层服务器，可以实现高性能的转发和响应；ABTestingGateway 是在 nginx 转发的框架内，在转向 upstream 前，根据 用户请求特征 和 系统的分流策略 ，查找出目标upstream，进而实现分流。



在此特别感谢：https://github.com/CNSRE/ABTestingGateway ，详细信息请参看原项目文档。

修改
========================
* 分流功能部分和管理功能部分分开，代码分开部署；
* 添加运行策略时需要传入域名参数；
* 增加策略更新；
* 修改策略删除代码，当存在正在使用该策略的域名时删除策略不成功；
* 增加根据cookie中userid和用户ip分流的模块；


演示说明
========================
说明：以userid和用户ip分流模块为例

* 1设置策略（优先判断cookie的userid）

{
    "divtype": "ipanduid",
    "divdata": [
        {
            "ipset": [
                323225132
            ],
            "upstream": "site2us1"
        },
        {
            "uidset": [
                90500,
                19889
            ],
            "upstream": "site2us2"
        }
    ]
    }
    
* 2设置某个域名运行的策略（需要传入域名）

{
    "domainname": "site2.fenliu.com",
    "policyid": X
     }
     
* 3更新一个已经存在的策略，假如ipset里面存在这个ip就更新，不存在就在这个策略里面新增这个ip

{
    "policyid": x,
    "divdata": [
        {
            "ipset": [
                323225132
            ],
            "upstream": "site2us1"
        },   
    ]
    }
    
* 4删除策略（假如有域名正在使用该策略则删除不成功）

{"policyid": x}