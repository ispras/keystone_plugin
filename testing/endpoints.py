from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneEndpoints(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneEndpoints, self).setUp()
        self.host = self.host + '/v3/endpoints/'

    def create(self):
        body = {
            "endpoint": {
                "interface": "public",
                "region_id": "RegionOne",
                "url": "http://localhost:8001/v3/",
                "service_id": "e2986b56-644d-43d3-92e0-2edf61796372"
            }
        }
        self.res = requests.post(self.host, json = body)
        self.checkCode(201)

    def list(self):
        self.res = requests.get(self.host)
        self.checkCode(200)

    def get_info(self):
        endpoint_id = '86012e94-55c2-4938-86c7-d3a4f467a1fa'
        self.res = requests.get(self.host + endpoint_id)
        self.checkCode(200)

    def update(self):
        endpoint_id = '86012e94-55c2-4938-86c7-d3a4f467a1fa'
        body = {
            "endpoint": {
                "interface": "internal",
                "url": "http://example.com/identity/v3/endpoints/828384",
                "service_id": "3c858b69-cd97-4d60-9678-64289d6c2389"
            }
        }
        self.res = requests.patch(self.host + endpoint_id, json=body)
        self.checkCode(200)

    def delete(self):
        endpoint_id = '4cbb72e5-f9a5-4837-b943-a06bcb3bae46'
        self.res = requests.delete(self.host + endpoint_id)
        self.checkCode(204)