from keystone_plugin.testing.base import TestKeystoneBase
import requests


class TestKeystoneProjects(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneProjects, self).setUp()
        self.url = self.host + '/v3/projects/'

    def create(self):
        body = body = {
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
        project_id = 'test1'
        self.res = requests.get(self.url + project_id)
        self.checkCode(200)

    def update(self):
        project_id = 'ea0341a4-3640-4a27-9be6-fd8a78c5fefb'
        body = {
        "project": {
            "description": "My updated project",
            "name": "myUpdatedProject"
            }
        }
        self.res = requests.patch(self.url + project_id, json=body)
        self.checkCode(200)

    def delete(self):
        project_id =  '03a51cb1-fd22-4282-89a2-8e6b53f88fda'
        self.res = requests.delete(self.url + project_id)
        self.checkCode(204)
