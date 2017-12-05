from base import TestKeystoneBase
import requests
from pprint import pprint

class TestKeystoneGroups(TestKeystoneBase):

    def setUp(self):
        super(TestKeystoneGroups, self).setUp()
        self.url = self.host + '/v3/groups/'
        self.user_id = '407560f3-b938-4c30-a9b4-5d2138677286'
        self.group_id = ''

    def list(self):
        query = {
            # 'name' : '',
            # 'domain_id' : ''
        }
        self.res = requests.get(self.url, params=query)
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
        self.res = requests.get(self.url + self.group_id)
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
        self.res = requests.get(self.url + self.group_id + '/users/')
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
        self.list()
        self.get_info()
        pprint(self.res.json())
        self.add_user()
        self.check_user()
        self.list_users()
        pprint(self.res.json())
        self.remove_user()
        self.update()
        self.delete()