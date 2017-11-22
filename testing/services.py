from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneServices(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneServices, self).setUp()
        self.host = self.host + '/v3/services/'

    def create(self):
        body = {
            "service": {
                "type": "identity",
                "name": "identity",
                "description": "Identity service"
            }
        }
        self.res = requests.post(self.host, json=body)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        service_id = '63f7baeb-b038-4883-8c2a-e6414d58b758'
        self.res = requests.get(self.host + service_id)
        self.checkCode(200)

    def update(self):
        service_id = '63f7baeb-b038-4883-8c2a-e6414d58b758'
        body = {
        "service": {
            "description": "Block Storage Service V2"
            }
        }
        self.res = requests.patch(self.host + service_id, json=body)
        self.checkCode(200)

    def delete(self):
        service_id = '63f7baeb-b038-4883-8c2a-e6414d58b758'
        self.res = requests.delete(self.host + service_id)
        self.checkCode(204)
