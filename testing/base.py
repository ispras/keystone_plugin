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
            print()
            p = ['domain_id', 'project_id', 'user_id', 'group_id', 'role_id']
            for k in p:
                if self.__getattribute__(k) != '':
                    print('self.' + k + ' = '+ self.__getattribute__(k))
        except:
            pass


    def init(self):
        body = {
            "domain": {
                "name": "Default",
                "description": "Default domain for testing",
                "enabled":  True
            }
        }
        self.res = requests.post(self.host + '/v3/domains', json = body)
        self.checkCode(201)
        self.domain_id = self.res.json()['domain']['id']

        body = {
            'role' : {
                'name' : 'Default'
            }
        }
        self.res = requests.post(self.host + '/v3/roles', json = body)
        self.checkCode(201)
        self.role_id = self.res.json()['role']['id']

        body = {
            "user": {
                "enabled": "true",
                "name": "admin",
                "password": "myadminpass"
            }
        }
        self.res = requests.post(self.host + '/v3/users', json = body)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']
