from base import TestKeystoneBase
import requests

class TestKeystoneServices(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneServices, self).setUp()
        self.url = self.host + '/v3/services/'
        self.admin_auth()

    def create(self):
        body = {
            "service": {
                "type": "identity",
                "name": "keystone",
                "description": "identity service",
                "enabled": True
            }
        }
        self.res = requests.post(self.url, json=body, headers=self.headers)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.url, headers=self.headers)
        self.checkCode(200)

    def get_info(self):
        service_id = 'placement'
        self.res = requests.get(self.url + service_id, headers = self.headers)
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
        service_id = 'b94cf729-961c-4868-ae84-5eed25b78a08'
        self.res = requests.delete(self.url + service_id, headers = self.headers)
        self.checkCode(204)

    def delete_all(self):
        self.res = requests.get(self.url, headers = self.headers)
        self.checkCode(200)
        services = self.res.json()['services']
        for k in services:
            if k['name'] != 'keystone':
                self.res = requests.delete(self.url + k['id'], headers = self.headers)
                self.checkCode(204)