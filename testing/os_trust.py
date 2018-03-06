from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOsTrust(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneOsTrust, self).setUp()
        self.url = self.host + '/v3/OS-TRUST/trusts/'
        self.admin_auth()

    def list(self):
        self.res = requests.get(self.url, headers=self.headers)
        self.checkCode(200)

    def create(self):
        body = {
            "trust": {
                "expires_at": "2013-02-27T18:30:59.999999Z",
                "impersonation": False,
                "allow_redelegation": True,
                "project_id": "31683f12-f291-406d-a709-a34ce4d9939f",
                "roles": [
                    {
                        "name": "admin"
                    }
                ],
                "trustee_user_id": "ff60450e-98b1-4c7c-9cbf-e173abdb1b3a",
                "trustor_user_id": "c1eb8b3c-bae1-43a9-b29d-33de343a4dc1"
            }
        }
        self.res = requests.post(self.host + '/v3/OS-TRUST/trusts/', json = body, headers=self.headers)
        self.checkCode(201)

    def get_info(self):
        trust_id = "13f5b7b2-fb95-4b1c-bbbb-7d6ea731068a"
        self.res = requests.get(self.url + trust_id, headers=self.headers)
        self.checkCode(200)

    def delete(self):
        trust_id = "13f5b7b2-fb95-4b1c-bbbb-7d6ea731068a"
        self.res = requests.delete(self.url + trust_id, headers=self.headers)
        self.checkCode(204)

    def list_roles(self):
        trust_id = "13f5b7b2-fb95-4b1c-bbbb-7d6ea731068a"
        self.res = requests.get(self.url + trust_id + "/roles/", headers=self.headers)
        self.checkCode(200)

    def get_role(self):
        trust_id = "13f5b7b2-fb95-4b1c-bbbb-7d6ea731068a"
        role_id = "e85b790a-0b6e-4d41-80c0-ca6ddd8bf8fd"
        self.res = requests.get(self.url + trust_id + "/roles/" + role_id, headers=self.headers)
        self.checkCode(200)

    def check_role(self):
        trust_id = "13f5b7b2-fb95-4b1c-bbbb-7d6ea731068a"
        role_id = "e85b790a-0b6e-4d41-80c0-ca6ddd8bf8fd"
        self.res = requests.head(self.url + trust_id + "/roles/" + role_id, headers=self.headers)
        self.checkCode(200)


