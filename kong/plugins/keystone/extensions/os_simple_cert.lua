local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

local function show_ca_cert(self, dao_factory)

    return 200, [[
    MIIDgTCCAmmgAwIBAgIJAIr3n9+0RSC7MA0GCSqGSIb3DQEBCwUAMFcxCzAJBgNV
BAYTAlVTMQ4wDAYDVQQIDAVVbnNldDEOMAwGA1UEBwwFVW5zZXQxDjAMBgNVBAoM
BVVuc2V0MRgwFgYDVQQDDA93d3cuZXhhbXBsZS5jb20wHhcNMTYxMDIwMTMwMjE4
WhcNMjYxMDE4MTMwMjE4WjBXMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVW5zZXQx
DjAMBgNVBAcMBVVuc2V0MQ4wDAYDVQQKDAVVbnNldDEYMBYGA1UEAwwPd3d3LmV4
YW1wbGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwoJkYpfJ
Bvqfq0eAuqTIziiunNQdnSUX/aMS5UuI6tjzSkYnR5FCdf9UP8OrpA37gthvz3KK
XhNLqnnV8MLzEo3+lN5IAr+TE1foXnqGs6vNvj5Jn1lViXXpIeaHxMwkJpJjPwxJ
nFLtxL1m9hIx5anV5ZyJWV8RIaMqnzOJ7QYiX07aouRvmtT5O1LQzr2ht2l4EzPY
YDt9UV/daSikrmroBnwgWMecaFJOC1pxSyvO2PAnw+yhX6NHgGPJmOu0TSN2IK1p
o07ZVM3QJLLbEZFjcUK7FXNRk5ZfzjkCrJA1l0Ys3ByHTb2offffIyTYPuatQtfF
0XvTIwMN5eIAswIDAQABo1AwTjAMBgNVHRMEBTADAQH/MB0GA1UdDgQWBBTZ4Nls
7DRmUBcrYhYDLSsDM0BCWzAfBgNVHSMEGDAWgBTZ4Nls7DRmUBcrYhYDLSsDM0BC
WzANBgkqhkiG9w0BAQsFAAOCAQEALil6WvVii6yNVwu0zgt2iDYqHvnnHWnSVhEJ
eKeBFRxpuwiH+UOeygFB0/6lD2r11cD0SdgaMfLAKkKspQucJIsp3BYLwBJ25oxn
NL2yB3HLZeEebAQzXQwnRbWUbIpcp/XPlKjybiA3unqE+X/qdQZgxJ2Xgtp7bHhN
yzDCSOUZlHrkKNXtFNvqRtoCeMBs2+jfqx2ap64ORSnLihEi57lOcUn2DbAR45OI
+wppD5CcUTDsE0r+XbBK3Cm3dn6pVyVcawv5qDidRB7JdsDbx6VC7gcBbdgdbLWz
Xf4KS8N77jeGjqKJ7QY5jkHdXhY+gGbeponch4y2VqLgMI0VGQ==]]
end

local function show_signing_cert(self, dao_factory)
    return 200, [[
    MIIDZjCCAk6gAwIBAgIBATANBgkqhkiG9w0BAQsFADBXMQswCQYDVQQGEwJVUzEO
MAwGA1UECAwFVW5zZXQxDjAMBgNVBAcMBVVuc2V0MQ4wDAYDVQQKDAVVbnNldDEY
MBYGA1UEAwwPd3d3LmV4YW1wbGUuY29tMB4XDTE2MTAyMDEzMDIxOFoXDTI2MTAx
ODEzMDIxOFowRzELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVVuc2V0MQ4wDAYDVQQK
DAVVbnNldDEYMBYGA1UEAwwPd3d3LmV4YW1wbGUuY29tMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAua3cVYSD9KY31+wNXZv3HBS5MyzTfoY+nh4nJ2x8
Ram6liu4gkHYRonTUriIrgDLyo+2fuXrmyFcq1+8ke4KD3n24i8pzcrt6BOGAVYP
KdPyXU0EkZECNmH/tKjvVqMLHcq2apsZdZ5ujBtE5G4zbTjVIEzz90AbAmRVJy7S
seluCxBKtg3IGa1WwqgU4B5pgog+VDpT8XPKFvHi1cVaX76qS6MOUxXA7kuOQUct
JxcyITS26Mxym7wOTI+7JV5A9Ow/dUN6CrGMrfHB59Psx3os/BfoopFmIbbnHdOO
ETOeifelkhwLWLfmmOHxWgYYX/aEyW3L/xCU5QDCz9B0wQIDAQABo00wSzAJBgNV
HRMEAjAAMB0GA1UdDgQWBBQeoHzsYSUSfGymk6kem/lpGVJS9DAfBgNVHSMEGDAW
gBTZ4Nls7DRmUBcrYhYDLSsDM0BCWzANBgkqhkiG9w0BAQsFAAOCAQEAfsH6AN7p
XWBg062LUtpfDsRyXqOLYofR4Y0Mzo1rH0jaozJsnOxsj42BdP+hBGjtZB9eUwgP
gx+MJQC4pz+Wuc/xMysDT6f0hyjZmsakXM92lsztlW7+Y7u9ATa2lDTER1Fv7X6D
I+kN+dhphq0lrIRWZvAf3TlZpEUG38cTxLD8OsdOlq4BxSzmvKFQf4mcbu39OX7i
0fGih0SxSa03idx9NWEOEp9IaGLo/mfL84nb4YjgV9yJj+3CkxYvqPlpiM2rHD/C
hMgz/UB52OxbjYjbWoyStZwvlSwKWY75C9iYA04TZrhs5UWvAT+I2Y2UY/krrZ2a
Rke2Bj7NAvXPHw==]]
end

local routes = {
    ['/v3/OS-SIMPLE-CERT/ca'] = {
        GET = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:show_ca_cert")
            responses.send(show_ca_cert(self, dao_factory))
        end
    },
    ['/v3/OS-SIMPLE-CERT/certificate'] = {
        GET = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:show_signing_cert")
            responses.send(show_signing_cert(self, dao_factory))
        end
    }
}

return {
    routes = routes
}