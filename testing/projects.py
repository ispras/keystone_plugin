from base import TestKeystoneBase
import requests


class TestKeystoneProjects(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneProjects, self).setUp()
        self.url = self.host + '/v3/projects/'
        self.project_id = 'f9c9f2b6-c717-4fec-9dec-f09e7a7e62ad'
        self.admin_auth()

    def create(self):
        body = {
            "project": {
                "name": "new_test",
                "description": "Test project for testing",
                "enabled": True,
                "is_domain": False,
                "domain_id": "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
            }
        }
        self.res = requests.post(self.url, json = body, headers = self.headers)
        self.checkCode(201)

    def list(self):
        query = {
            # 'domain_id' : '14ad23de-d411-4b72-9295-cee25cfaee09'
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expiself.res_at': 'password_expiself.res_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.url, params=query, headers = self.headers)
        self.checkCode(200)

    def get_info(self):
        self.res = requests.get(self.url + self.project_id, headers = self.headers)
        self.checkCode(200)

    def update(self):
        body = {
        "project": {
            "description": "My updated project",
            "name": "myUpdatedProject"
            }
        }
        self.res = requests.patch(self.url + self.project_id, json=body, headers = self.headers)
        self.checkCode(200)

    def delete(self):
        self.res = requests.delete(self.url + self.project_id, headers = self.headers)
        self.checkCode(204)

    def tags(self):
        tag = 'keystone'
        self.res = requests.put(self.url + self.project_id + '/tags/' + tag, json={}, headers = self.headers)
        self.checkCode(201)
        self.res = requests.get(self.url + self.project_id + '/tags/' + tag, headers = self.headers)
        self.checkCode(204)
        self.res = requests.delete(self.url + self.project_id + '/tags/' + tag, headers = self.headers)
        self.checkCode(204)

        body = {
            'tags' : ['keystone', 'admin']
        }
        self.res = requests.put(self.url + self.project_id + '/tags/', json = body, headers = self.headers)
        self.checkCode(200)
        self.res = requests.get(self.url + self.project_id + '/tags/', headers = self.headers)
        self.checkCode(200)
        self.res = requests.delete(self.url + self.project_id + '/tags/', headers = self.headers)
        self.checkCode(204)
