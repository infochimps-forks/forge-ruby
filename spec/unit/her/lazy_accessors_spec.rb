require 'spec_helper'
require 'json'

describe Her::LazyAccessors do
  let(:klass) do
    Class.new do
      include Her::Model
      include Her::LazyAccessors

      def request_path
        "/things/#{id}"
      end

      def standalone_method
        "a/b/c"
      end

      def satisified_dependent_method
        "-#{local}-"
      end

      def unsatisfied_dependent_method
        "-#{remote}-"
      end

      def shadow
        "-#{super}-"
      end

      def remote_shadow
        "-#{super}-"
      end
    end
  end

  let(:local_data)  { { :id => 1, :local => 'data', :shadow => 'x' } }
  let(:remote_data) { local_data.merge(:remote => 'DATA', :remote_shadow => 'X') }

  subject { klass.new(local_data) }

  it 'does not call methods to #inspect' do
    subject.should_not_receive(:shadow)
    subject.inspect
  end

  describe 'local attributes' do
    before { klass.should_not_receive(:request) }

    example 'allow access to local attributes' do
      expect(subject.local).to eql('data')
    end

    example 'provide local attributes predicates' do
      expect(subject.local?).to be true
    end

    example 'provide local attributes setters' do
      subject.local = 'foo'
      expect(subject.local).to eql('foo')
    end

    example 'allow access to local standalone methods' do
      expect(subject.standalone_method).to eql('a/b/c')
    end

    example 'allow access to locally satisfiable methods' do
      expect(subject.satisified_dependent_method).to eql('-data-')
    end

    example 'allow `super` access to shadowed attributes' do
      expect(subject.shadow).to eql('-x-')
    end

    example 'do not create accessors on the base class itself' do
      expect(klass.instance_methods(false)).to_not include(:local)
      subject.local rescue nil
      expect(klass.instance_methods(false)).to_not include(:local)
    end
  end

  describe 'remote attributes' do
    before do
      stub_api_for(klass) do |api|
        api.get('/things/1') do
          [ 200, { 'Content-Type' => 'json' }, remote_data.to_json ]
        end
      end
    end

    example 'allow access to remote attributes' do
      expect(subject.remote).to eql('DATA')
    end

    example 'provide remote attributes predicates' do
      expect(subject.remote?).to be true
    end

    example 'provide remote attributes setters' do
      subject.remote = 'foo'
      expect(subject.remote).to eql('foo')
    end

    example 'allow multiple instances to access remote attributes' do
      klass.should_receive(:request).exactly(9).times.and_call_original
      9.times { expect(klass.new(local_data).remote).to eql('DATA') }
    end

    example 'allow access to locally unsatisfiable methods' do
      expect(subject.unsatisfied_dependent_method).to eql('-DATA-')
    end

    example 'allow `super` access to shadowed remote attributes' do
      expect(subject.remote_shadow).to eql('-X-')
    end

    example 'do not create accessors on the base class itself' do
      expect(klass.instance_methods(false)).to_not include(:remote)
      subject.remote rescue nil
      expect(klass.instance_methods(false)).to_not include(:remote)
    end
  end

  describe 'unsatisfiable attributes' do
    before do
      stub_api_for(klass) do |api|
        api.get('/things/1') do
          [ 200, { 'Content-Type' => 'json' }, remote_data.to_json ]
        end
      end
    end

    example 'raise an exception when accessing an unknown attribute' do
      expect { subject.unknown_attribute }.to raise_error(NoMethodError)
    end

    example 'do not create accessors on the base class itself' do
      expect(klass.instance_methods(false)).to_not include(:local)
      subject.unknown_attribute rescue nil
      expect(klass.instance_methods(false)).to_not include(:local)
    end
  end
end
