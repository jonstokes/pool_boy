module PoolBoy
  def self.initialize_redis!
    return unless defined?(Rails)
    filename = "#{Rails.root}/config/redis.yml"
    return unless File.exists?(filename)
    config = YAML.load_file(filename)[Rails.env].symbolize_keys
    configure_pool_boy(config)
    setup_pool(config)
  end

  def self.configure_pool_boy(config)
    redis_config = ThreadSafe::Cache.new

    config.each do |name, c|
      base_url = Figaro.env.send c['url'].downcase
      db = c['database' ]
      url = generate_full_url(base_url, db)

      redis_config[name] = {
          size:            c['pool'],
          url:             url,
          database:        db,
          timeout:         c['timeout'] || 5,
          network_timeout: c['network_timeout'] || 5
      }
    end

    PoolBoy::Settings.configure do |con|
      con.redis_config = redis_config
    end
  end

  def self.setup_pool(config)
    redis_pool = ThreadSafe::Cache.new
    redis_config = PoolBoy::Settings.redis_config

    config.each_key do |name|
      next if name == :sidekiq
      puts "# Configuring pool #{name} with size #{redis_config[name][:size]} on #{redis_config[name][:url]}"
      redis_pool[name] = ConnectionPool.new(
         redis_config[name].slice(:size, :timeout)
      ) do
        Redis.new(
          redis_config[name].slice(:url, :network_timeout)
        )
      end
    end

    PoolBoy::Settings.configure do |con|
      con.redis_pool = redis_pool
    end
  end

  def self.generate_full_url(base_url, db)
    if base_url[-1,1] == "/"
      "#{base_url}#{db}"
    else
      "#{base_url}/#{db}"
    end
  end
end
