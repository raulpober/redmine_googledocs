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
# Module for representing a Google Document.
#
# This module provides a class for easily manipulating a document
# created from the xml of a Google Documents List API query.
#
#    Document: Class for representing a document and its properties.


module GDoc

  class Document
  
    attr_reader :permissions, :xml
    attr_accessor :title, :doc_id, :type, :last_updated, :last_viewed,
                  :last_modified_by, :author, :links, :writers_can_invite

    # Initializer.
    #
    # Args:
    # - title: string Title of the document
    # - options: hash of options
    #            valid options: +type+: string The type of document. Possible
    #                                   values are 'document', 'presentation',
    #                                   'spreadsheet', 'folder', 'pdf'
    #                           +last_updated+: DateTime
    #                           +xml+: string An XML representation of this doc
    #
    def initialize(title, options={})
      @title = title
      @links = {}
      @type = options[:type] || ''
      @last_updated = options[:last_updated] || DateTime.new
      @last_viewed = options[:last_viewed] || DateTime.new
      @xml = options[:xml] || nil
      @permissions = {'owner' => [], 'reader' => [], 'writer' => []}
    end

    def add_permission(email, role)
      role.downcase!
      return if !@permissions.has_key?(role)

      if email.class == String
        @permissions[role].push(email)
      elsif email.class == Array
        @permissions[role] = @permissions[role] | email
      end
      @permissions[role].uniq!
    end

    def <=>(document)
      @title.casecmp(document.title) # need case-insensitive version of <=>
    end

    def to_s
      [@title, ", doc_id: #{@doc_id} (#{@type})",
      "\nlinks: #{@links.inspect}",
      "\npermissions:\n#{@permissions.inspect}"].join
    end

    def to_xml
      @xml
    end

    def inspect
      self.to_s
    end
  end

end
