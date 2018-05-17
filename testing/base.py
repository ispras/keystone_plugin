import unittest
from pprint import pprint
import requests

class TestKeystoneBase(unittest.TestCase):
    def setUp(self):
        super(TestKeystoneBase, self).setUp()
        self.host = 'http://localhost:8001'
        # self.host = 'http://10.10.10.10:8001'
        self.domain_id = ''
        self.project_id = ''
        self.user_id = ''
        self.group_id = ''
        self.role_id = ''
        self.headers = {}

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

    def admin_auth(self):
        '''
        Authenticate as admin
        :return:
        '''
        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            'name' : 'admin',
                            'domain' : {
                                'name' : 'Default'
                            },
                            'password' : 'myadminpassword'
                            # 'password': 'tester'
                        }
                    }
                }
            }
        }
        self.res = requests.post(self.host + '/v3/auth/tokens', json = body)
        # pprint(self.res.json())
        self.checkCode(201)
        self.auth_token = self.res.headers['X-Subject-Token']
        self.headers ['X-Auth-Token'] = self.auth_token

    def base_init(self):
        self.res = requests.post(self.host + '/v3', json = {})
        self.checkCode(200)

        ids = self.res.json()
        self.default_domain_id = ids['default_domain_id']
        self.admin_domain_id = ids['admin_domain_id']
        self.admin_project_id_1 = ids['admin_project_id_1'] # from admin domain
        self.admin_project_id_2 = ids['admin_project_id_2'] # from default domain
        self.default_role_id = ids['default_role_id']
        self.admin_role_id = ids['admin_role_id']
        self.admin_user_id_1 = ids['admin_user_id_1'] # from admin domain
        self.admin_user_id_2 = ids['admin_user_id_2'] # from project domain

    def init(self):
        self.base_init()
        self.admin_auth()

        # keystone_ep = "http://localhost:8001/v3/"
        keystone_ep = "http://10.10.10.61:8001/v3/"
        body = {
            "region": {
                "description": "My subregion",
                "id": "RegionOne",
            }
        }
        self.res = requests.post(self.host + '/v3/regions/', json=body, headers=self.headers)
        self.checkCode(201)
        self.region_id = self.res.json()['region']['id']

        body = {
            "service": {
                "type": "identity",
                "name": "keystone",
                "description": "identity service",
                "enabled": True
                # TODO extra
            }
        }
        self.res = requests.post(self.host + '/v3/services/', json=body, headers=self.headers)
        self.checkCode(201)
        self.identity_service_id = self.res.json()['service']['id']

        body = {
            "endpoint": {
                "interface": "internal",
                "region_id": "RegionOne",
                "url": keystone_ep,
                "service_id": self.identity_service_id
            }
        }
        self.res = requests.post(self.host  + '/v3/endpoints/', json=body, headers=self.headers)
        self.checkCode(201)

        body = {
            "endpoint": {
                "interface": "public",
                "region_id": "RegionOne",
                "url": keystone_ep,
                "service_id": self.identity_service_id
            }
        }
        self.res = requests.post(self.host + '/v3/endpoints/', json=body, headers=self.headers)
        self.checkCode(201)

        body = {
            "endpoint": {
                "interface": "admin",
                "region_id": "RegionOne",
                "url": keystone_ep,
                "service_id": self.identity_service_id
            }
        }
        self.res = requests.post(self.host + '/v3/endpoints/', json=body, headers=self.headers)
        self.checkCode(201)

    def rotate_fernet_keys(self):
        self.admin_auth()
        self.res = requests.post(self.host + '/v3/fernet_keys', headers = self.headers)
        self.checkCode(201)

    def clean_devstack(self):
        self.admin_auth()
        user_id = '50cdd695-3508-4ae0-9c4a-f46358197801'
        self.res = requests.delete(self.host + '/v3/users/' + user_id, headers = self.headers)
        self.checkCode(204)
        user_id = 'de0ca469-81ab-4c19-9cc1-1c91995a1739'
        self.res = requests.delete(self.host + '/v3/users/' + user_id, headers = self.headers)
        self.checkCode(204)
        user_id = '431db3f3-ca91-4cc7-a433-ffab6c2751f7'
        self.res = requests.delete(self.host + '/v3/users/' + user_id, headers = self.headers)
        self.checkCode(204)

