
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
  # nodes, or districts with names beginning with "mock". A real proxy is
  # still necessary for e.g. getting the cartridge list.
  module MockApplicationContainerProxy

    module Common
      # short form for mock-specific conf
      CONF=Rails.application.config.msg_broker[:mock]

      # register the real proxy as sometimes it will be needed.
      REAL_PROXY = OpenShift::MCollectiveApplicationContainerProxy

      # decide if a thing is supposed to be a mock
      def is_mock_dist?(name); name.start_with?(CONF[:dist_base_name]); end
      def is_mock_node?(name); name.start_with?(CONF[:node_base_name]); end
      def is_mock_app?(name); name.start_with?(CONF[:app_base_name]); end
      def is_mock_user?(name); name.start_with?(CONF[:user_base_name]); end

      # Wrap the log messages so it doesn't HAVE to be rails
      def log_debug(message)
        Rails.logger.debug message
        puts message
      end
      def log_error(message)
        Rails.logger.error message
        puts message
      end

    end # Common


    #
    # This class resolves whether to use the real or mock proxy and delegates.
    # The resolution can happen when instantiated if a node is known at that
    # time, or according to the purpose once the instance is used for something.
    # This is necessary because several class methods instantiate a proxy instance
    # without any way to know what it will be used for, and sometimes we will not
    # want to mock calls (e.g. getting the cartridge cache, creating a real app).
    #
    class Resolver < OpenShift::ApplicationContainerProxy
      include Common  # these should be instance methods
      extend Common   # ... and class methods

      # <<constructor>>
      #
      # Create a resolver instance that responds to ApplicationContainerProxy methods
      # and delegates to an appropriate mock or real proxy.
      #
      # INPUTS:
      # * id: string - a unique app identifier
      # * district: <type> - a classifier for app placement
      # * resolver: <Hash> - contains :real_proxy and :mock_proxy generator lambdas
      #
      def initialize(id=nil, district=nil, resolver=nil)
        raise "Need an id or a resolver" unless id || resolver
        return if @resolver = resolver
        # we have a node id, so we can resolve now whether it's mock
        real_proxy_lambda = lambda { REAL_PROXY.new(id, district) }
        @proxy = is_mock_node?(id) ? Mock.new(id, district, real_proxy_lambda)
                                   : real_proxy_lambda.call
      end

      # We don't know at this point whether operations will need to be mocked or not.
      # So, store the method for getting a real proxy in case we need it.
      # Also store requirements for a mock node in case we need that.
      def self.find_available_impl(*args)
        self.new(nil, nil, {
                 real_proxy: lambda { @@real_proxy.find_available_impl(*args) },
                 mock_proxy: lambda { Mock.find_available_impl(*args) },
        } )
      end

      def self.find_one_impl(node_profile=nil)
        self.new(nil, nil, {
                 real_proxy: lambda { @@real_proxy.find_one_impl(node_profile) },
                 mock_proxy: lambda { Mock.find_one_impl(node_profile) }
        } )
      end

      # Require the proxy to be resolved if it hasn't been;
      # True means it should be a mock if we don't know otherwise.
      def resolve_mock_nature(suggest_mock = false)
        # if a proxy has already been determined, use that.
        return @proxy if @proxy
        # otherwise, use the suggestion
        @proxy = @resolver[suggest_mock ? :mock_proxy : :real_proxy].call
        @proxy.real_proxy_lambda = @resolver[:real_proxy] if suggest_mock
        @proxy
      end

      # #####################################
      # Automatically proxy a bunch of methods:
      # #####################################

      # pass class methods to real proxy class unless they're overridden here
      def self.method_missing(meth, *args, &block)
        log_debug "DEBUG: MockAPRes: proxying missing class method '#{meth}' to real proxy"
        output = REAL_PROXY.send(meth, *args, &block)
        log_debug "DEBUG: MockAPRes: class method '#{meth}' returned: \n#{output.inspect}"
        return output
      end
      # pass instance methods to proxy instance
      def method_missing(meth, *args, &block)
        log_debug "DEBUG: MockAPRes: proxying missing instance method '#{meth}' to resolved proxy"
        output = resolve_mock_nature(false).send(meth, *args, &block)
        log_debug "DEBUG: MockAPRes: instance method '#{meth}' returned: \n#{output.inspect}"
        return output
      end

      # automated instance method creation - force resolution of proxy
      %w[ get_quota ].each do |meth|
        define_method meth.to_sym, ->(*args, &block) do
          resolve_mock_nature(false).send(meth.to_sym, *args, &block)
        end
      end

    end


    # This is the actual mock proxy class.
    # Should work much like the real thing, but never hits mcollective.
    class Mock < OpenShift::ApplicationContainerProxy
      include Common  # these should be instance methods
      extend Common   # ... and class methods

      # A Node ID string
      attr_accessor :id

      # A District ID string
      attr_accessor :district

      # A way to get a real proxy if needed
      attr_accessor :real_proxy_lambda

      # <<constructor>>
      #
      # Create a resolver instance that responds to ApplicationContainerProxy methods
      # and delegates to an appropriate mock or real proxy.
      #
      # INPUTS:
      # * id: string - a unique app identifier
      # * district: <type> - a classifier for app placement
      # * real_proxy_lambda: <lambda> - for generating real proxy instance if needed.
      #                      Must be set by resolver during construction or resolution.
      #
      def initialize(id, district=nil, real_proxy_lambda=nil)
        @id = id
        @district = district
        @real_proxy_lambda = real_proxy_lambda
      end

      # Still keep around a way to get the real proxy for when we haven't mocked something
      def real_proxy
        @real_proxy ||= @real_proxy_lambda.call
      end

      # DEBUG: Need to know when unknown methods are being called
      def self.method_missing(meth, *args, &block)
        log_error "MockAppProxy: don't know how to handle class method:\n\t" +
          "#{meth}(#{args.inspect}) #{block ? '&block': ''}"
        output = REAL_PROXY.send(meth, *args, &block)
        log_debug "DEBUG: MockAppProxy: class method '#{meth}' returned: \n#{output.inspect}"
        return output
      end
      def method_missing(meth, *args, &block)
        log_error "MockAppProxy: don't know how to handle instance method:\n\t" +
          "#{self.inspect}.#{meth}(#{args.inspect}) #{block ? '&block': ''}"
        output = real_proxy().send(meth, *args, &block)
        log_debug "DEBUG: MockAppProxy: instance method '#{meth}' returned: \n#{output.inspect}"
        return output
      end

      # ############################################
      # Mock proxy class methods
      # ############################################

      def self.find_available_impl(node_profile=nil, district_uuid=nil, non_ha_server_identities=nil)
        #TODO: really find a mock
        self.new(CONF[:node_base_name], CONF[:dist_base_name])
      end

      def self.find_one_impl(node_profile=nil)
        #TODO: really find a mock
        self.new(CONF[:node_base_name], CONF[:dist_base_name])
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
      def get_quota(gear)
        raise OpenShift::NodeException.new("Mocked node exception error - get_quota", 143) if gear.app.name.include? "breakquota"
        ['/var/lib/openshift', 1024, 2048, 2048, 100, 1000, 2000]
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
  end # module
end # OpenShift
