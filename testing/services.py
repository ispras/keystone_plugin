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
                "name": "keystone",
                "description": "test2 service"
            }
        }
        self.res = requests.post(self.host, json=body)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        service_id = 'identity'
        self.res = requests.get(self.host + service_id)
        self.checkCode(200)

    def update(self):
        service_id = 'a9a31a2d-bd4f-4ac3-9361-1c8fe5eb1f57'
        body = {
        "service": {
            "enabled": True
            }
        }
        self.res = requests.patch(self.host + service_id, json=body)
        self.checkCode(200)

    def delete(self):
        service_id = '5c826a59-9619-491e-b700-296b77fd5cd1'
        self.res = requests.delete(self.host + service_id)
        self.checkCode(204)
