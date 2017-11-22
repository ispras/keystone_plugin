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
        res = requests.post(self.host, json=body)
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
        service_id = '63f7baeb-b038-4883-8c2a-e6414d58b758'
        res = requests.get(self.host + service_id)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def update(self):
        service_id = '63f7baeb-b038-4883-8c2a-e6414d58b758'
        body = {
        "service": {
            "description": "Block Storage Service V2"
            }
        }
        res = requests.patch(self.host + service_id, json=body)
        self.checkCode(res, 200)

        response = res.json()
        for k, v in response.items():
            print(k, '\n\t', v)

    def delete(self):
        service_id = '63f7baeb-b038-4883-8c2a-e6414d58b758'
        res = requests.delete(self.host + service_id)
        self.checkCode(res, 204)
