module Maybe
  class << self
    def version
      Semver.new(semver)
    end

    def commit_sha
      ENV["BUILD_COMMIT_SHA"].presence || `git rev-parse HEAD 2>/dev/null`.strip.presence || "unknown"
    rescue Errno::ENOENT
      "unknown"
    end

    private
      def semver
        "0.7.0"
      end
  end
end
