# -----------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
#   CyberArk WebServices Provider to use CyberArk WebServices SDK REST API
# -----------------------------------------------------------------------------

require 'net/http'
require 'json'

# Forward declaration(s)
module PuppetX; end

module PuppetX::CyberArk
  #:nodoc:
  class WebServices < Puppet::Provider
    @session_token = ''

    @authentication_info = { 'username' => 'scott' }

    @base_url = ''

    @webservices_certificate_file = ''

    def self.base_url=(url)
      Puppet.debug("Setting base_url to #{url}")
      @base_url = url
    end

    def self.base_url
      # Puppet.debug("CyberArk_PVWA_BaseURL = " +  ENV["CyberArk_PVWA_BaseURL"])
      Puppet.debug("base url = #{@base_url}")

      return ENV['CyberArk_PVWA_BaseURL'] if @base_url.empty? && ENV['CyberArk_PVWA_BaseURL']
      @base_url
    end

    def self.webservices_certificate_file=(certfile)
      Puppet.debug("Setting certificate file to #{certfile}")
      @webservices_certificate_file = certfile
    end

    def self.webservices_certificate_file
      Puppet.debug("certificate file = #{@webservices_certificate_file}")

      return ENV['CyberArk_PVWA_CertificateFile'] if @webservices_certificate_file.empty? && ENV['CyberArk_PVWA_CertificateFile']
      @webservices_certificate_file
    end

    def self.calling_method
      # Get calling method and clean it up for good reporting
      cm = caller(0..0).first.split(' ').last
      cm.tr!('\'', '')
      cm.tr!('\`', '')
      cm
    end

    def rest_call(action, url, data: data = nil, resource: resource = nil)
      self.class.rest_call(action, url, data, resource)
    end

    def self.post(url, data: data = nil, resource: resource = nil)
      Puppet.debug("data #{data}")
      rest_call('POST', url, data, resource)
    rescue StandardError => e
      raise("puppet_x::CyberArk::WebServices.post: Error caught on POST: #{e}")
    end

    def self.put(url, data: data = nil, resource: resource = nil)
      rest_call('PUT', url, data, resource)
    rescue StandardError => e
      raise("puppet_x::CyberArk::WebServices.put: Error caught on PUT: #{e}")
    end

    def self.patch(url, data: data = nil, resource: resource = nil)
      rest_call('PATCH', url, data, resource)
    rescue StandardError => e
      raise("puppet_x::CyberArk::WebServices.put: Error caught on PATCH: #{e}")
    end

    def self.delete(url, data: data = nil, resource: resource = nil)
      rest_call('DELETE', url, data, resource)
    rescue StandardError => e
      raise("puppet_x::CyberArk::WebServices.delete: Error caught on DELETE: #{e}")
    end

    def self.get(url, data: data = nil, resource: resource = nil)
      #     def self.get(url, token, data=nil)
      Puppet.debug("GET!!!  resource = #{resource}")
      Puppet.debug("******** LOGIN username => #{resource[:login_username]}")
      Puppet.debug("******** base_url => #{resource['base_url']}")

      begin
        rest_call('GET', url, data, resource: resource)
      rescue StandardError => e
        raise("puppet_x::CyberArk::WebServices.get: Error caught on GET: #{e}")
      end
    end

    def self.rest_call(action, url, data, resource)
      # Single method to make all calls to the respective RESTful API

      if resource
        Puppet.debug("Resource passed #{resource[:resource].parameters.keys}")
        unless resource[:resource].parameters[:base_url].nil?
          Puppet.debug("Setting base_url to #{resource[:resource].parameters[:base_url].value}")
          self.base_url = resource[:resource].parameters[:base_url].value
        end
        unless resource[:resource].parameters[:webservices_certificate_file].nil?
          Puppet.debug("Setting certificate_file to #{resource[:resource].parameters[:webservices_certificate_file].value}")
          self.webservices_certificate_file = resource[:resource].parameters[:webservices_certificate_file].value
        end
      end

      if base_url + '/' + url !~ URI.regexp
        raise('puppet_x::CyberArk::WebServices.get: Must supply a valid URL and/or set environment variable CyberArk_PVWA_BaseURL')
      end

      uri = URI.parse(base_url + '/' + url)

      http = Net::HTTP.new(uri.host, uri.port)

      if uri.port == 443 || uri.scheme == 'https'
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.cert_store = OpenSSL::X509::Store.new
        http.cert_store.set_default_paths
        if webservices_certificate_file != ''
          http.cert_store.add_file(webservices_certificate_file)
        end
      else
        http.use_ssl = false
      end

      if Puppet[:debug] == true
        http.set_debug_output($stdout)
      end

      req = if action =~ %r{post}i
              Net::HTTP::Post.new(uri.request_uri)
            elsif action =~ %r{logon}i
              Net::HTTP::Post.new(uri.request_uri)
            elsif action =~ %r{patch}i
              Net::HTTP::Patch.new(uri.request_uri)
            elsif action =~ %r{put}i
              Net::HTTP::Put.new(uri.request_uri)
            elsif action =~ %r{delete}i
              Net::HTTP::Delete.new(uri.request_uri)
            else
              Net::HTTP::Get.new(uri.request_uri)
            end

      req.set_content_type('application/json')

      if action !~ %r{logon}i && @session_token.empty?
        Puppet.debug('Session Token not set, authenticating first')
        web_service_logon(resource)
        Puppet.debug("SessionToken=#{@session_token}")
      end

      req.add_field('Authorization', @session_token.to_s)

      req.body = data if data && valid_json?(data)

      Puppet.debug("webservices::#{calling_method}: REST API #{req.method} Endpoint: #{uri}")
      Puppet.debug("webservices::#{calling_method}: REST API #{req.method} Request: #{req}")

      Puppet.debug('before http.request')
      response = http.request(req)
      Puppet.debug('after http.request')

      Puppet.debug("webservices::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

      return JSON.parse(response.body) if req.method == 'GET'
      response
    end

    def self.web_service_logon(resource)
      Puppet.debug('LOGON INVOKED!')

      data = {}
      endpoint_url = '/PasswordVault/WebServices/auth/Shared/RestfulAuthenticationService.svc/Logon'

      Puppet.debug(" #{resource[:resource].parameters[:use_shared_logon_authentication].value}")

      if resource[:resource].parameters[:use_shared_logon_authentication].value.to_s == 'false'
        Puppet.debug('Not using shared_logon_authentication')

        endpoint_url = '/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon'

        unless resource[:resource].parameters[:login_username] && resource[:resource].parameters[:login_password]
          raise("webservices::#{calling_method}: Unable to logon. Missing username/password")
        end

        data['username'] = resource[:resource].parameters[:login_username].value
        data['password'] = resource[:resource].parameters[:login_password].value

        unless resource[:resource].parameters[:connection_number].nil?
          connection_number = resource[:resource].parameters[:connection_number].value.to_i
          data['connectionNumber'] = connection_number
          Puppet.debug("Connection Number => #{resource[:resource].parameters[:connection_number].value.to_i}")
        end

        Puppet.debug("logon data => #{data.to_json}")
      end

      response = rest_call('LOGON', endpoint_url, data.to_json, resource)
      Puppet.debug("Response => #{response.code}")

      raise("webservices::#{calling_method}: Unable to logon") unless response.code == '200'

      result = JSON.parse(response.body)
      if result.key?('LogonResult')
        @session_token = result['LogonResult']
      elsif result.key?('CyberArkLogonResult')
        @session_token = result['CyberArkLogonResult']
      else
        raise("webservices::#{calling_method}: Unable to logon. No session token found!")
      end
    end

    def self.valid_json?(json)
      Puppet.debug(json)
      JSON.parse(json)
      return true
    rescue StandardError => e
      raise("webservices::#{calling_method}: Unable to parse parameters passed in as valid JSON: #{e.message}")
    end
  end
end
