from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneAuthAndTokens(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneAuthAndTokens, self).setUp()
        self.host = self.host + '/v3/auth/'
    def password_unscoped(self):
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            'name' : 'admin',
                            'domain' : {
                                'name' : 'default_domain'
                            },
                            'password' : 'myadminpass'
                        }
                    }
                }
            }
        }
        self.res = requests.post(self.host + 'tokens', json = body)
        self.checkCode(201)

    def get_catalog(self):
        token_id = ''
        headers = {
            "X-Auth_token" : '3482f312-51b1-4383-93d3-7651149074fc'

        }
        self.res = requests.get(self.host + 'catalog', headers=headers)
        self.checkCode(200)

    def get_token(self):
        self.host = self.host + '/v3/auth/tokens'
        token_id = ''
        headers = {
            "X-Auth_token" : "9c06f542-61d3-43ce-8b46-9526c574d8b6",
            "X-Subject-Token": "4e4290aa-e89a-4906-b82e-f012a86616bd"
        }
        self.res = requests.get(self.host)
        self.checkCode(200)
