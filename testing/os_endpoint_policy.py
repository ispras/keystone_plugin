from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOsEndpointsPolicies(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneOsEndpointsPolicies, self).setUp()
        self.url = self.host + '/v3/'
        self.admin_auth()

    def verify_policy_endpoint(self):
        endpoint_id = '8f17661f-e5d8-41e2-8568-bce8d54c91b7'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/endpoints/" + endpoint_id,
                                headers=self.headers)
        self.checkCode(204)

    def associate_policy_endpoint(self):
        endpoint_id = '8f17661f-e5d8-41e2-8568-bce8d54c91b7'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.put(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/endpoints/" + endpoint_id,
                                json={}, headers=self.headers)
        self.checkCode(204)

    def delete_policy_endpoint(self):
        endpoint_id = '8f17661f-e5d8-41e2-8568-bce8d54c91b7'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.delete(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/endpoints/" + endpoint_id,
                                headers=self.headers)
        self.checkCode(204)

    def verify_policy_service(self):
        service_id = '8b2e74b0-9a6e-47bf-aa24-1c4fb6c9af1c'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/services/" + service_id,
                                headers=self.headers)
        self.checkCode(204)

    def associate_policy_service(self):
        service_id = '8b2e74b0-9a6e-47bf-aa24-1c4fb6c9af1c'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.put(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/services/" + service_id,
                                json={}, headers=self.headers)
        self.checkCode(204)

    def delete_policy_service(self):
        service_id = '8b2e74b0-9a6e-47bf-aa24-1c4fb6c9af1c'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.delete(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/services/" + service_id,
                                   headers=self.headers)
        self.checkCode(204)

    def show_policy(self):
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        self.res = requests.get(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/policy", headers=self.headers)
        self.checkCode(200)

    def check_policy(self):
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        self.res = requests.head(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/policy",  headers=self.headers)
        self.checkCode(200)

    def verify_policy_service_region(self):
        service_id = '8b2e74b0-9a6e-47bf-aa24-1c4fb6c9af1c'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        region_id = 'RegionOne'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/services/" + service_id
                                + "/regions/" + region_id, headers=self.headers)
        self.checkCode(204)

    def associate_policy_service_region(self):
        service_id = '8b2e74b0-9a6e-47bf-aa24-1c4fb6c9af1c'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        region_id = 'RegionOne'
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.put(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/services/" + service_id
                                + "/regions/" + region_id, json={}, headers=self.headers)
        self.checkCode(204)

    def delete_policy_service_region(self):
        service_id = '8b2e74b0-9a6e-47bf-aa24-1c4fb6c9af1c'
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        region_id = 'RegionOne'
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.delete(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/services/" + service_id
                                + "/regions/" + region_id, headers=self.headers)
        self.checkCode(204)

    def list_endpoints(self):
        policy_id = 'f3f0e991-634a-4647-8975-e2d0ce4f8680'
        self.res = requests.get(self.url + "policies/" + policy_id + "/OS-ENDPOINT-POLICY/endpoints", headers=self.headers)
        self.checkCode(200)

    def show_policy_for_endpoint(self):
        endpoint_id = '8f17661f-e5d8-41e2-8568-bce8d54c91b7'
        self.res = requests.get(self.url + "endpoints/" + endpoint_id + "/OS-ENDPOINT-POLICY/policy", headers=self.headers)
        self.checkCode(200)


