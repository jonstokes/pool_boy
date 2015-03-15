module PoolBoy
  module Settings

    class SettingsData < Struct.new(
        :env, :redis_config, :redis_pool
    )
    end

    def self.configuration
      @configuration ||= Bellbro::Settings::SettingsData.new
    end

    def self.configure
      yield configuration
    end

    def self.env
      return unless configured?
      configuration.env
    end

    def self.test?
      return unless configured?
      configuration.env == 'test'
    end

    def self.redis_pool
      return unless configured?
      configuration.redis_pool
    end

    def self.redis_config
      return unless configured?
      configuration.redis_config
    end

    def self.configured?
      !!configuration
    end
  end
end
