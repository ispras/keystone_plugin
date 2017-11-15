from base import TestKeystoneBase
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
            "name": "NewProject3"
            }
        }
        res = requests.post(self.host, json = body)
        self.checkCode(res, 201)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def list(self):
        res = requests.get(self.host)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def get_info(self):
        project_id = 'ea0341a4-3640-4a27-9be6-fd8a78c5fefb'
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
