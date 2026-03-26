require "spec_helper"
require "plutoprint/rack/middleware"

RSpec.describe Plutoprint::Rack::Middleware do
  let(:html_body) { "<html><head></head><body><h1>Test</h1></body></html>" }
  let(:inner_app) do
    lambda { |env| [200, {"Content-Type" => "text/html"}, [html_body]] }
  end
  let(:middleware) { described_class.new(inner_app) }

  # Rack 3 uses lowercase headers, Rack 2 uses capitalized
  def header(headers, name)
    headers[name] || headers[name.downcase]
  end

  after { Plutoprint.instance_variable_set(:@configuration, nil) }

  describe "#call" do
    context "when request path ends with .pdf" do
      let(:env) { Rack::MockRequest.env_for("/transactions/123.pdf") }

      it "strips .pdf from PATH_INFO before forwarding" do
        forwarded_path = nil
        app = lambda { |env|
          forwarded_path = env["PATH_INFO"]
          [200, {"Content-Type" => "text/html"}, [html_body]]
        }
        mw = described_class.new(app)
        mw.call(env)
        expect(forwarded_path).to eq("/transactions/123")
      end

      it "sets the plutoprint.middleware env flag" do
        flag = nil
        app = lambda { |env|
          flag = env["plutoprint.middleware"]
          [200, {"Content-Type" => "text/html"}, [html_body]]
        }
        mw = described_class.new(app)
        mw.call(env)
        expect(flag).to eq(true)
      end

      it "returns PDF content type" do
        status, headers, _body = middleware.call(env)
        expect(status).to eq(200)
        expect(header(headers, "Content-Type")).to eq("application/pdf")
      end

      it "returns a PDF body starting with %PDF" do
        _status, _headers, body = middleware.call(env)
        pdf_content = +""
        body.each { |chunk| pdf_content << chunk }
        expect(pdf_content).to start_with("%PDF")
      end

      it "sets Content-Length header" do
        _status, headers, body = middleware.call(env)
        pdf_content = +""
        body.each { |chunk| pdf_content << chunk }
        expect(header(headers, "Content-Length")).to eq(pdf_content.bytesize.to_s)
      end

      it "restores PATH_INFO after response" do
        middleware.call(env)
        expect(env["PATH_INFO"]).to eq("/transactions/123.pdf")
      end
    end

    context "when request path ends with .png" do
      before { Plutoprint.configure { |c| c.use_png_middleware = true } }

      let(:env) { Rack::MockRequest.env_for("/chart/1.png") }

      it "returns PNG content type" do
        status, headers, _body = middleware.call(env)
        expect(status).to eq(200)
        expect(header(headers, "Content-Type")).to eq("image/png")
      end
    end

    context "when PNG middleware is disabled" do
      let(:env) { Rack::MockRequest.env_for("/chart/1.png") }

      it "passes through without conversion" do
        app = lambda { |_env| [200, {"Content-Type" => "text/html"}, [html_body]] }
        mw = described_class.new(app)
        _status, headers, _body = mw.call(env)
        expect(header(headers, "Content-Type")).to eq("text/html")
      end
    end

    context "when request path does not end with .pdf or .png" do
      let(:env) { Rack::MockRequest.env_for("/transactions/123") }

      it "passes through without modification" do
        status, headers, body = middleware.call(env)
        expect(status).to eq(200)
        expect(header(headers, "Content-Type")).to eq("text/html")
        expect(body).to eq([html_body])
      end
    end

    context "when response is not HTML" do
      let(:json_app) { lambda { |_env| [200, {"Content-Type" => "application/json"}, ["{}"]] } }
      let(:middleware) { described_class.new(json_app) }
      let(:env) { Rack::MockRequest.env_for("/api/data.pdf") }

      it "passes through non-HTML responses" do
        _status, headers, _body = middleware.call(env)
        expect(header(headers, "Content-Type")).to eq("application/json")
      end
    end

    context "when response is a redirect" do
      let(:redirect_app) { lambda { |_env| [302, {"Location" => "/login"}, []] } }
      let(:middleware) { described_class.new(redirect_app) }
      let(:env) { Rack::MockRequest.env_for("/secure/report.pdf") }

      it "passes through redirects" do
        status, headers, _body = middleware.call(env)
        expect(status).to eq(302)
        expect(headers["Location"]).to eq("/login")
      end
    end

    context "with ignore_path string" do
      before { Plutoprint.configure { |c| c.ignore_path = "/admin" } }

      let(:env) { Rack::MockRequest.env_for("/admin/report.pdf") }

      it "skips conversion for ignored paths" do
        _status, headers, _body = middleware.call(env)
        expect(header(headers, "Content-Type")).to eq("text/html")
      end
    end

    context "with ignore_path regexp" do
      before { Plutoprint.configure { |c| c.ignore_path = /\/api\// } }

      let(:env) { Rack::MockRequest.env_for("/api/v1/report.pdf") }

      it "skips conversion for paths matching regexp" do
        _status, headers, _body = middleware.call(env)
        expect(header(headers, "Content-Type")).to eq("text/html")
      end
    end

    context "with ignore_path proc" do
      before { Plutoprint.configure { |c| c.ignore_path = ->(path) { path.include?("/skip/") } } }

      let(:env) { Rack::MockRequest.env_for("/skip/report.pdf") }

      it "skips conversion when proc returns truthy" do
        _status, headers, _body = middleware.call(env)
        expect(header(headers, "Content-Type")).to eq("text/html")
      end
    end

    context "with ignore_request proc" do
      before do
        Plutoprint.configure do |c|
          c.ignore_request = ->(req) { req.params["no_pdf"] == "1" }
        end
      end

      let(:env) { Rack::MockRequest.env_for("/report.pdf?no_pdf=1") }

      it "skips conversion when proc returns truthy" do
        _status, headers, _body = middleware.call(env)
        expect(header(headers, "Content-Type")).to eq("text/html")
      end
    end

    context "with per-request options" do
      let(:env) do
        e = Rack::MockRequest.env_for("/test.pdf")
        e["plutoprint.options"] = {size: :letter}
        e
      end

      it "uses per-request options for conversion" do
        status, headers, _body = middleware.call(env)
        expect(status).to eq(200)
        expect(header(headers, "Content-Type")).to eq("application/pdf")
      end
    end
  end
end
