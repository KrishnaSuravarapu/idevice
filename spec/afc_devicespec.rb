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
require 'time'

describe Idevice::AFCClient do
  before :all do
    @fromfile = sample_file("plist.bin")
  end

  before :each do
    @afc = Idevice::AFCClient.attach(idevice:shared_idevice, lockdown_client:shared_lockdown_client)
  end

  it "should attach" do
    @afc.should be_a Idevice::AFCClient
  end

  it "should return device info" do
    result = @afc.device_info
    result.should be_a Hash
    result.keys.sort.should == [:FSBlockSize, :FSFreeBytes, :FSTotalBytes, :Model]
    result[:FSBlockSize].should =~ /^\d+$/
    result[:FSFreeBytes].should =~ /^\d+$/
    result[:FSTotalBytes].should =~ /^\d+$/
    result[:FSTotalBytes].to_i.should > result["FSFreeBytes"].to_i
  end

  it "should return device info for specific keys" do
    totbytes = @afc.device_info("FSTotalBytes")
    totbytes.should be_a String
    totbytes.should =~ /^\d+$/

    freebytes = @afc.device_info("FSFreeBytes")
    freebytes.should be_a String
    freebytes.should =~ /^\d+$/

    totbytes.to_i.should > freebytes.to_i
  end

  it "should list directory contents" do
    result = @afc.read_directory('/')
    result.should be_a Array
    result[0,2].should == ['.', '..']
  end

  it "should raise an error listing an invalid directory" do
    lambda{ @afc.read_directory('/TOTALLYNOTREALLYTHERE') }.should raise_error(Idevice::AFCError)
  end

  it "should get file information" do
    result = @afc.file_info('/')
    result.should be_a Hash
    result.keys.sort.should == [:st_birthtime, :st_blocks, :st_ifmt, :st_mtime, :st_nlink, :st_size]
    result[:st_ifmt].should == :S_IFDIR
  end

  it "should raise an error getting info for an invalid path" do
    lambda{ @afc.file_info('/TOTALLYNOTREALLYTHERE') }.should raise_error(Idevice::AFCError)
  end

  it "should remove a file path" do
    remotepath='TOTALLYATESTFILECREATEDTEST'

    @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
    @afc.remove_path(remotepath).should == true
  end

  it "should remove an (empty) directory path" do
    remotepath='TOTALLYATESTDIRCREATEDTEST'
    @afc.make_directory(remotepath).should == true
    @afc.remove_path(remotepath).should == true
  end

  it "should rename a file path" do
    remotepath='TOTALLYATESTFILECREATEDTEST'
    renamepath = remotepath+'2'

    begin
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      originfo = @afc.file_info(remotepath)
      @afc.rename_path(remotepath, renamepath).should == true
      lambda{ @afc.file_info(remotepath) }.should raise_error Idevice::AFCError
      info = @afc.file_info(renamepath)
      info.should == originfo
    ensure
      @afc.remove_path(remotepath) rescue nil
      @afc.remove_path(renamepath).should == true
    end

  end

  it "should rename a directory path" do
    remotepath = 'TOTALLYATESTDIRCREATEDTEST'
    renamepath = remotepath+'2'
    begin
      @afc.make_directory(remotepath).should == true
      originfo = @afc.file_info(remotepath)
      @afc.rename_path(remotepath, renamepath).should == true
      lambda{ @afc.file_info(remotepath) }.should raise_error Idevice::AFCError
      info = @afc.file_info(renamepath)
      info.should == originfo
    ensure
      @afc.remove_path(remotepath) rescue nil
      @afc.remove_path(renamepath).should == true
    end
  end

  it "should make a directory" do
    remotepath = 'TOTALLYATESTDIR'
    begin
      @afc.make_directory(remotepath).should == true
      result = @afc.file_info(remotepath)
      result[:st_ifmt].should == :S_IFDIR
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should make a symbolic link to a directory" do
    begin
      @afc.symlink('.', 'TOTALLYATESTSYMLINKTOCURRENTDIR').should == true
      result = @afc.file_info('TOTALLYATESTSYMLINKTOCURRENTDIR')
      result[:st_ifmt].should == :S_IFLNK
    ensure
      @afc.remove_path('TOTALLYATESTSYMLINKTOCURRENTDIR') rescue nil
    end
  end

  it "should make a symbolic link to a file" do
    remotefile = 'TOTALLYATESTFILE3'
    remotelink = 'TOTEALLYATESTSYMLINK3'

    begin
      @afc.touch(remotefile).should == true
      @afc.symlink(remotefile, remotelink).should == true
      @afc.file_info(remotefile)[:st_ifmt].should == :S_IFREG
      @afc.file_info(remotelink)[:st_ifmt].should == :S_IFLNK

      # opening a symlinked file via AFC seems to give PERM_DENIED ?
      #@afc.open(remotelink,'a'){|f| f.write("meep") }
      #@afc.cat(remotefile).should == "meep"

      #@afc.file_info(remotefile)[:st_ifmt].should == :S_IFREG
      #@afc.file_info(remotelink)[:st_ifmt].should == :S_IFLNK
    ensure
      @afc.remove_path(remotefile) rescue nil
      @afc.remove_path(remotelink) rescue nil
    end
  end

  it "should make a hard link to a file" do
    remotefile = 'TOTALLYATESTFILE2'
    remotelink = 'TOTEALLYATESTHARDLINK'

    begin
      @afc.touch(remotefile).should == true
      @afc.hardlink(remotefile, remotelink).should == true
      @afc.file_info(remotefile)[:st_ifmt].should == :S_IFREG
      @afc.file_info(remotelink)[:st_ifmt].should == :S_IFREG

      @afc.open(remotelink,'a'){|f| f.write("meep") }
      @afc.cat(remotefile).should == "meep"

      @afc.file_info(remotefile)[:st_ifmt].should == :S_IFREG
      @afc.file_info(remotelink)[:st_ifmt].should == :S_IFREG
    ensure
      @afc.remove_path(remotefile) rescue nil
      @afc.remove_path(remotelink) rescue nil
    end
  end

  it "should raise an error removing a non-existent path" do
    lambda{ @afc.remove_path('TOTALLYNOTREALLYTHERE') }.should raise_error(Idevice::AFCError)
  end

  it "should put a file and cat it" do
    remotepath = 'TESTFILEUPLOAD'

    begin
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      @afc.cat(remotepath).should == @fromfile.read()
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should put a file and cat it with a small chunk size" do
    remotepath = 'TESTFILEUPLOAD'

    begin
      gotblock=false
      @afc.put_path(@fromfile.to_s, remotepath, chunksize: 2) do |chunksz|
        gotblock=true
        (0..2).should include(chunksz)
      end.should == @fromfile.size
      gotblock.should == true

      catsize = 0
      catbuf = StringIO.new
      gotblock=false

      @afc.cat(remotepath, 2) do |chunk|
        catbuf << chunk
        catsize += chunk.size
        gotblock=true
        (0..2).should include(chunk.size)
      end

      catsize.should == @fromfile.size
      catbuf.string.should == @fromfile.read()
      gotblock.should == true
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should get a file" do
    tmpfile = Tempfile.new('TESTFILEUPLOADFORGETlocal')
    tmppath = tmpfile.path
    tmpfile.close
    remotepath = 'TESTFILEUPLOADFORGET'
    begin
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      @afc.get_path(remotepath, tmppath).should == @fromfile.size
      File.read(tmppath).should == @fromfile.read()
    ensure
      @afc.remove_path(remotepath) rescue nil
      File.unlink(tmppath)
    end
  end

  it "should truncate a file path" do
    remotepath = 'TESTFILEUPLOADFORTRUNCATE'

    begin
      (@fromfile.size > 10).should == true
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      @afc.size(remotepath).should == @fromfile.size
      @afc.truncate(remotepath, 10).should == true
      @afc.size(remotepath).should == 10
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should get file mtime" do
    res = @afc.mtime('.')
    res.should be_a Time
    # between first iphone release and 30-sec from now
    res.should > Time.parse("June 29, 2007")
    res.should < (Time.now+30)
  end

  it "should get file ctime" do
    res = @afc.mtime('.')
    res.should be_a Time
    # between first iphone release and 30-sec from now
    res.should > Time.parse("June 29, 2007")
    res.should < (Time.now+30)
  end

  it "should touch a file" do
    remotefile = "TESTFILETOUCH"
    begin
      @afc.touch(remotefile).should == true
      @afc.cat(remotefile).should == ""
      @afc.ctime(remotefile).should == @afc.mtime(remotefile)
    ensure
      @afc.remove_path(remotefile) rescue nil
    end
  end

  it "should set file time" do
    remotefile = "TESTINGFILETIMESETTING"
    settime = Time.parse("June 29, 2007 4:20 UTC")
    begin
      @afc.touch(remotefile).should == true
      @afc.ctime(remotefile).should_not == settime
      @afc.mtime(remotefile).should_not == settime

      @afc.set_file_time(remotefile, settime).should == true
      @afc.ctime(remotefile).should == settime
      @afc.mtime(remotefile).should == settime
    ensure
      @afc.remove_path(remotefile) rescue nil
    end
  end

  it "should open a file and read all its contents" do
    remotepath = 'TESTFILEUPLOADFOROPENANDREAD'

    begin
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      dat = @afc.open(remotepath, 'r') { |f| f.read() }
      dat.should == @fromfile.read()
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should open a file and read a few bytes from it" do
    remotepath = 'TESTFILEUPLOADFOROPENANDREAD'

    begin
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      @afc.open(remotepath, 'r') do |f|
        f.read(6).should == "bplist"
      end
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should open a file skip ahead a few bytes offset and read from it" do
    remotepath = 'TESTFILEUPLOADFOROPENANDREADOFFSET'

    begin
      @afc.put_path(@fromfile.to_s, remotepath).should == @fromfile.size
      @afc.open(remotepath, 'r') do |f|
        f.pos=2
        f.read(4).should == "list"
      end
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should open a file and write to it" do
    remotepath = 'TESTFILEUPLOADFOROPENANDWRITE'
    testdata = "hellotest"

    begin
      @afc.open(remotepath, 'w') do |f|
        f.write(testdata).should == testdata.size
      end
      @afc.cat(remotepath).should == testdata
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should open a file and append to it" do
    remotepath = 'TESTFILEUPLOADFOROPENANDAPEND'
    testdata = "hellotest"

    begin
      @afc.open(remotepath, 'w') do |f|
        f.write(testdata).should == testdata.size
      end
      @afc.cat(remotepath).should == testdata
      @afc.open(remotepath, 'a') do |f|
        f.pos.should == 0
        f.pos+= testdata.size
        f.pos.should == testdata.size
        f.write(testdata).should == testdata.size
      end
      @afc.cat(remotepath).should == testdata + testdata
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

  it "should open a file jump around positions and read/write to it" do
    remotepath = 'TESTFILEUPLOADFOROPENANDWRITE'
    testdata = "hellotest"

    begin
      @afc.open(remotepath, 'w') do |f|
        f.write(testdata).should == testdata.size
      end
      @afc.open(remotepath, 'r+') do |f|
        f.pos.should == 0
        f.read().should == testdata
        f.pos.should == testdata.size
        f.rewind
        f.pos.should == 0
        f.seek(0, :SEEK_END)
        f.pos.should == testdata.size
        f.write(testdata).should == testdata.size
        f.pos.should == testdata.size*2
        f.rewind
        f.read().should == testdata*2
      end
      @afc.cat(remotepath).should == testdata*2
    ensure
      @afc.remove_path(remotepath) rescue nil
    end
  end

end
