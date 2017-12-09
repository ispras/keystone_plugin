from base import TestKeystoneBase
import requests

class TestKeystoneUsers(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneUsers, self).setUp()
        self.url = self.host + '/v3/users/'
        self.user_id = '3daf3fca-d165-4059-a71a-fd1617d9e9cb'
        self.domain_id = '7bba3639-1d1e-4999-9b14-d8392b6a025d'
        self.project_id = '899f724c-80ad-456a-a584-040d3748a5b8'

    def list(self):
        query = {
            # 'domain_id' : 'domain_id',
            'enabled': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expires_at': 'lte:2017-12-08T13:00:00Z',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.url, params = query)
        self.checkCode(200)

    def create_local(self):
        body = {
            "user": {
                "enabled": "true",
                "name": "test_default_project",
                "password": "myadminpass",
                'default_project_id': self.project_id
                # "domain_id": self.domain_id,
            }
        }
        self.res = requests.post(self.url, json = body)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

    def create_nonlocal(self):
        body = {
            "user": {
                "name": "nonloc_user"
            }
        }
        self.res = requests.post(self.url, json = body)
        self.checkCode(201)
        self.user_id = self.res.json()['user']['id']

    def delete(self):
        self.res = requests.delete(self.url + self.user_id)
        self.checkCode(204)

    def get_info(self):
        self.res = requests.get(self.url + self.user_id)
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
        self.res = requests.patch(self.url + self.user_id, json = body)
        self.checkCode(200)

    def list_groups(self):
        self.res = requests.get(self.url + self.user_id + '/groups')
        self.checkCode(200)

    def list_projects(self):
        self.res = requests.get(self.url + self.user_id + '/projects')
        self.checkCode(200)

    def change_password(self):
        body = {
            'user' : {
                'password' : 'new_tester',
                'original_password' : 'tester'
            }
        }
        self.res = requests.post(self.url + '/password', json = body)
        self.checkCode(204)
