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


    def init(self):
        body = {
            "domain": {
                "name": "Default",
                "description": "Default domain for testing",
                "enabled":  True
            }
        }
        self.res = requests.post(self.host + '/v3/domains', json = body)

        # if self.res.text != "{\"message\":\"Error: project with this name exists\"}\n":
        self.checkCode(201)
        self.default_domain_id = self.res.json()['domain']['id']
        #
        # # body = {
        # # "project": {
        # #     "description": "Admin project",
        # #     "enabled": True,
        # #     "name": "Admin",
        # #     }
        # # }
        # # self.res = requests.post(self.host + '/v3/projects', json = body)
        # # if self.res.text != "{\"message\":\"Error: project with this name exists\"}\n":
        # #     self.checkCode(201)
        # #     self.project_id = self.res.json()['project']['id']
        # #
        # # self.checkCode(201)
        # # self.default_domain_id = self.res.json()['domain']['id']
        #
        body = {
            "domain": {
                "name": "admin",
                "description": "Admin domain for testing",
                "enabled": True
            }
        }

        # if self.res.text != "{\"message\":\"Error: project with this name exists\"}\n":
        self.res = requests.post(self.host + '/v3/domains', json=body)
        self.checkCode(201)
        self.admin_domain_id = self.res.json()['domain']['id']


        body = {
            "project": {
                "name": "admin",
                "description": "Admin project for testing",
                "enabled": True,
                "is_domain": False,
                "domain_id": self.admin_domain_id
            }
        }
        self.res = requests.post(self.host + '/v3/projects', json=body)
        self.checkCode(201)
        self.admin_project_id = self.res.json()['project']['id']


        body = {
            'role' : {
                'name' : 'Default'
            }
        }
        self.res = requests.post(self.host + '/v3/roles', json = body)

        if self.res.text != "{\"message\":\"Role with specified name already exists in domain\"}\n":
            self.checkCode(201)
            self.default_role_id = self.res.json()['role']['id']

        # # body = {
        # #     'role': {
        # #         'name': 'Admin'
        # #     }
        # # }
        # # self.res = requests.post(self.host + '/v3/roles', json=body)
        # # if self.res.text != "{\"message\":\"Role with specified name already exists in domain\"}\n":
        # #     self.checkCode(201)
        # #     self.role_id = self.res.json()['role']['id']
        #
        # # self.checkCode(201)
        # # self.default_role_id = self.res.json()['role']['id']
        #
        body = {
            'role': {
                'name': 'admin'
            }
        }
        self.res = requests.post(self.host + '/v3/roles', json=body)
        self.checkCode(201)
        self.admin_role_id = self.res.json()['role']['id']

        body = {
            "user": {
                "enabled": "true",
                "name": "admin",
                "password": "myadminpass",
                "domain_id": self.admin_domain_id,
                "default_project_id": self.admin_project_id

            }
        }
        self.res = requests.post(self.host + '/v3/users', json = body)
        #
        # # if self.res.text != "{\"message\":\"Local user with this name is already exists\"}\n":
        # #     self.checkCode(201)
        # #     self.user_id = self.res.json()['user']['id']
        #
        self.checkCode(201)
        self.admin_user_id = self.res.json()['user']['id']

        self.res = requests.put(self.host + '/v3/domains/' + self.admin_domain_id + '/users/'
                                + self.admin_user_id + '/roles/' + self.admin_role_id, json={})  # json object is required
        self.checkCode(204)

        self.res = requests.put(
            self.host + '/v3/projects/' + self.admin_project_id + '/users/' + self.admin_user_id + '/roles/' + self.admin_role_id,
            json={})  # json object is required
        self.checkCode(204)

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

