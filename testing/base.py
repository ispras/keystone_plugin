import unittest
from pprint import pprint
import requests

class TestKeystoneBase(unittest.TestCase):
    def setUp(self):
        super(TestKeystoneBase, self).setUp()
        self.host = 'http://localhost:8001'
        self.domain_id = ''
        self.project_id = ''
        self.user_id = ''
        self.group_id = ''
        self.role_id = ''

    def checkCode(self, code):
        if self.res.status_code != code:
            print("Failed with error:", self.res.reason)
            self.assertEqual(self.res.status_code, code)
    def tearDown(self):
        try:
            pprint(self.res.json())
        except:
            pass
        print()
        p = ['domain_id', 'project_id', 'user_id', 'group_id', 'role_id']
        for k in p:
            if self.__getattribute__(k) != '':
                print('self.' + k + ' = \''+ self.__getattribute__(k) + '\'')

    def auth(self):
        # Authenticate as admin
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            'name' : 'admin',
                            'domain' : {
                                'name' : 'admin'
                            },
                            'password' : 'myadminpassword'
                        }
                    }
                }
            }
        }
        self.res = requests.post(self.host + '/v3/auth/tokens', json = body)
        self.checkCode(201)
        self.auth_token = self.res.headers['X-Subject-Token']

    def init(self):
        self.res = requests.post(self.host + '/v3', json = {})
        self.checkCode(200)

        ids = self.res.json()
        self.default_domain_id = ids['default_domain_id']
        self.admin_domain_id = ids['admin_domain_id']
        self.admin_project_id = ids['admin_project_id']
        self.default_role_id = ids['default_role_id']
        self.admin_role_id = ids['admin_role_id']
        self.admin_user_id = ids['admin_user_id']


        body = {
            "region": {
                "description": "My subregion",
                "id": "RegionOne",
            }
        }
        self.res = requests.post(self.host + '/v3/regions/', json=body)
        self.checkCode(201)
        self.region_id = self.res.json()['region']['id']

        body = {
            "service": {
                "type": "identity",
                "name": "identity",
                "description": "identity service",
                "enabled": True
            }
        }
        self.res = requests.post(self.host + '/v3/services/', json=body)
        self.checkCode(201)
        self.identity_service_id = self.res.json()['service']['id']

        body = {
            "endpoint": {
                "interface": "internal",
                "region_id": "RegionOne",
                "url": "http://localhost:8001/v3/",
                "service_id": self.identity_service_id
            }
        }
        self.res = requests.post(self.host  + '/v3/endpoints/', json=body)
        self.checkCode(201)

        body = {
            "endpoint": {
                "interface": "public",
                "region_id": "RegionOne",
                "url": "http://localhost:8001/v3/",
                "service_id": self.identity_service_id
            }
        }
        self.res = requests.post(self.host + '/v3/endpoints/', json=body)
        self.checkCode(201)

        body = {
            "endpoint": {
                "interface": "admin",
                "region_id": "RegionOne",
                "url": "http://localhost:8001/v3/",
                "service_id": self.identity_service_id
            }
        }
        self.res = requests.post(self.host + '/v3/endpoints/', json=body)
        self.checkCode(201)

