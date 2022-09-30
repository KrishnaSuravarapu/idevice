def get_libimobile_dylib
  `otool -L /usr/local/bin/idevice_id | grep -m 1 'libplist.*dylib' | awk '{print $1}'`
end

def get_libplist_dylib
  `otool -L /usr/local/bin/idevice_id | grep -m 1 'libimobiledevice.*dylib' | awk '{print $1}'`
end

LIBIMOBILEDYLIB = get_libimobile_dylib.freeze
LIBPLISTDYLIB = get_libplist_dylib.freeze
