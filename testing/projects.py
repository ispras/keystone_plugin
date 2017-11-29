from keystone_plugin.testing.base import TestKeystoneBase
import requests


class TestKeystoneProjects(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneProjects, self).setUp()
        self.host = self.host + '/v3/projects/'

    def create(self):
        body = {
        "project": {
            "description": "New admin project",
            "enabled": True,
            "is_domain": False,
            "name": "admin",
            "domain_id": "ffb8809c-e262-4703-b1ba-8af5c9f8a134"
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)

    def list(self):
        query = {
            # 'domain_id' : 'domain_id',
            # 'is_domain': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expiself.res_at': 'password_expiself.res_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        project_id = 'Default'
        self.res = requests.get(self.host + project_id)
        self.checkCode(200)

    def update(self):
        project_id = 'ea0341a4-3640-4a27-9be6-fd8a78c5fefb'
        body = {
        "project": {
            "description": "My updated project",
            "name": "myUpdatedProject"
            }
        }
        self.res = requests.patch(self.host + project_id, json=body)
        self.checkCode(200)

    def delete(self):
        project_id = 'cc207ed2-61e4-4e7b-ab33-6e65acc8f76c'
        self.res = requests.delete(self.host + project_id)
        self.checkCode(204)
