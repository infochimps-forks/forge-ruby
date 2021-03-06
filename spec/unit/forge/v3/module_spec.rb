require 'spec_helper'

describe PuppetForge::V3::Module do
  before do
    stub_api_for(PuppetForge::V3::Module) do |api|
      stub_fixture(api, :get, '/v3/modules/puppetlabs-apache')
      stub_fixture(api, :get, '/v3/modules/absent-apache')
    end
  end

  describe '::find' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }
    let(:missing_mod) { PuppetForge::V3::Module.find('absent-apache') }

    it 'can find modules that exist' do
      mod.name.should == 'apache'
    end

    it 'returns nil for non-existent modules' do
      missing_mod.should be_nil
    end
  end

  describe '#owner' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    before do
      stub_api_for(PuppetForge::V3::User) do |api|
        stub_fixture(api, :get, '/v3/users/puppetlabs')
      end
    end

    it 'exposes the related module as a property' do
      expect(mod.owner).to_not be nil
    end

    it 'grants access to module attributes without an API call' do
      PuppetForge::V3::User.should_not_receive(:request)
      expect(mod.owner.username).to eql('puppetlabs')
    end

    it 'transparently makes API calls for other attributes' do
      PuppetForge::V3::User.should_receive(:request).once.and_call_original
      expect(mod.owner.created_at).to_not be nil
    end
  end

  describe '#current_release' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    it 'exposes the current_release as a property' do
      expect(mod.current_release).to_not be nil
    end

    it 'grants access to release attributes without an API call' do
      PuppetForge::V3::Release.should_not_receive(:request)
      expect(mod.current_release.version).to_not be nil
    end

    it 'transparently makes API calls for other attributes' do
      stub_api_for(PuppetForge::V3::Release) do |api|
        api.get(mod.current_release.uri) do
          load_fixture('/v3/releases/puppetlabs-apache-0.0.1')
        end
      end

      mod.attributes[:current_release].delete :created_at
      expect(mod.current_release.created_at).to_not be nil
    end
  end

  describe '#releases' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    before do
      stub_api_for(PuppetForge::V3::Release) do |api|
        stub_fixture(api, :get, '/v3/releases/puppetlabs-apache-0.0.1')
        stub_fixture(api, :get, '/v3/releases/puppetlabs-apache-0.0.2')
        stub_fixture(api, :get, '/v3/releases/puppetlabs-apache-0.0.3')
        stub_fixture(api, :get, '/v3/releases/puppetlabs-apache-0.0.4')
        stub_fixture(api, :get, '/v3/releases/puppetlabs-apache-0.1.1')
        stub_fixture(api, :get, '/v3/releases?module=puppetlabs-apache')
      end
    end

    it 'exposes the related releases as a property' do
      expect(mod.releases).to be_an Array
    end

    it 'knows the size of the collection' do
      expect(mod.releases).to_not be_empty
    end

    it 'grants access to release attributes without an API call' do
      PuppetForge::V3::Release.should_not_receive(:request)
      expect(mod.releases.map(&:version)).to_not include nil
    end

    it 'transparently makes API calls for other attributes' do
      versions = %w[ 0.0.1 0.0.2 0.0.3 0.0.4 0.1.1 ]
      releases = mod.releases.select { |x| versions.include? x.version }

      PuppetForge::V3::Release.should_receive(:request) \
                        .exactly(5).times \
                        .and_call_original

      expect(releases.map(&:created_at)).to_not include nil
    end
  end

  describe 'instance properies' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    example 'are easily accessible' do
      expect(mod.created_at).to_not be nil
    end
  end
end
