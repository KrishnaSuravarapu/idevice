#
# Copyright (c) 2013 Eric Monti - Bluebox Security
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative 'spec_helper'

if ENV["TEST_MOBILEBACKUP1"]

  describe Idevice::MobileBackupClient do
    before :each do
      @mb = Idevice::MobileBackupClient.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
    end

    after :each do
    end

    it "should attach" do
      @mb.should be_a Idevice::MobileBackupClient
    end

    it "needs functional tests" do
      skip "writing more specs for MobileBackupClient"
    end
  end
end
