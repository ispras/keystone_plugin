from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneAuthAndTokens(TestKeystoneBase):
    #requires domain, role and user be created in given order

    def setUp(self):
        super(TestKeystoneAuthAndTokens, self).setUp()
        self.url = self.host + '/v3/auth/'
        self.token = ''
        self.user_id = 'ac74734b-c604-4ba4-ba53-b45f88655fee'
        self.password_unscoped()

    def password_unscoped(self):
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            # 'name' : 'admin',
                            # 'domain' : {
                            #     'name' : 'Admin'
                            # },
                            'id' : self.user_id,
                            'password' : 'myadminpassword'
                        }
                    }
                }
            }
        }
        self.res = requests.post(self.url + 'tokens', json = body)
        self.checkCode(201)
        self.auth = self.res.headers['X-Subject-Token']

    def token_scoped(self):
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'token' ],
                    'token' : {
                        'id' : self.auth
                    }
                },
                'scope' : {
                    'domain' : {
                        'name' : 'admin'
                    }
                }
            }
        }
        self.res = requests.post(self.url + 'tokens', json = body)
        self.checkCode(201)
        self.token = self.res.headers['X-Subject-Token']

    def get_catalog(self):
        self.token_scoped()
        headers = {
            "X-Auth-Token" : self.token
        }
        self.res = requests.get(self.url + 'catalog', headers=headers)
        self.checkCode(200)

    def get_token(self):
        self.password_unscoped()
        # self.token_scoped()
        headers = {
            "X-Auth-Token" : 'cf481a8b-645d-4fc3-aecc-5d088abd4341',
            "X-Subject-Token": 'f12effea-fce6-4e56-95c9-f97326e9b210'
        }
        self.res = requests.get(self.url + 'tokens', headers = headers)
        self.checkCode(200)

    def get_scopes(self):
        self.password_unscoped()
        headers = {
            "X-Auth-Token" : self.auth
        }
        self.res = requests.get(self.url + 'domains', headers = headers)
        self.checkCode(200)
