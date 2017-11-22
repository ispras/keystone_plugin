from keystone_plugin.testing.base import TestKeystoneBase
import requests


class TestKeystoneProjects(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneProjects, self).setUp()
        self.host = self.host + '/v3/projects/'

    def create(self):
        body = {
        "project": {
            "description": "New project",
            "enabled": True,
            "is_domain": False,
            "name": "admin",
            "domain_id": "db680c6e-d4e1-4a59-af41-8b30ea8dce6d"
            }
        }
        res = requests.post(self.host, json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def list(self):
        query = {
            # 'domain_id' : 'domain_id',
            # 'is_domain': 'true',
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expires_at': 'password_expires_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        res = requests.get(self.host)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def get_info(self):
        project_id = '45f6fc21-e5cf-4f21-9439-8761a2973d98'
        res = requests.get(self.host + project_id)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def update(self):
        project_id = 'ea0341a4-3640-4a27-9be6-fd8a78c5fefb'
        body = {
        "project": {
            "description": "My updated project",
            "name": "myUpdatedProject"
            }
        }
        res = requests.patch(self.host + project_id, json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def delete(self):
        project_id = 'cc207ed2-61e4-4e7b-ab33-6e65acc8f76c'
        res = requests.delete(self.host + project_id)
        self.checkCode(res, 204)
