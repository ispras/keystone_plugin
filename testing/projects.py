from keystone_plugin.testing.base import TestKeystoneBase
import requests


class TestKeystoneProjects(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneProjects, self).setUp()
        self.url = self.host + '/v3/projects/'
        self.project_id = '899f724c-80ad-456a-a584-040d3748a5b8'

    def create(self):
        body = {
            "project": {
                "name": "admin",
                "description": "Admin project for testing",
                "enabled": True,
                "is_domain": False,
                "domain_id": self.admin_domain_id
            }
        }
        self.res = requests.post(self.url, json = body)
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
        self.res = requests.get(self.url, params=query)
        self.checkCode(200)

    def get_info(self):
        self.res = requests.get(self.url + self.project_id)
        self.checkCode(200)

    def update(self):
        body = {
        "project": {
            "description": "My updated project",
            "name": "myUpdatedProject"
            }
        }
        self.res = requests.patch(self.url + self.project_id, json=body)
        self.checkCode(200)

    def delete(self):
        self.res = requests.delete(self.url + self.project_id)
        self.checkCode(204)

    def tags(self):
        tag = 'keystone'
        self.res = requests.put(self.url + self.project_id + '/tags/' + tag, json={})
        self.checkCode(201)
        self.res = requests.get(self.url + self.project_id + '/tags/' + tag)
        self.checkCode(204)
        self.res = requests.delete(self.url + self.project_id + '/tags/' + tag)
        self.checkCode(204)

        body = {
            'tags' : ['keystone', 'admin']
        }
        self.res = requests.put(self.url + self.project_id + '/tags/', json = body)
        self.checkCode(200)
        self.res = requests.get(self.url + self.project_id + '/tags/')
        self.checkCode(200)
        self.res = requests.delete(self.url + self.project_id + '/tags/')
        self.checkCode(204)
