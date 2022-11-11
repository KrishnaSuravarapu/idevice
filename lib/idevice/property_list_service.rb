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

require 'idevice/c'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class PropertyListServiceError < IdeviceLibError
  end

  class PropertyListServiceClient < C::ManagedOpaquePointer
    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.restored_client_free(ptr)
        end
      end
    end

    def self.attach(opts = {})
      idevice = opts[:idevice] || Idevice.attach(opts)
      label = opts[:label] || "ruby-idevice"

      FFI::MemoryPointer.new(:pointer) do |p_rc|
        err = C.property_list_service_client_new(idevice, p_rc, label)
        raise PropertyListServiceError, "Property List Service Error: #{err}" if err != :SUCCESS

        rc = p_rc.read_pointer
        raise PropertyListServiceError, "property_list_service_client_new returned a NULL client" if rc.null?

        return new(rc)
      end
    end

    module C
        ffi_lib 'imobiledevice'
    
        typedef enum(
          :SUCCESS, 0,
          :INVALID_ARG, -1,
          :MUX_ERROR, -2,
          :SSL_ERROR, -3,
          :NOT_ENOUGH_DATA, -4,
          :TIMEOUT, -5
          :UNKNOWN_ERROR, -256,
        ), :property_list_service_error_t
    
        # property_list_service_error_t property_list_service_client_new(idevice_t device, lockdownd_service_descriptor_t service, property_list_service_client_t *client);
        attach_function :property_list_service_client_new, [Idevice, LockdownServiceDescriptor, :pointer], :property_list_service_error_t
    
        # # restored_error_t restored_client_free(restored_client_t client);
        # attach_function :restored_client_free, [RestoreClient], :restored_error_t
    
        # # restored_error_t restored_query_type(restored_client_t client, char **type, uint64_t *version);
        # attach_function :restored_query_type, [RestoreClient, :pointer, :pointer], :restored_error_t
    
        # # restored_error_t restored_query_value(restored_client_t client, const char *key, plist_t *value);
        # attach_function :restored_query_value, [RestoreClient, :string, :pointer], :restored_error_t
    
        # # restored_error_t restored_get_value(restored_client_t client, const char *key, plist_t *value) ;
        # attach_function :restored_get_value, [RestoreClient, :string, :pointer], :restored_error_t
    
        # # restored_error_t restored_send(restored_client_t client, plist_t plist);
        # attach_function :restored_send, [RestoreClient, Plist_t], :restored_error_t
    
        # # restored_error_t restored_receive(restored_client_t client, plist_t *plist);
        # attach_function :restored_receive, [RestoreClient, :pointer], :restored_error_t
    
        # # restored_error_t restored_goodbye(restored_client_t client);
        # attach_function :restored_goodbye, [RestoreClient], :restored_error_t
    
        # # restored_error_t restored_start_restore(restored_client_t client, plist_t options, uint64_t version);
        # attach_function :restored_start_restore, [RestoreClient, Plist_t, :uint64], :restored_error_t
    
        # # restored_error_t restored_reboot(restored_client_t client);
        # attach_function :restored_reboot, [RestoreClient], :restored_error_t
    
        # # void restored_client_set_label(restored_client_t client, const char *label);
        # attach_function :restored_client_set_label, [RestoreClient, :string], :void
      end
end
