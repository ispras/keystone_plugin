from base import TestKeystoneBase
import requests


class TestKeystoneProjects(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneProjects, self).setUp()
        self.url = self.host + '/v3/projects/'

    def create(self):
        body = {
        "project": {
            "description": "Test2 domain",
            "is_domain": False,
            "enabled": True,
            "name": "test2",
            # "domain_id": "33606fac-6309-4b8d-8341-d8218c5c180f"
            }
        }
        self.res = requests.post(self.url, json = body)
        self.checkCode(201)

    def list(self):
        query = {
             'domain_id' : '14ad23de-d411-4b72-9295-cee25cfaee09'
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
        project_id = 'cc207ed2-61e4-4e7b-ab33-6e65acc8f76c'
        self.res = requests.delete(self.url + project_id)
        self.checkCode(204)
