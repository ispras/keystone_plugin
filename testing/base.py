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
                print('self.' + k + ' = '+ self.__getattribute__(k))


    def init(self):
        body = {
            "domain": {
                "name": "Default",
                "description": "Default domain for testing",
                "enabled":  True
            }
        }
        self.res = requests.post(self.host + '/v3/domains', json = body)
        if self.res.text != "{\"message\":\"Error: project with this name exists\"}\n":
            self.checkCode(201)
            self.domain_id = self.res.json()['domain']['id']

        body = {
        "project": {
            "description": "Admin project",
            "enabled": True,
            "name": "Admin",
            }
        }
        self.res = requests.post(self.host + '/v3/projects', json = body)
        if self.res.text != "{\"message\":\"Error: project with this name exists\"}\n":
            self.checkCode(201)
            self.project_id = self.res.json()['project']['id']

        body = {
            'role' : {
                'name' : 'Default'
            }
        }
        self.res = requests.post(self.host + '/v3/roles', json = body)
        if self.res.text != "{\"message\":\"Role with specified name already exists in domain\"}\n":
            self.checkCode(201)
            self.role_id = self.res.json()['role']['id']

        body = {
            'role': {
                'name': 'Admin'
            }
        }
        self.res = requests.post(self.host + '/v3/roles', json=body)
        if self.res.text != "{\"message\":\"Role with specified name already exists in domain\"}\n":
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
        if self.res.text != "{\"message\":\"Local user with this name is already exists\"}\n":
            self.checkCode(201)
            self.user_id = self.res.json()['user']['id']
