
#
# The OpenShift module is a namespace for all OpenShift related objects and
# methods.
#
module OpenShift

  # This proxy wraps the MCollective proxy to enable creating and reporting on
  # fake applications from fake nodes. It is put in place when the "MOCK_ENABLE"
  # configuration setting is true.
  #
  # Requests are passed on to the real proxy unless they involve applications,
  # nodes, or districts with names beginning with "mock". An actual node is
  # still necessary for e.g. getting the cartridge list.
  class MockApplicationContainerProxy < OpenShift::ApplicationContainerProxy

    # A Node ID string
    attr_accessor :id

    # A District ID string
    attr_accessor :district

    # register the real proxy as sometimes it will be needed.
    @@actual_proxy = OpenShift::MCollectiveApplicationContainerProxy

    # short form for mock-specific conf
    CONF=Rails.application.config.msg_broker[:mock]

    # <<constructor>>
    #
    # Create an app descriptor/handle for remote controls
    #
    # INPUTS:
    # * id: string - a unique app identifier
    # * district: <type> - a classifier for app placement
    #
    def initialize(id=nil, district=nil, mock=nil)
      @is_mock = id && self.class.is_mock_node?(id)
      @actual_proxy = mock[:actual] if @mock = mock
      @actual_proxy ||= @@actual_proxy.new(id, district)
      @id = id
      @district = district
    end

    # #####################################
    # Automatically mock a bunch of methods:
    # #####################################

    # pass class methods to real proxy class if we don't override
    def self.method_missing(meth, *args, &block)
      Rails.logger.debug "DEBUG: MockAppProxy: proxying missing class method #{meth} to actual proxy"
      #define_singleton_method(meth) { @@actual_proxy.send(meth, *args, &block) }.call(*args,&block)
      output = @@actual_proxy.send(meth, *args, &block)
      Rails.logger.debug "DEBUG: MockAppProxy: #{meth} returned: \n#{output.inspect}"
      return output
    end
    # pass instance methods to real proxy instance if we don't override
    def method_missing(meth, *args, &block)
      Rails.logger.debug "DEBUG: MockAppProxy: proxying missing instance method #{meth} to actual proxy"
      #self.class.instance_eval { define_method(meth) { @actual_proxy.send(meth, *args, &block) } }
      output = @actual_proxy.send(meth, *args, &block)
      Rails.logger.debug "DEBUG: MockAppProxy: #{meth} returned: \n#{output.inspect}"
      return output
    end

    # centralized instance "@is_mock" checking; if against a mock node,
    # then call the method with _mock; else send to the real proxy.
    %w[ get_quota ].each do |meth|
      define_method meth.to_sym, ->(*args, &block) do
        @is_mock ? send("#{meth}_mock".to_sym, *args, &block)
                 : @actual_proxy.send(meth.to_sym, *args, &block)
      end
    end

    # decide if a thing is supposed to be a mock

    def self.is_mock_dist?(name)
      name.start_with?(CONF[:dist_base_name])
    end

    def self.is_mock_node?(name)
      name.start_with?(CONF[:node_base_name])
    end

    def self.is_mock_app?(name)
      name.start_with?(CONF[:app_base_name])
    end

    def self.is_mock_user?(name)
      name.start_with?(CONF[:user_base_name])
    end

    # ############################################
    # Mock proxy class methods
    # ############################################

    # We don't know at this point whether operations will need to be mocked or not.
    # So, request an actual available node and keep it around in case we need it.
    # Also get a mock node in case we need that.
    def self.find_available_impl(node_profile=nil, district_uuid=nil, non_ha_server_identities=nil)
      actual = @@actual_proxy.find_available_impl(node_profile, district_uuid, non_ha_server_identities)
      # TODO: actually find mock node/dist
      self.new(nil, nil, { actual_proxy: actual, mock_node: CONF[:node_base_name], mock_dist: CONF[:dist_base_name]} )
    end

    def self.find_one_impl(node_profile=nil)
      actual = @@actual_proxy.find_one_impl(node_profile)
      # TODO: actually find mock node/dist
      self.new(nil, nil, { actual_proxy: actual, mock_node: CONF[:node_base_name], mock_dist: CONF[:dist_base_name]} )
    end
    def mock_if_not_set
      # if a node has already been determined, use that.
      return if @id
      # otherwise, use the mock node
      @is_mock = true
      @id = @mock[:mock_node]
      @district = @mock[:mock_dist]
    end


    # ############################################
    # Mock proxy instance methods
    # ############################################

    # Mock the disk quotas from a Gear on a node
    #
    # RETURNS:
    # * an array with following information:
    #
    # [Filesystem, blocks_used, blocks_soft_limit, blocks_hard_limit,
    # inodes_used, inodes_soft_limit, inodes_hard_limit]
    #
    # RAISES:
    # * OpenShift::NodeException if app name includes "breakquota"
    #
    def get_quota_mock(gear)
      raise OpenShift::NodeException.new("Mocked node exception error - get_quota", 143) if gear.app.name.include? "breakquota"
      ['/var/lib/openshift', 1024, 2048, 2048, 100, 1000, 2000]
    end

    protected

    # Wrap the log messages so it doesn't HAVE to be rails
    def log_debug(message)
      Rails.logger.debug message
      puts message
    end
    def log_error(message)
      Rails.logger.error message
      puts message
    end

  end # proxy class

  class PotentialClassMethods

    def self.get_all_gears(opts = {})
      @proxy_provider.get_all_gears_impl(opts)
    end

    def self.get_all_active_gears
      @proxy_provider.get_all_active_gears_impl
    end

    def self.get_all_gears_sshkeys
      @proxy_provider.get_all_gears_sshkeys_impl
    end

    def self.execute_parallel_jobs(handle)
      @proxy_provider.execute_parallel_jobs_impl(handle)
    end

    def self.get_details_for_all(name_list)
      @proxy_provider.get_details_for_all_impl(name_list)
    end

  end #PotentialClassMethods
end # OpenShift
