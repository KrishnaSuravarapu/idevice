require 'idevice/c'
require 'idevice/idevice'
require 'idevice/lockdown'

module Idevice
  class PropertyListServiceError < IdeviceLibError
  end

  class PropertyListServiceClient < C::ManagedOpaquePointer
    include LibHelpers
    def self.release(ptr)
      C::Freelock.synchronize do
        unless ptr.null?
          C.property_list_service_client_free(ptr)
        end
      end
    end

    def self.attach(opts = {})
      idevice = opts[:idevice] || Idevice.attach(opts)

      _attach_helper("com.apple.amfi.lockdown", opts) do |idevice, ldsvc, p_plsc|
        err = C.property_list_service_client_new(idevice, ldsvc, p_plsc)
        raise PropertyListServiceError, "Property List Service Error: #{err}" if err != :SUCCESS

        plsc = p_plsc.read_pointer
        raise PropertyListServiceError, "property_list_service_client_new returned a NULL client" if plsc.null?

        return new(plsc)
      end
    end

    def send_plist(dict)
      err = C.property_list_service_send_xml_plist(self, Plist_t.from_ruby(dict))
      raise PropertyListServiceError, "Property List Service error: #{err}" if err != :SUCCESS

      return true
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
      :TIMEOUT, -5,
      :UNKNOWN_ERROR, -256,
    ), :property_list_service_error_t

    # property_list_service_error_t property_list_service_client_new(idevice_t device, lockdownd_service_descriptor_t service, property_list_service_client_t *client);
    attach_function :property_list_service_client_new, [Idevice, LockdownServiceDescriptor, :pointer],
                    :property_list_service_error_t

    # property_list_service_error_t property_list_service_send_xml_plist(property_list_service_client_t client, plist_t plist)
    attach_function :property_list_service_send_xml_plist, [:pointer, Plist_t], :property_list_service_error_t

    # property_list_service_error_t property_list_service_client_free(property_list_service_client_t client)
    attach_function :property_list_service_client_free, [:pointer], :property_list_service_error_t
  end
end