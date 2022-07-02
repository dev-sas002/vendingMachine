require 'rails_helper'

describe ApplicationService do
  it 'requires subclasses to implement #call' do
    expect { described_class.call }.to raise_error(NotImplementedError, /must implement/)
  end

  it 'builds an instance and runs it' do
    stub_const('Doubler', Class.new(described_class) do
      def initialize(value:)
        super()
        @value = value
      end

      def call
        @value * 2
      end
    end)

    expect(Doubler.call(value: 21)).to eq(42)
  end
end
