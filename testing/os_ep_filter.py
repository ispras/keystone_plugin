from keystone_plugin.testing.base import TestKeystoneBase
import requests

class TestKeystoneOsEpFilter(TestKeystoneBase):
    def setUp(self):
        super(TestKeystoneOsEpFilter, self).setUp()
        self.url = self.host + '/v3/OS-EP-FILTER/'
        self.admin_auth()

    def create_endpoint_group(self):
        body = {
            "endpoint_group": {
                "description": "endpoint group description",
                "filters": {
                    "interface": "admin",
                    "service_id": "8c1a13ae-61a9-43d4-992d-b5544e593d06"
                },
                "name": "endpoint group name 4"
            }
        }

        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.post(self.url + "endpoint_groups", json=body,
                                headers=self.headers)
        self.checkCode(201)

    def list_endpoint_group(self):
        self.res = requests.get(self.url + "endpoint_groups",
                                headers=self.headers)
        self.checkCode(200)

    def get_endpoint_group(self):
        endpoint_id = '61ca440a-5cf5-4c66-9813-4fd96b0b753e'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "endpoint_groups/" + endpoint_id,
                                headers=self.headers)
        self.checkCode(200)

    def update_endpoint_group(self):
        endpoint_id = '61ca440a-5cf5-4c66-9813-4fd96b0b753e'
        body = {
            "endpoint_group": {
                "filters": {
                    "interface": "public"
                }
            }
        }
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.patch(self.url + "endpoint_groups/" + endpoint_id, json=body,
                                headers=self.headers)
        self.checkCode(200)

    def delete_endpoint_group(self):
        endpoint_id = 'dd6c4b95-6e3d-4a54-9793-bbf966dd6669'
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.delete(self.url + "endpoint_groups/" + endpoint_id,
                                headers=self.headers)
        self.checkCode(204)

    def create_association(self):
        endpoint_id = '106dc5b0-0b1a-4017-ba8c-cb066f440f44'
        project_id = "31683f12-f291-406d-a709-a34ce4d9939f"
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.put(self.url + "projects/" + project_id + "/endpoints/" + endpoint_id, json={},
                                headers=self.headers)
        self.checkCode(204)

    def check_association(self):
        endpoint_id = '106dc5b0-0b1a-4017-ba8c-cb066f440f44'
        project_id = "31683f12-f291-406d-a709-a34ce4d9939f"
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.head(self.url + "projects/" + project_id + "/endpoints/" + endpoint_id,
                                headers=self.headers)
        self.checkCode(204)

    def list_association_by_project(self):
        # endpoint_id = '106dc5b0-0b1a-4017-ba8c-cb066f440f44'
        project_id = "31683f12-f291-406d-a709-a34ce4d9939f"
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "projects/" + project_id + "/endpoints/",
                                headers=self.headers)
        self.checkCode(200)

    def list_association_by_endpoint(self):
        endpoint_id = '106dc5b0-0b1a-4017-ba8c-cb066f440f44'
        # project_id = "31683f12-f291-406d-a709-a34ce4d9939f"
        #/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "endpoints/" + endpoint_id + "/projects/",
                                headers=self.headers)
        self.checkCode(200)

    def create_ep_association(self):
        endpoint_group_id = '5d578fd8-3eb3-424a-ac48-5538c310856e'
        project_id = "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.put(self.url + "endpoint_groups/" + endpoint_group_id + "/projects/" + project_id, json={},
                                headers=self.headers)
        self.checkCode(204)

    def get_ep_association(self):
        endpoint_group_id = 'dd6c4b95-6e3d-4a54-9793-bbf966dd6669'
        project_id = "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.head(self.url + "endpoint_groups/" + endpoint_group_id + "/projects/" + project_id, json={},
                                headers=self.headers)
        self.checkCode(200)

    def delete_ep_association(self):
        endpoint_group_id = 'dd6c4b95-6e3d-4a54-9793-bbf966dd6669'
        project_id = "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.delete(self.url + "endpoint_groups/" + endpoint_group_id + "/projects/" + project_id, json={},
                                 headers=self.headers)
        self.checkCode(204)

    def list_projects_by_ep_group(self):
        endpoint_group_id = 'dd6c4b95-6e3d-4a54-9793-bbf966dd6669'
        project_id = "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "endpoint_groups/" + endpoint_group_id + "/projects/", json={},
                                 headers=self.headers)
        self.checkCode(200)

    def list_ep_by_ep_group(self):
        endpoint_group_id = '5d578fd8-3eb3-424a-ac48-5538c310856e'
        # project_id = "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "endpoint_groups/" + endpoint_group_id + "/endpoints/", json={},
                                 headers=self.headers)
        self.checkCode(200)

    def list_ep_groups_by_project(self):
        # endpoint_group_id = '5d578fd8-3eb3-424a-ac48-5538c310856e'
        project_id = "e64747bd-c21d-450a-9d13-ab4d6ce118ac"
        # /policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id
        self.res = requests.get(self.url + "projects/" + project_id + "/endpoint_groups/", json={},
                                 headers=self.headers)
        self.checkCode(200)
