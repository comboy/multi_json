shared_examples_for "an adapter" do |adapter|

  before do
    begin
      MultiJson.use adapter
    rescue LoadError
      pending "Adapter #{adapter} couldn't be loaded (not installed?)"
    end
  end

  describe '.dump' do
    it 'writes decodable JSON' do
      [
        {'abc' => 'def'},
        [1, 2, 3, "4"],
      ].each do |example|
        MultiJson.load(MultiJson.dump(example)).should == example
      end
    end

    it 'dumps symbol keys as strings' do
      [
        [
          {:foo => {:bar => 'baz'}},
          {'foo' => {'bar' => 'baz'}},
        ],
        [
          [{:foo => {:bar => 'baz'}}],
          [{'foo' => {'bar' => 'baz'}}],
        ],
        [
          {:foo => [{:bar => 'baz'}]},
          {'foo' => [{'bar' => 'baz'}]},
        ]
      ].each do |example, expected|
        dumped_json = MultiJson.dump(example)
        MultiJson.load(dumped_json).should == expected
      end
    end

    it 'dumps rootless JSON' do
      MultiJson.dump("random rootless string").should == "\"random rootless string\""
      MultiJson.dump(123).should == "123"
    end

    it 'passes options to the adapter' do
      MultiJson.adapter.should_receive(:dump).with('foo', {:bar => :baz})
      MultiJson.dump('foo', :bar => :baz)
    end

    if adapter == 'json_gem' || adapter == 'json_pure'
      describe 'with :pretty option set to true' do
        it 'passes default pretty options' do
          object = 'foo'
          object.should_receive(:to_json).with(JSON::PRETTY_STATE_PROTOTYPE.to_h)
          MultiJson.dump(object,:pretty => true)
        end
      end
    end

    it 'dumps custom objects which implement as_json' do
      MultiJson.dump(TimeWithZone.new).should == "\"2005-02-01T15:15:10Z\""
    end
  end

  describe '.load' do
    it 'properly loads valid JSON' do
      MultiJson.load('{"abc":"def"}').should == {'abc' => 'def'}
    end

    it 'raises MultiJson::DecodeError on invalid JSON' do
      lambda do
        MultiJson.load('{"abc"}')
      end.should raise_error(MultiJson::DecodeError)
    end

    it 'raises MultiJson::DecodeError with data on invalid JSON' do
      data = '{invalid}'
      begin
        MultiJson.load(data)
      rescue MultiJson::DecodeError => de
        de.data.should == data
      end
    end

    it 'stringifys symbol keys when encoding' do
      dumped_json = MultiJson.dump(:a => 1, :b => {:c => 2})
      MultiJson.load(dumped_json).should == {"a" => 1, "b" => {"c" => 2}}
    end

    it 'properly loads valid JSON in StringIOs' do
      json = StringIO.new('{"abc":"def"}')
      MultiJson.load(json).should == {'abc' => 'def'}
    end

    it 'properly loads null' do
      MultiJson.load('null').should == nil
    end

    it 'allows for symbolization of keys' do
      [
        [
          '{"abc":{"def":"hgi"}}',
          {:abc => {:def => 'hgi'}},
        ],
        [
          '[{"abc":{"def":"hgi"}}]',
          [{:abc => {:def => 'hgi'}}],
        ],
        [
          '{"abc":[{"def":"hgi"}]}',
          {:abc => [{:def => 'hgi'}]},
        ],
      ].each do |example, expected|
        MultiJson.load(example, :symbolize_keys => true).should == expected
      end
    end
  end
end
