
require_relative '../../../puppet_x/cyberark/webservices.rb'

Puppet::Type.type(:cyberark_user)
            .provide(:ruby, parent: PuppetX::CyberArk::WebServices) do

  mk_resource_methods

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.instances
    Puppet.debug('def self.instances ==> returning empty list')
    []
  end

  def self.prefetch(resources)
    instances.each do |prov|
      resource.provider = prov if resource == resources[prov.name]
    end
  end

  def underscore(value)
    value.gsub(%r{::}, '/')
         .gsub(%r{([A-Z]+)([A-Z][a-z])}, '\1_\2')
         .gsub(%r{([a-z\d])([A-Z])}, '\1_\2')
         .tr('-', '_')
         .downcase
  end

  def exists?
    url = "/PasswordVault/WebServices/PIMServices.svc/Users/#{name}"
    result = PuppetX::CyberArk::WebServices
             .get(url, data: nil, resource: @resource)
    result && result.key?('UserName')
  end

  def flush
    # Puppet.debug(" property_flush => #{@property_flush.to_json}")
    data = {}
    @property_flush.each do |key, value|
      new_key = key.to_s.split('_').each(&:capitalize!).join('')
      data[new_key] = value
    end

    return if data.empty?

    url = ['/PasswordVault/WebServices/PIMServices.svc/',
           "Users/#{@resource[:username]}"].join
    PuppetX::CyberArk::WebServices.put(url, data: data.to_json)
    @property_hash = resource.to_hash
  end

  # ==== Updateable properties ===========

  def user_type_name=(value)
    @property_flush[:user_type_name] = value
  end

  def email=(value)
    @property_flush[:email] = value
  end

  def first_name=(value)
    @property_flush[:first_name] = value
  end

  def last_name=(value)
    @property_flush[:last_name] = value
  end

  def change_password_on_the_next_logon=(value)
    @property_flush[:change_password_on_the_next_logon] = value
  end

  def expiry_date=(value)
    @property_flush[:expiry_date] = value
  end

  def disabled=(value)
    @property_flush[:disabled] = value
  end

  def location=(value)
    @property_flush[:location] = value
  end

  # ======================================

  def destroy
    Puppet.debug('DESTROY')
    Puppet.debug(@resource[:username])
    url = ['/PasswordVault/WebServices/PIMServices.svc/',
           "Users/#{@resource[:username]}"].join
    PuppetX::CyberArk::WebServices.delete(url)
  end

  def create
    Puppet.debug('CREATE')
    Puppet.debug(@resource)
    data = {}
    r = @resource
    data[:UserName] = r[:username] if r[:username]
    data[:InitialPassword] = r['initial_password'] if r['initial_password']
    data[:Email] = r['email'] if r['email']
    data[:FirstName] = r['first_name'] if r['first_name']
    data[:LastName] = r['last_name'] if r['last_name']
    v = r['change_password_on_the_next_logon']
    data[:ChangePasswordOnTheNextLogon] = v if v
    data[:ExpiryDate] = r['expiry_date'] if r['expiry_date']
    data[:UserTypeName] = r['user_type_name'] if r['user_type_name']
    data[:Disabled] = r['disabled'] if r['disabled']
    data[:Location] = r['location'] if r['location']

    # Puppet.debug(data.to_json)
    url = '/PasswordVault/WebServices/PIMServices.svc/Users'
    PuppetX::CyberArk::WebServices.post(url, data: data.to_json, resource: nil)

    return unless @resource['groups_to_be_added_to']

    groups_array = @resource['groups_to_be_added_to'].split(',')

    groups_array.each do |groupname|
      Puppet.debug("Adding #{@resource[:username]} to group #{groupname}")
      g_d = { 'UserName' => @resource[:username] }.to_json
      url = ['/PasswordVault/WebServices/PIMServices.svc/',
             "Groups/#{groupname}/Users"].join
      PuppetX::CyberArk::WebServices.post(url, data: g_d, resource: nil)
    end
  end
end
