require "spec_helper"

RSpec.describe Plutoprint::ResourceFetcher do
  describe "#fetch_url" do
    it "responds to fetch_url" do
      fetcher = described_class.new
      expect(fetcher).to respond_to(:fetch_url)
    end
  end
end

RSpec.describe Plutoprint::DefaultResourceFetcher do
  describe "singleton" do
    it "is accessible via Plutoprint.default_resource_fetcher" do
      fetcher = Plutoprint.default_resource_fetcher
      expect(fetcher).to be_a(described_class)
    end

    it "returns the same instance each time" do
      a = Plutoprint.default_resource_fetcher
      b = Plutoprint.default_resource_fetcher
      expect(a).to equal(b)
    end

    it "is frozen" do
      expect(Plutoprint.default_resource_fetcher).to be_frozen
    end

    it "cannot be instantiated via new" do
      expect { described_class.new }.to raise_error(TypeError)
    end
  end

  describe "configuration methods" do
    let(:fetcher) { Plutoprint.default_resource_fetcher }

    it "responds to set_ssl_cainfo" do
      expect(fetcher).to respond_to(:set_ssl_cainfo)
    end

    it "responds to set_ssl_capath" do
      expect(fetcher).to respond_to(:set_ssl_capath)
    end

    it "responds to set_ssl_verify_peer" do
      expect(fetcher).to respond_to(:set_ssl_verify_peer)
    end

    it "responds to set_ssl_verify_host" do
      expect(fetcher).to respond_to(:set_ssl_verify_host)
    end

    it "responds to set_http_follow_redirects" do
      expect(fetcher).to respond_to(:set_http_follow_redirects)
    end

    it "responds to set_http_max_redirects" do
      expect(fetcher).to respond_to(:set_http_max_redirects)
    end

    it "responds to set_http_timeout" do
      expect(fetcher).to respond_to(:set_http_timeout)
    end
  end
end
