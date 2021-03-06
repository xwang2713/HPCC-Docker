#!/usr/bin/python3
################################################################################
#    HPCC SYSTEMS software Copyright (C) 2019 HPCC Systems®.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
################################################################################
import os
import sys
import json

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + os.sep + "..")
from CollectIPs import CollectIPs


class CollectIPsFromDocker (CollectIPs):

    def __init__(self):
        '''
        constructor
        '''
        super(CollectIPs, self).__init__()


    def retrieveIPsFromCloud(self, input_fn):
        with open(input_fn) as json_file:
            network_data = json.load(json_file)
            #print("open json file")
            #print(repr(network_data))
        self.clean_dir(self._out_dir)

        #print(repr(network_data['Containers']))
        for key in network_data['Containers']:
            node_name = (network_data['Containers'][key]['Name']).split('_')[1].split('.')[0]
            if ( node_name.startswith('admin')     or
                 node_name.startswith('dali')      or
                 node_name.startswith('esp')       or
                 node_name.startswith('thor')      or
                 node_name.startswith('roxie')     or
                 node_name.startswith('eclcc')     or
                 node_name.startswith('scheduler') or
                 node_name.startswith('backup')    or
                 node_name.startswith('sasha')     or
                 node_name.startswith('dropzone')  or
                 node_name.startswith('support')   or
                 node_name.startswith('spark')     or
                 node_name.startswith('node')):
                #print("node name: " + node_name)
                node_ip = (network_data['Containers'][key]['IPv4Address']).split('/')[0]
                #print("node ip: " + node_ip)
                self.write_to_file(self._out_dir, node_name, node_ip + ";")

if __name__ == '__main__':

    cip = CollectIPsFromDocker()
    cip.main()
