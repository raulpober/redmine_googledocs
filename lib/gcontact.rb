#!/usr/bin/ruby
#
# Copyright (C) 2009 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author:: Eric Bidelman (mailto:e.bidelman@google.com)
#
# Module for representing a Google Contact.
#
# This module provides a class for easily manipulating a contact
# created from the xml of a Google Contacts API query.
#
#    Contact: Class for representing a contact and its properties.


module GContact

  class Contact
  
    attr_accessor :name, :email

    def initialize(name = nil, email=nil, xml=nil)
      @name, @email, @xml = name, email, xml
    end
    
    def <=>(contact)
      if !contact.email.nil? and !@email.nil?
        @email.casecmp(contact.email) # case-insensitive version of <=>
      else
        -1
      end
    end

    def to_s
      str = ''
      str += "#{@name}, " if @name
      str += @email
      return str
    end
    
    def to_xml
      @xml
    end
    
    def inspect
      self.to_s
    end
  end

end
