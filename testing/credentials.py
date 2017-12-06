from keystone_plugin.testing.base import TestKeystoneBase
import requests


class TestKeystoneCredentials(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneCredentials, self).setUp()
        self.host = self.host + '/v3/credentials/'

    def create(self):
        body = {
            "credential": {
                "blob": "{\"access\":\"181920\",\"secret\":\"secretKey\"}",
                "project_id": "a634b76d-f2a4-4bdf-9e61-22f2f89b2c96",
                "type": "ec2",
                "user_id": "e7b41294-5c18-4265-91f3-4b1e374f9219"
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)

    def list(self):
        query = {
            'user_id': '4f0547bd-f1b2-4506-b9e6-9c9dea3c0476'
             # 'domain_id' : '14ad23de-d411-4b72-9295-cee25cfaee09'
            # 'idp_id': 'idp_id',
            # 'name': 'name',
            # 'password_expiself.res_at': 'password_expiself.res_at',
            # 'protocol_id': 'protocol_id',
            # 'unique_id': 'unique_id'
        }
        self.res = requests.get(self.host, params=query)
        self.checkCode(200)

    def get_info(self):
        credential_id = '10b754b2-2c3f-4e76-94a6-0386b3a3b7a8'
        self.res = requests.get(self.host + credential_id)
        self.checkCode(200)

    def update(self):
        credential_id = '10b754b2-2c3f-4e76-94a6-0386b3a3b7a8'
        body = {
            "credential": {
                "blob": "{\"access\":\"181920\",\"secret\":\"NewSecretKey\"}",
                "project_id": "a634b76d-f2a4-4bdf-9e61-22f2f89b2c96",
                "type": "ec2",
                "user_id": "e869d4eb-308b-4954-a901-5b22c69154be"
            }
        }
        self.res = requests.patch(self.host + credential_id, json=body)
        self.checkCode(200)

    def delete(self):
        credential_id = '10b754b2-2c3f-4e76-94a6-0386b3a3b7a8'
        self.res = requests.delete(self.host + credential_id)
        self.checkCode(204)
