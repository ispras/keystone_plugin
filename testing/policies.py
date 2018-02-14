from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystonePolicies(TestKeystoneBase):
    def setUp(self):
        super(TestKeystonePolicies, self).setUp()
        self.url = self.host + '/v3/policies/'
        self.admin_auth()

    def create(self):
        body = {
            "policy": {
                "blob": "{'foobar_user': 'role:compute-user'}",
                "type": "application/json"
            }
        }
        self.res = requests.post(self.url, json = body, headers=self.headers)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.url, headers=self.headers)
        self.checkCode(200)

    def get_info(self):
        policy_id = "6dcd3e06-4457-4818-863c-fba127a6367b"
        self.res = requests.get(self.url + policy_id, headers=self.headers)
        self.checkCode(200)

    def update(self):
        policy_id = "6dcd3e06-4457-4818-863c-fba127a6367b"
        body = {
            "policy": {
                "blob": '{"foobar_user": ["role:compute-user"]}',
                "type": "application/json"
            }
        }
        self.res = requests.patch(self.url + policy_id, json=body, headers=self.headers)
        self.checkCode(200)

    def delete(self):
        policy_id = "6dcd3e06-4457-4818-863c-fba127a6367b"
        self.res = requests.delete(self.url + policy_id, headers=self.headers)
        self.checkCode(204)