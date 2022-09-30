LIBIMOBILEDYLIB = get_libimobile_dylib.freeze
LIBPLISTDYLIB = get_libplist_dylib.freeze

def get_libimobile_dylib
  puts "Hey Harshit"
  `otool -L /usr/local/bin/idevice_id | grep -m 1 'libimobiledevice'`.strip().split[0]
end

def get_libplist_dylib
  puts "Hey Krishna"
  `otool -L /usr/local/bin/idevice_id | grep -m 1 'libplist'`.strip().split[0]
end
