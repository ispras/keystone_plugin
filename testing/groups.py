from base import TestKeystoneBase
import requests
from pprint import pprint

class TestKeystoneGroups(TestKeystoneBase):

    def setUp(self):
        super(TestKeystoneGroups, self).setUp()
        self.url = self.host + '/v3/groups/'
        self.user_id = '3daf3fca-d165-4059-a71a-fd1617d9e9cb'
        self.group_id = ''
        self.admin_auth()

    def list(self):
        query = {
            # 'name' : '',
            # 'domain_id' : ''
        }
        self.res = requests.get(self.url, params=query, headers = self.headers)
        self.checkCode(200)

    def create(self):
        body = {
            'group' : {
                'description' : 'group for admins',
                # 'domain_id' : 'Default',
                'name' : 'admin'
            }
        }
        self.res = requests.post(self.url, json = body)
        self.checkCode(201)
        self.group_id = self.res.json()['group']['id']

    def get_info(self):
        self.group_id = 'admins'
        self.res = requests.get(self.url + self.group_id, headers = self.headers)
        self.checkCode(200)

    def update(self):
        body = {
            'group' : {
                'description' : 'group for adminadmins',
                # 'domain_id' : 'Default',
                'name' : 'adminadmin'
            }
        }
        self.res = requests.patch(self.url + self.group_id, json = body)
        self.checkCode(200)

    def delete(self):
        query = {
            # 'password_expires_at' : 'lt:2016-12-08T22:02:00Z' # not implemented
        }
        self.res = requests.delete(self.url + self.group_id, params = query)
        self.checkCode(204)

    def list_users(self):
        query = {
            'password_expires_at' : 'gt:2017-12-08T13:00:00Z'
        }
        self.res = requests.get(self.url + self.group_id + '/users/', params = query)
        self.checkCode(200)

    def add_user(self):
        self.res = requests.put(self.url + self.group_id + '/users/' + self.user_id, json = {})
        self.checkCode(200)

    def check_user(self):
        self.res = requests.head(self.url + self.group_id + '/users/' + self.user_id)
        self.checkCode(204)

    def remove_user(self):
        self.res = requests.delete(self.url + self.group_id + '/users/' + self.user_id)
        self.checkCode(204)

    def all(self):
        self.create()
        # self.list()
        # self.get_info()
        # pprint(self.res.json())
        self.add_user()
        self.check_user()
        self.list_users()
        pprint(self.res.json())
        self.remove_user()
        # self.update()
        self.delete()