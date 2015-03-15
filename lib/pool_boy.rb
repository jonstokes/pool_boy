module PoolBoy
  def with_connection
    self.class.with_connection do |c|
      yield c
    end
  end

  def self.included(klass)
    class << klass

      def set_db(default)
        @db_name = default.to_sym
      end

      def with_connection
        retryable(sleep: 0.5) do
          model_pool.with do |conn|
            yield conn
          end
        end
      end

      def model_pool
        @model_pool ||= PoolBoy::Settings.redis_pool[@db_name]
      end
    end
  end
end