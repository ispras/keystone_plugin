from keystone_plugin.testing.base import TestKeystoneBase
import requests
from pprint import pprint
import uuid

class TestKeystoneUsers(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneUsers, self).setUp()
        self.url = self.host + '/v3/users/'
        self.user_id = '8f5b0cfa-8655-4055-a2e0-71070149c85e'
        self.domain_id = '902f3886-0f59-40f6-baff-768aa8767159'
        self.project_id = 'd99a744b-3a9d-4fc1-85bf-0c6035414ec2'
        self.admin_auth()


    def list(self):
        query = {
            # 'domain_id' : 'domain_id',
            # 'enabled': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expires_at': 'lte:2017-12-08T13:00:00Z',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.url, params = query, headers = self.headers)
        self.checkCode(200)

    def create_local(self):
        body = {
            "user": {
                "enabled": "true",
                "name": "trustee",
                "password": "myadminpass"
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)
        #self.user_id = self.res.json()['user']['id']

    def create_nonlocal(self):
        body = {
            "user": {
                "name": "nonloc_user"
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

    def delete(self):
        self.res = requests.delete(self.url + self.user_id, headers = self.headers)
        self.checkCode(204)

    def get_info(self):
        self.res = requests.get(self.url + self.user_id, headers = self.headers)
        self.checkCode(200)

    def update(self):
        # self.create_nonlocal()
        body = {
            "user" : {
                'enabled': True,
                'name' : 'local_user',
                'password' : 'secret2'
            }
        }
        self.res = requests.patch(self.url + self.user_id, json = body, headers = self.headers)
        self.checkCode(200)

    def list_groups(self):
        self.res = requests.get(self.url + self.user_id + '/groups', headers = self.headers)
        self.checkCode(200)

    def list_projects(self):
        self.res = requests.get(self.url + self.user_id + '/projects', headers = self.headers)
        self.checkCode(200)

    def change_password(self):
        body = {
            'user' : {
                'password' : 'myadminpassword',
                'original_password' : 'myadminpassword'
            }
        }
        self.res = requests.post(self.url + self.user_id + '/password', json = body, headers=self.headers)
        self.checkCode(204)

    def policies(self):
        '''
        create user, authenticate him, check policies for user actions and delete user
        :return:
        '''

        body = {
            "user": {
                "enabled": "true",
                "name": "not_admin",
                "password": "not_admin",
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

        body = {
            'auth' : {
                'identity' : {
                    'methods' : [ 'password' ],
                    'password' : {
                        'user' : {
                            'id' : self.user_id,
                            'password' : 'not_admin'
                        }
                    }
                },
                # 'scope' : {
                #     'domain' : {
                #         'id' : self.domain_id
                #     }
                # }
            }
        }
        self.res = requests.post(self.host + '/v3/auth/tokens', json = body)
        self.checkCode(201)
        self.auth_token = self.res.headers['X-Subject-Token']

        self.headers = {
            'X-Auth-Token' : self.auth_token
        }
        query = {
            'user' : {
                'domain' : {
                    'id' : self.domain_id
                }
            }
        }
        self.res = requests.get(self.url + self.user_id, json = query, headers = self.headers)
        self.checkCode(200)
        # pprint(self.res.json())
        # self.delete()